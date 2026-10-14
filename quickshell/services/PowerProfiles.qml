pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "." as QsServices

// Power Profiles Service (power-profiles-daemon).
// Event-driven: Quickshell's UPower PowerProfiles singleton tracks PPD over
// D-Bus, so ActiveProfile changes push instead of polling `powerprofilesctl`.
// The `which` check below runs once at startup (not on a timer).
Singleton {
    id: root

    // Synced mirrors of the C++ properties. The raw
    // `PowerProfiles.profile` can be undefined at QML binding time (missed
    // init notify) and would misreport "balanced", so consumers must use
    // these, updated in syncPerformance() on D-Bus notifies.
    property string activeProfile: "balanced"
    property var availableProfiles: ["balanced", "power-saver"]
    // Bool mirror of hasPerformanceProfile. The C++ property can be
    // undefined at QML binding time (missed init notify), which breaks
    // `visible:` bindings and can leave stale entries in array models, so
    // consumers must use this instead of the raw property.
    property bool hasPerformance: false
    property bool isAvailable: false

    Component.onCompleted: {
        checkAvailability()
        syncPerformance()
    }

    Connections {
        target: PowerProfiles
        function onHasPerformanceProfileChanged() { root.syncPerformance() }
        function onProfileChanged() { root.syncPerformance() }
    }

    function syncPerformance() {
        root.hasPerformance = PowerProfiles.hasPerformanceProfile === true
        root.availableProfiles = root.hasPerformance
            ? ["performance", "balanced", "power-saver"]
            : ["balanced", "power-saver"]
        const p = PowerProfiles.profile
        root.activeProfile = (p === undefined || p === null) ? "balanced" : profileToString(p)
    }

    function profileToString(profile: int): string {
        if (profile === PowerProfile.Performance) return "performance"
        if (profile === PowerProfile.PowerSaver) return "power-saver"
        return "balanced"
    }

    function stringToProfile(profile: string): int {
        if (profile === "performance") return PowerProfile.Performance
        if (profile === "power-saver") return PowerProfile.PowerSaver
        return PowerProfile.Balanced
    }

    function checkAvailability() {
        checkProc.running = true
    }

    Process {
        id: checkProc
        command: ["which", "powerprofilesctl"]
        onExited: code => {
            root.isAvailable = code === 0
            if (root.isAvailable) {
                QsServices.Logger.debug("PowerProfiles", "Service available")
                QsServices.Logger.info("PowerProfiles", `Active profile: ${root.activeProfile}`)
            }
        }
    }

    function setProfile(profile: string) {
        if (!isAvailable) return
        if (!availableProfiles.includes(profile)) return

        PowerProfiles.profile = stringToProfile(profile)
    }

    function getProfileIcon(profile: string): string {
        switch(profile) {
            case "performance": return "󰓅"  // rocket
            case "balanced": return "󰾅"  // scale-balance
            case "power-saver": return "󰂎"  // battery-heart
            default: return "󰚥"
        }
    }

    function getProfileLabel(profile: string): string {
        switch(profile) {
            case "performance": return "Performance"
            case "balanced": return "Balanced"
            case "power-saver": return "Power Saver"
            default: return profile
        }
    }
}
