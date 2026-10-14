pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "." as QsServices

Singleton {
    id: root
    
    // Consumer visibility control - set to false to pause polling when UI is hidden
    property bool active: true
    
    property real cpuPerc: 0
    property real memUsed: 0
    property real memTotal: 1
    readonly property real memPerc: memTotal > 0 ? memUsed / memTotal : 0
    property real diskUsed: 0
    property real diskTotal: 1
    readonly property real diskPerc: diskTotal > 0 ? diskUsed / diskTotal : 0
    
    // Network speed tracking
    property real downloadSpeed: 0  // bytes per second
    property real uploadSpeed: 0    // bytes per second
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real lastNetTime: 0
    property var networkHistory: []  // Array of {download, upload} for graphing
    
    // GPU monitoring
    property bool hasGpu: false
    property string gpuType: "none"  // "nvidia", "amd", "intel", "none"
    property string gpuName: ""
    property real gpuUsage: 0        // percentage 0-100, -1 = unknown
    property real gpuTemp: 0         // celsius
    property real gpuMemUsed: 0      // MB
    property real gpuMemTotal: 0     // MB
    readonly property real gpuMemPerc: gpuMemTotal > 0 ? gpuMemUsed / gpuMemTotal : 0

    // CPU identity + temperature (coretemp/k10temp/acpitz via sysfs)
    property string cpuName: ""
    property real cpuTemp: 0         // celsius, 0 = unknown
    property string _cpuTempPath: ""
    property string _gpuTempPath: ""
    property double _lastTempRedetect: 0
    
    // Rolling history buffers for charts (0-100), shared by all widgets.
    // This is the Caelestia-style "by charts" data for CPU / RAM / GPU.
    property var cpuHistory: []
    property var memHistory: []
    property var gpuHistory: []

    // Top processes
    property var topProcesses: []    // [{name, cpu, pid}, ...]
    
    property real lastCpuIdle: 0
    property real lastCpuTotal: 0
    
    Component.onCompleted: {
        detectHardware()
        updateTimer.start()
        updateSysStats()
        updateDisk()
        updateTopProcesses()
    }

    // One-shot hardware detection: CPU name, GPU type/name, and resolved
    // sysfs temperature sensor paths (hwmon numbers vary, so resolve the
    // file paths once instead of re-scanning every tick).
    function detectHardware() {
        detectGpu()
        hardwareDetectProc.running = true
    }
    
    function updateSysStats() {
        if (!sysStatsProcess.running)
            sysStatsProcess.running = true
    }
    
    function updateDisk() {
        diskProcess.running = true
    }
    
    function updateGpu() {
        if (!hasGpu) return

        if (gpuType === "nvidia") {
            nvidiaGpuProc.running = true
        } else if (gpuType === "amd") {
            amdGpuProc.running = true
        }
        // Intel iGPU: no usage counter in sysfs (gt freq files absent on
        // modern kernels); gpuUsage stays -1 = unknown, temp mirrors CPU.
    }

    // Read CPU (+discrete GPU) temperatures from resolved sysfs paths.
    // Runs on the slow tick; millidegree values converted to celsius.
    function updateTemps() {
        if (_cpuTempPath !== "") {
            cpuTempProc.command = ["/bin/cat", _cpuTempPath]
            cpuTempProc.running = true
        }
        if (_gpuTempPath !== "") {
            gpuTempProc.command = ["/bin/cat", _gpuTempPath]
            gpuTempProc.running = true
        }
    }

    Process {
        id: cpuTempProc
        running: false

        stdout: SplitParser {
            onRead: data => {
                const milli = parseInt(data.trim())
                if (!isNaN(milli) && milli > 0) {
                    root.cpuTemp = milli / 1000
                    // Integrated GPU shares the CPU die temperature
                    if (root.gpuType === "intel")
                        root.gpuTemp = root.cpuTemp
                } else if (root._cpuTempPath !== "") {
                    // Sensor path went stale (hwmon renumbering) — redetect at
                    // most once a minute to avoid a process storm if the
                    // sensor never reappears.
                    const now = Date.now()
                    if (now - root._lastTempRedetect > 60000) {
                        root._lastTempRedetect = now
                        root._cpuTempPath = ""
                        detectHardware()
                    }
                }
            }
        }
    }

    Process {
        id: gpuTempProc
        running: false

        stdout: SplitParser {
            onRead: data => {
                const milli = parseInt(data.trim())
                if (!isNaN(milli) && milli > 0) {
                    root.gpuTemp = milli / 1000
                }
            }
        }
    }
    
    function updateTopProcesses() {
        topProcessesProc.running = true
    }
    
    function formatBytes(bytes) {
        const gb = bytes / (1024 ** 3)
        if (gb >= 1) return { value: gb, unit: "GB" }
        const mb = bytes / (1024 ** 2)
        if (mb >= 1) return { value: mb, unit: "MB" }
        const kb = bytes / 1024
        return { value: kb, unit: "KB" }
    }
    
    // Combined CPU, memory, and network read (shared /proc sources)
    Process {
        id: sysStatsProcess
        command: ["/bin/sh", "-c", "cat /proc/stat | grep '^cpu ' && echo '---MEM---' && free -b | grep Mem && echo '---NET---' && cat /proc/net/dev | tail -n +3 | awk '{rx+=$2; tx+=$10} END {print rx\" \"tx}'"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const sections = text.split('---MEM---\n')
                if (sections.length < 2) return

                // --- Parse CPU (first section) ---
                // /proc/stat cpu line: cpu user nice system idle iowait irq
                // softirq steal guest guest_nice. Idle = idle + iowait; total
                // = all non-guest fields so IO-heavy loads aren't under-reported.
                const cpuData = sections[0].trim()
                const cpuParts = cpuData.split(/\s+/)
                if (cpuParts.length >= 5) {
                    const nums = cpuParts.slice(1, 9).map(v => parseInt(v) || 0)
                    while (nums.length < 8) nums.push(0)
                    const idle = nums[3] + nums[4]
                    const total = nums[0] + nums[1] + nums[2] + nums[3] + nums[4] + nums[5] + nums[6] + nums[7]

                    if (root.lastCpuTotal > 0) {
                        const totalDiff = total - root.lastCpuTotal
                        const idleDiff = idle - root.lastCpuIdle
                        if (totalDiff > 0) {
                            root.cpuPerc = 1 - (idleDiff / totalDiff)
                            // Push chart history (0-100)
                            root.cpuHistory = [...root.cpuHistory.slice(-59), Math.max(0, Math.min(100, root.cpuPerc * 100))]
                        }
                    }

                    root.lastCpuIdle = idle
                    root.lastCpuTotal = total
                }

                // --- Parse memory (between ---MEM--- and ---NET---) ---
                const memAndNet = sections[1].split('---NET---\n')
                const memData = memAndNet[0].trim()
                const memParts = memData.split(/\s+/)
                if (memParts.length >= 3) {
                    root.memTotal = parseInt(memParts[1])
                    root.memUsed = parseInt(memParts[2])
                    // Push chart history (0-100)
                    const mp = root.memTotal > 0 ? (root.memUsed / root.memTotal) * 100 : 0
                    root.memHistory = [...root.memHistory.slice(-59), Math.max(0, Math.min(100, mp))]
                }

                // --- Parse network (after ---NET---) ---
                if (memAndNet.length >= 2) {
                    const netData = memAndNet[1].trim()
                    const netParts = netData.split(/\s+/)
                    if (netParts.length >= 2) {
                        const rxBytes = parseInt(netParts[0])
                        const txBytes = parseInt(netParts[1])
                        const currentTime = Date.now() / 1000

                        if (root.lastNetTime > 0) {
                            const timeDiff = currentTime - root.lastNetTime
                            const rxDiff = rxBytes - root.lastRxBytes
                            const txDiff = txBytes - root.lastTxBytes
                            // Guard counter reset/wrap (reboot, iface re-add):
                            // negative diffs would push huge negative spikes.
                            if (timeDiff > 0 && rxDiff >= 0 && txDiff >= 0) {
                                root.downloadSpeed = rxDiff / timeDiff
                                root.uploadSpeed = txDiff / timeDiff

                                root.networkHistory.push({download: root.downloadSpeed, upload: root.uploadSpeed})
                                if (root.networkHistory.length > 30) {
                                    root.networkHistory.shift()
                                }
                                root.networkHistoryChanged()
                            }
                        }

                        root.lastRxBytes = rxBytes
                        root.lastTxBytes = txBytes
                        root.lastNetTime = currentTime
                    }
                }
            }
        }
    }

    // Disk usage
    Process {
        id: diskProcess
        command: ["/bin/sh", "-c", "df -B1 / | tail -1"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length >= 3) {
                    diskTotal = parseInt(parts[1])
                    diskUsed = parseInt(parts[2])
                }
            }
        }
    }
    
    // GPU Detection + CPU identity + temperature sensor resolution.
    // Emits KEY=value lines parsed below. Temp sensor preference:
    // coretemp "Package id" > k10temp/zenpower > acpitz.
    Process {
        id: hardwareDetectProc
        command: ["/bin/sh", "-c", "echo \"CPU_NAME=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')\"; if command -v nvidia-smi >/dev/null 2>&1; then echo 'GPU_TYPE=nvidia'; echo \"GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)\"; elif command -v radeontop >/dev/null 2>&1; then echo 'GPU_TYPE=amd'; echo \"GPU_NAME=$(lspci 2>/dev/null | grep -im1 'vga\\|3d\\|display' | cut -d: -f3- | sed 's/^ *//')\"; elif ls -d /sys/class/drm/card* >/dev/null 2>&1; then echo 'GPU_TYPE=intel'; echo \"GPU_NAME=$(lspci 2>/dev/null | grep -im1 'vga\\|3d\\|display' | cut -d: -f3- | sed 's/^ *//')\"; else echo 'GPU_TYPE=none'; fi; found=''; for d in /sys/class/hwmon/hwmon*; do n=$(cat \"$d/name\" 2>/dev/null); case \"$n\" in coretemp) for t in \"$d\"/temp*_input; do l=$(cat \"${t%_input}_label\" 2>/dev/null); case \"$l\" in *Package*) echo \"CPU_TEMP=$t\"; found=1; break 2;; esac; done;; k10temp|zenpower) echo \"CPU_TEMP=$d/temp1_input\"; found=1; break;; esac; done; if [ -z \"$found\" ]; then for d in /sys/class/hwmon/hwmon*; do if [ \"$(cat \"$d/name\" 2>/dev/null)\" = acpitz ]; then echo \"CPU_TEMP=$d/temp1_input\"; break; fi; done; fi; for d in /sys/class/hwmon/hwmon*; do if [ \"$(cat \"$d/name\" 2>/dev/null)\" = amdgpu ]; then echo \"GPU_TEMP=$d/temp1_input\"; break; fi; done; true"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const eq = line.indexOf("=")
                    if (eq < 0) continue
                    const key = line.slice(0, eq)
                    const val = line.slice(eq + 1)
                    if (key === "CPU_NAME" && val) root.cpuName = val
                    else if (key === "GPU_TYPE" && val) {
                        root.gpuType = val
                        root.hasGpu = val !== "none"
                        QsServices.Logger.debug("SystemUsage", `GPU detected: ${val}`)
                    }
                    else if (key === "GPU_NAME" && val) root.gpuName = val
                    else if (key === "CPU_TEMP" && val) root._cpuTempPath = val
                    else if (key === "GPU_TEMP" && val) root._gpuTempPath = val
                }
                if (root.gpuType === "intel" && !root.gpuName)
                    root.gpuName = "Integrated Graphics"
                // Intel iGPU has no usage counter in sysfs; mark unknown
                // instead of showing a fake 0%.
                if (root.gpuType === "intel")
                    root.gpuUsage = -1
                if (root.hasGpu)
                    updateGpu()
                updateTemps()
            }
        }
    }

    // Legacy GPU type probe (kept for compatibility, superseded by
    // hardwareDetectProc which also resolves names and temp sensors).
    function detectGpu() {
        if (!hardwareDetectProc.running)
            hardwareDetectProc.running = true
    }
    
    // NVIDIA GPU monitoring
    Process {
        id: nvidiaGpuProc
        command: ["/bin/sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(',').map(x => x.trim())
                if (parts.length >= 4) {
                    gpuUsage = parseFloat(parts[0])
                    gpuTemp = parseFloat(parts[1])
                    gpuMemUsed = parseFloat(parts[2])
                    gpuMemTotal = parseFloat(parts[3])
                    root.gpuHistory = [...root.gpuHistory.slice(-59), Math.max(0, Math.min(100, gpuUsage))]
                }
            }
        }
    }
    
    // AMD GPU monitoring (using radeontop).
    // Temperature comes from updateTemps() via the resolved amdgpu hwmon.
    Process {
        id: amdGpuProc
        command: ["/bin/sh", "-c", "radeontop -d - -l 1 2>/dev/null | grep -oP 'gpu \\K[0-9.]+' | head -1"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                gpuUsage = parseFloat(data.trim())
                root.gpuHistory = [...root.gpuHistory.slice(-59), Math.max(0, Math.min(100, gpuUsage))]
            }
        }
    }
    
    // Top CPU-consuming processes
    Process {
        id: topProcessesProc
        command: ["/bin/sh", "-c", "ps aux --sort=-%cpu | head -6 | tail -5 | awk '{print $11\"|\"$3\"|\"$2}'"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n').filter(l => l.length > 0)
                topProcesses = lines.map(line => {
                    const parts = line.split('|')
                    return {
                        name: parts[0] || "Unknown",
                        cpu: parseFloat(parts[1]) || 0,
                        pid: parseInt(parts[2]) || 0
                    }
                })
            }
        }
    }
    
    // Update timer - staggered updates.
    // NOTE: CPU %, memory, disk and network speeds are rates: they can only
    // be computed by sampling counters over time, so true event-driven
    // updates are impossible here. The bar shows cpu/mem/disk permanently,
    // so sampling stays always-on but slow; expensive collectors (top
    // processes, GPU) run less often. Only runs when active (controlled by
    // consumer visibility).
    Timer {
        id: updateTimer
        interval: 3000  // Base interval (was 2s)
        repeat: true
        running: root.active  // Pause when no consumer is visible
        triggeredOnStart: true  // Immediate first read

        property int tickCount: 0

        onTriggered: {
            tickCount++

            // Update CPU, Memory, Network every tick (3s)
            updateSysStats()

            // Update Disk rarely (every 60s - disk usage barely changes)
            if (tickCount % 20 === 0) {
                updateDisk()
            }

            // Update GPU + temperatures moderately (every 6s)
            if (tickCount % 2 === 0) {
                updateGpu()
                updateTemps()
            }

            // Update top processes rarely (every 12s - dashboard-only data)
            if (tickCount % 4 === 0) {
                updateTopProcesses()
            }
        }
    }
}
