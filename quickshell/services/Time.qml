pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

// Missing QtQuick import caused binding warnings on load; the `??` defaults
// cover the transient window when the nested SystemClock child hasn't
// published its first valid QDateTime/ints yet (consumers only call
// format(), but the singleton API keeps these properties readable).
Singleton {
    property alias enabled: clock.enabled
    readonly property date date: clock.date ?? new Date()
    readonly property int hours: clock.hours ?? 0
    readonly property int minutes: clock.minutes ?? 0
    readonly property int seconds: clock.seconds ?? 0

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
