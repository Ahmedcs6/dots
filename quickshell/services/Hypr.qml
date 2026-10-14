pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick 6.10

Singleton {
    id: root

    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors

    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    // Screen of the currently focused monitor (null if unknown).
    // Overlays bind to this with a screens[0] fallback so popups open
    // on the active monitor instead of always the primary.
    readonly property var focusedScreen: {
        const m = Hyprland.focusedMonitor
        if (!m)
            return null
        const screens = Quickshell.screens?.values ?? []
        for (let i = 0; i < screens.length; i++) {
            if (screens[i] && screens[i].name === m.name)
                return screens[i]
        }
        return null
    }

    // Per-screen active workspace id. The old global activeWsId made every
    // monitor's bar highlight the same workspace.
    function activeWsIdFor(screen: var): int {
        if (screen) {
            const mon = Hyprland.monitorFor(screen)
            const id = mon?.activeWorkspace?.id
            if (id !== undefined && id !== null)
                return id
        }
        return activeWsId
    }

    // Dispatch a Hyprland action. Hyprland ≥0.55 speaks lua over IPC, so
    // `request` must be a dispatcher object, e.g.
    //   "hl.dsp.focus({ workspace = 2 })"
    // ("workspace 2" style strings fail with a lua syntax error.)
    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    function monitorFor(screen: var): var {
        return Hyprland.monitorFor(screen);
    }

    // Get occupied workspaces (workspaces with windows)
    function getOccupiedWorkspaces(): var {
        const occupied = {};
        for (const ws of workspaces.values) {
            occupied[ws.id] = (ws.lastIpcObject?.windows ?? 0) > 0;
        }
        return occupied;
    }

    // Refresh timer to ensure updates when events are missed
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            Hyprland.refreshWorkspaces();
        }
    }

    // Debounce burst refreshes (e.g. movewindow storms) into one IPC round-trip
    property bool _needWorkspaces: false
    property bool _needToplevels: false
    property bool _needMonitors: false
    Timer {
        id: refreshDebounce
        interval: 200
        repeat: false
        onTriggered: {
            if (root._needToplevels) {
                Hyprland.refreshToplevels();
                root._needToplevels = false
            }
            if (root._needWorkspaces) {
                Hyprland.refreshWorkspaces();
                root._needWorkspaces = false
            }
            if (root._needMonitors) {
                Hyprland.refreshMonitors();
                root._needMonitors = false
            }
        }
    }

    function requestRefresh(workspaces: bool, toplevels: bool, monitors: bool): void {
        if (workspaces) root._needWorkspaces = true
        if (toplevels) root._needToplevels = true
        if (monitors) root._needMonitors = true
        refreshDebounce.restart()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: var): void {
            var n = event.name ?? ""
            // Hyprland ≥0.4x emits v2 variants (workspacev2/activewindowv2);
            // normalize instead of dropping.
            if (n.endsWith("v2"))
                n = n.slice(0, -2)

            // More aggressive refresh for workspace changes
            if (["workspace", "moveworkspace", "activespecial", "focusedmon", "activewindow"].includes(n)) {
                requestRefresh(true, false, true)
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                requestRefresh(true, true, false)
            } else if (n.includes("workspace")) {
                requestRefresh(true, false, false)
            } else if (n.includes("window")) {
                requestRefresh(true, true, false)
            } else if (n.includes("monitor")) {
                requestRefresh(false, false, true)
            }
        }
    }
}
