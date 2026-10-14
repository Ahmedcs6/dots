pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

Singleton {
    id: root
    
    property real brightness: 0.5
    property real maxBrightness: 1.0
    
    // Alias for easier access
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)
    
    property string _backlightDevice: ""
    readonly property string backlightPath: _backlightDevice !== "" ? `/sys/class/backlight/${_backlightDevice}/brightness` : ""
    readonly property string maxBrightnessPath: _backlightDevice !== "" ? `/sys/class/backlight/${_backlightDevice}/max_brightness` : ""
    
    property int currentValue: 0
    property int maxValue: 255
    // Coalesce rapid slider moves: setBrightnessProcess.running=true while
    // running is a silent no-op, so queue the latest value instead of
    // dropping intermediate ticks silently.
    property real _pendingBrightness: -1
    
    Component.onCompleted: {
        detectBacklightDevice()
        readMaxBrightness()
        readBrightness()
    }

    function detectBacklightDevice() {
        detectProc.running = true
    }
    
    function readMaxBrightness() {
        if (maxBrightnessPath === "") return
        maxBrightnessProcess.command = ["/bin/cat", maxBrightnessPath]
        maxBrightnessProcess.running = true
    }

    function readBrightness() {
        if (backlightPath === "") return
        brightnessProcess.command = ["/bin/cat", backlightPath]
        brightnessProcess.running = true
    }
    
    function setBrightness(value) {
        // Clamp between 0 and 1
        const newValue = Math.max(0, Math.min(1, value))

        if (backlightPath === "")
            return

        // Coalesce: if a write is in flight, remember the latest value and
        // let onExited drain it.
        if (setBrightnessProcess.running) {
            root._pendingBrightness = newValue
            brightness = newValue
            return
        }

        // Use brightnessctl when available (works for most backlight devices).
        // Device/path go via positional args ($1/$2) — never interpolated —
        // and percent/sysfsValue are Math.rounded numbers.
        const percent = Math.round(newValue * 100)
        const sysfsValue = Math.round(newValue * (maxValue > 0 ? maxValue : 255))
        setBrightnessProcess.command = ["/bin/sh", "-c",
            "brightnessctl set \"$1\"% || echo \"$2\" | sudo tee \"$3\" >/dev/null; cat \"$3\"",
            "sh", String(percent), String(sysfsValue), backlightPath]
        setBrightnessProcess.running = true

        // Optimistic update for instant UI feedback; confirmed when the
        // setter process exits (see setBrightnessProcess.onExited).
        // External changes (Hyprland keybinds, power-manager dimming) arrive
        // via the FileView watch below, with the slow timer as backstop.
        brightness = newValue
    }
    
    function increaseBrightness() {
        setBrightness(brightness + 0.05)
    }
    
    function decreaseBrightness() {
        setBrightness(brightness - 0.05)
    }
    
    // Read max brightness
    Process {
        id: detectProc
        command: ["/bin/sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -n 1"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const dev = text.trim()
                // Validate kernel hwmon/backlight name — never trust it into
                // a shell string unvalidated.
                if (/^[A-Za-z0-9_-]+$/.test(dev)) {
                    root._backlightDevice = dev
                } else {
                    if (dev.length > 0)
                        console.warn(`[Brightness] rejecting suspicious device name: ${dev}`)
                    root._backlightDevice = ""
                }

                readMaxBrightness()
                readBrightness()
            }
        }
    }

    Process {
        id: maxBrightnessProcess
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && value > 0) {
                    maxValue = value
                }
            }
        }
    }
    
    // Read current brightness
    Process {
        id: brightnessProcess
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value)) {
                    currentValue = value
                    brightness = maxValue > 0 ? value / maxValue : 0
                }
            }
        }
    }
    
    // Set brightness process
    Process {
        id: setBrightnessProcess
        running: false
        // Confirm the write landed (covers rounding/clamping by brightnessctl),
        // then drain one coalesced slider value if queued.
        onExited: {
            readBrightness()
            if (root._pendingBrightness >= 0) {
                const v = root._pendingBrightness
                root._pendingBrightness = -1
                setBrightness(v)
            }
        }
    }

    // Event-driven refresh: the kernel notifies on sysfs writes from any
    // process (Hyprland keybinds call brightnessctl directly). sysfs files do
    // not always emit inotify events, so the slow timer below is a backstop.
    FileView {
        path: root.backlightPath
        watchChanges: true
        onFileChanged: root.readBrightness()
    }

    // Safety net for writers the FileView misses (e.g. power-manager dimming
    // on idle). Fires every 15s instead of the old 2s poll.
    Timer {
        id: updateTimer
        interval: 15000
        repeat: true
        running: root.backlightPath !== ""
        onTriggered: readBrightness()
    }
}
