pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "." as QsServices

Singleton {
    id: root

    property bool inhibited: false

    onInhibitedChanged: {
        QsServices.Logger.debug("IdleInhibitor", `Inhibited changed: ${inhibited}`)
        inhibitorProc.running = inhibited
    }

    // Owned child process: systemd-inhibit holds the logind idle-inhibit lock
    // while it itself runs `sleep infinity`. Quickshell tracks this process
    // directly — setting running=false (and shell destruction/reload)
    // terminates the whole child tree, so there is nothing to leak.
    //
    // Never go back to `systemd-inhibit ... sleep infinity & echo $!`: $! is
    // the *wrapper* PID; killing it under kill-mode orphans the sleep child
    // and the inhibitor process-tree outlives the toggle.
    Process {
        id: inhibitorProc
        command: [
                    "systemd-inhibit",
                    "--what=idle",
                    "--who=QuickShell",
                    "--why=Caffeine mode enabled",
                    "sleep", "infinity"
                ]
        running: false
    }

    Component.onCompleted: {
        QsServices.Logger.debug("IdleInhibitor", "Service loaded")
    }

    // Belt-and-braces belt: fired only from Component.onDestruction, in case
    // destruction doesn't reap the owned child. Static pattern, no
    // interpolation → safe under AGENTS.md shell-command rules.
    Process {
        id: cleanupProc
        command: [
                    "/bin/sh", "-c",
                    "pkill -f 'systemd-inhibit --what=idle --who=QuickShell' 2>/dev/null; true",
                    "sh"
                ]
        running: false
    }

    Component.onDestruction: {
        if (inhibited) {
            QsServices.Logger.debug("IdleInhibitor", "Best-effort cleanup on destroy")
            cleanupProc.running = true
        }
    }
}
