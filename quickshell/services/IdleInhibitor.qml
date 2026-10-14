pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "." as QsServices

Singleton {
    id: root
    
    property bool inhibited: false
    property int inhibitorPid: -1
    
    onInhibitedChanged: {
        QsServices.Logger.debug("IdleInhibitor", `Inhibited changed: ${inhibited}`)
        if (inhibited) {
            enableInhibitor()
        } else {
            disableInhibitor()
        }
    }
    
    function enableInhibitor() {
        // Guard against double-enable leaking orphan sleep processes
        if (root.inhibitorPid > 0 || enableProcess.running)
            return
        QsServices.Logger.info("IdleInhibitor", "Enabling")
        enableProcess.running = true
    }
    
    // Enable idle inhibitor using systemd-inhibit
    Process {
        id: enableProcess
        command: ["/bin/sh", "-c", "systemd-inhibit --what=idle --who=QuickShell --why='Caffeine mode enabled' sleep infinity & echo $!"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const pid = parseInt(data.trim())
                if (!isNaN(pid) && pid > 0) {
                    root.inhibitorPid = pid
                    QsServices.Logger.debug("IdleInhibitor", `Started PID=${pid}`)
                }
            }
        }
    }
    
    // Disable idle inhibitor
    Process {
        id: disableProcess
        // Kill only our own inhibitor PID. Never use overbroad
        // `pkill -f 'systemd-inhibit.*QuickShell'` — it can kill
        // unrelated processes via full-cmdline match.
        command: ["/bin/sh", "-c", "kill \"$1\" 2>/dev/null", "sh", ""]
        running: false

        onExited: {
            root.inhibitorPid = -1
            QsServices.Logger.debug("IdleInhibitor", "Stopped")
        }
    }

    function disableInhibitor() {
        QsServices.Logger.info("IdleInhibitor", "Disabling")
        if (root.inhibitorPid > 0) {
            // bind PID via positional arg (no interpolation)
            disableProcess.command = ["/bin/sh", "-c", "kill \"$1\" 2>/dev/null", "sh", String(root.inhibitorPid)]
            disableProcess.running = true
        } else {
            root.inhibitorPid = -1
        }
    }
    
    Component.onCompleted: {
        QsServices.Logger.debug("IdleInhibitor", "Service loaded")
    }

    Component.onDestruction: {
        // Best-effort cleanup so `sleep infinity` doesn't outlive the shell.
        // Synchronous spawn is not available here; use a fire-and-forget kill
        // of our own PID only.
        if (root.inhibitorPid > 0) {
            disableProcess.command = ["/bin/sh", "-c", "kill \"$1\" 2>/dev/null", "sh", String(root.inhibitorPid)]
            disableProcess.running = true
        }
    }
}
