import Quickshell
import Quickshell.Services.UPower
import QtQuick 6.10
import Quickshell.Io
import "../services" as QsServices

Scope {
    id: root

    property list<var> warnLevels: [
        { level: 20, title: "Battery low", message: "Plug in soon", icon: "battery_alert" },
        { level: 10, title: "Battery very low", message: "Save your work", icon: "battery_alert" },
        { level: 5, title: "Battery critical", message: "Plug in now", icon: "battery_alert" }
    ]

    property var _warnedLevels: ({})
    // Edge-trigger state for plug/unplug + fully-charged events.
    property bool _wasFullyCharged: false
    // Grace period: ignore D-Bus init flapping right after shell load.
    property double _loadedAt: 0

    function _inGrace(): bool {
        return (Date.now() - root._loadedAt) < 5000
    }

    property int criticalLevel: 2
    property int criticalActionDelayMs: 5000
    property string criticalAction: "hibernate" // hibernate|poweroff|none

    function _resetWarned(): void {
        _warnedLevels = ({})
    }

    function _notify(title: string, body: string): void {
        // Use notify-send if present; otherwise just log.
        notifyProc.exec(["notify-send", title, body])
    }

    Process {
        id: notifyProc
    }

    Connections {
        target: UPower

        // Plug / unplug is a pure D-Bus push — no polling. Fires only on
        // actual transitions, never for the initial binding value.
        function onOnBatteryChanged(): void {
            if (!UPower.onBattery) {
                root._resetWarned()
                root._wasFullyCharged = false
            }
            if (root._inGrace())
                return

            const dev = UPower.displayDevice
            const p = dev ? Math.round((dev.percentage ?? 0) * 100) : -1
            if (!UPower.onBattery) {
                QsServices.Logger.info("Battery", "Charger connected")
                root._notify("Charger connected", p >= 0 ? `Battery at ${p}%` : "On AC power")
            } else {
                QsServices.Logger.info("Battery", "Charger disconnected")
                root._notify("Charger disconnected", p >= 0 ? `Battery at ${p}%` : "On battery power")
            }
        }
    }

    Connections {
        target: UPower.displayDevice
        enabled: UPower.displayDevice !== null

        // Fully-charged edge: transitions into FullyCharged while on AC.
        function onStateChanged(): void {
            const dev = UPower.displayDevice
            if (!dev || root._inGrace())
                return
            const full = dev.state === UPowerDevice.FullyCharged
            if (full && !root._wasFullyCharged && !UPower.onBattery) {
                QsServices.Logger.info("Battery", "Fully charged")
                root._notify("Battery fully charged", "You can unplug the charger")
            }
            root._wasFullyCharged = full
        }

        function onPercentageChanged(): void {
            const dev = UPower.displayDevice
            if (!UPower.onBattery || !dev)
                return

            const p = Math.round((dev.percentage ?? 0) * 100)

            // warn levels
            const sorted = [...warnLevels].sort((a, b) => b.level - a.level)
            for (let i = 0; i < sorted.length; i++) {
                const lvl = sorted[i]
                if (p <= lvl.level && !_warnedLevels[lvl.level]) {
                    _warnedLevels[lvl.level] = true
                    root._notify(lvl.title, `${lvl.message} (${p}%)`)
                }
            }

            if (!criticalTimer.running && p <= criticalLevel && criticalAction !== "none") {
                root._notify("Battery critical", `Running ${criticalAction} in ${Math.round(criticalActionDelayMs / 1000)}s (${p}%)`)
                criticalTimer.start()
            }
        }
    }

    Timer {
        id: criticalTimer
        interval: root.criticalActionDelayMs

        onTriggered: {
            if (root.criticalAction === "hibernate")
                Quickshell.execDetached(["systemctl", "hibernate"])
            else if (root.criticalAction === "poweroff")
                Quickshell.execDetached(["systemctl", "poweroff"])
        }
    }

    Component.onCompleted: {
        root._loadedAt = Date.now()
        const dev = UPower.displayDevice
        root._wasFullyCharged = dev ? dev.state === UPowerDevice.FullyCharged : false
    }
}
