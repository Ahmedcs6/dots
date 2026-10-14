pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "." as QsServices

Singleton {
    id: root
    
    property bool enabled: false
    property bool dndEnabled: false
    property real previousBrightness: 0.5
    property bool didSetBrightness: false
    // True until startup governor detection finishes. While true,
    // onEnabledChanged must not fire DND/brightness side effects.
    property bool _initializing: true
    
    // Performance settings. Resolved at startup from
    // scaling_available_governors: intel_pstate only offers
    // "performance powersave", so a hardcoded "schedutil" fallback would be
    // rejected by the kernel on such machines.
    readonly property string performanceGovernor: "performance"
    property string balancedGovernor: "powersave"
    property var detectedGovernors: ["performance", "powersave"]
    
    onEnabledChanged: {
        QsServices.Logger.info("GamingMode", `Gaming mode ${enabled ? "ENABLED" : "DISABLED"}`)

        // Suppress DND/brightness/governor side effects during startup sync.
        if (root._initializing)
            return

        if (enabled) {
            // Save current DND state
            dndEnabled = notifs.dnd
            didSetBrightness = false
            
            // Enable performance mode
            setCpuGovernor(performanceGovernor)
            
            // Enable DND
            notifs.dnd = true
            
            // Boost brightness (optional - can be customized)
            if (brightness.brightness < 0.8) {
                previousBrightness = brightness.brightness
                brightness.setBrightness(1.0)
                didSetBrightness = true
            }
        } else {
            // Restore balanced mode
            setCpuGovernor(balancedGovernor)
            
            // Restore DND only if user hasn't manually changed it
            if (notifs.dnd === true)
                notifs.dnd = dndEnabled
            
            // Restore brightness only if gaming mode set it
            if (didSetBrightness)
                brightness.setBrightness(previousBrightness)
        }
    }
    
    function toggle() {
        enabled = !enabled
    }
    
    readonly property var validGovernors: detectedGovernors

    function setCpuGovernor(governor) {
        if (!validGovernors.includes(governor)) {
            QsServices.Logger.warn("GamingMode", `Invalid CPU governor: ${governor}`)
            return
        }
        QsServices.Logger.info("GamingMode", `Setting CPU governor to: ${governor}`)
        cpuGovernorProc.exec([
            "sh", "-c",
            "printf '%s' \"$1\" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor",
            "sh", governor
        ])
    }
    
    // Process to set CPU governor (requires passwordless sudo for cpufreq)
    Process {
        id: cpuGovernorProc
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    QsServices.Logger.debug("GamingMode", `CPU governor output: ${text.trim()}`)
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    QsServices.Logger.warn("GamingMode", `CPU governor error: ${text.trim()}`)
                    QsServices.Logger.info("GamingMode", "Tip: add passwordless tee to /etc/sudoers.d/cpufreq if desired")
                }
            }
        }
    }
    
    // Check current CPU governor on startup
    Component.onCompleted: {
        detectGovernorsProc.running = true
        checkGovernorProc.running = true
    }

    // Detect which governors this kernel/driver supports (one-shot)
    Process {
        id: detectGovernorsProc
        command: ["cat", "/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const list = text.trim().split(/\s+/).filter(g => g.length > 0)
                if (list.length > 0) {
                    root.detectedGovernors = list
                    // Prefer schedutil for "balanced" where supported,
                    // otherwise fall back to powersave (always present
                    // alongside performance on intel_pstate/acpi-cpufreq).
                    if (list.includes("schedutil"))
                        root.balancedGovernor = "schedutil"
                    else if (list.includes("powersave"))
                        root.balancedGovernor = "powersave"
                    else
                        root.balancedGovernor = list[0]
                    QsServices.Logger.debug("GamingMode", `Available governors: ${list.join(", ")}; balanced=${root.balancedGovernor}`)
                }
            }
        }
    }
    
    Process {
        id: checkGovernorProc
        command: ["cat", "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                const currentGovernor = text.trim()
                QsServices.Logger.debug("GamingMode", `Current CPU governor: ${currentGovernor}`)
                // Sync persisted state without firing DND/brightness side
                // effects (_initializing guard in onEnabledChanged handles it).
                if (currentGovernor === performanceGovernor) {
                    enabled = true
                }
                root._initializing = false
            }
        }
    }
    
    // Reference to services (will be set by Control Center)
    readonly property var notifs: QsServices.Notifs
    readonly property var brightness: QsServices.Brightness
}
