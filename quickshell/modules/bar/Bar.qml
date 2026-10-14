import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import "components" as BarComponents
import "../../components"
import "../../components/effects"
import "../../config" as QsConfig
import "../../services" as QsServices

Item {
    id: root
    
    property var screen
    property var barWindow
    property var controlCenter
    property var launcher
    property var sidebar

    // ═══ Inline Popup State ═══
    property string activePopup: ""  // "", "network", "battery", "performance", "bluetooth"
    readonly property bool hasPopup: activePopup !== ""
    readonly property real popupAreaHeight: hasPopup ? popupHost.height : 0
    
    function togglePopup(name: string) {
        if (activePopup === name) {
            activePopup = ""
        } else {
            activePopup = name
        }
    }
    function closePopup() {
        activePopup = ""
    }

    function popupAnchorTarget() {
        if (activePopup === "network") return connectivityPill
        if (activePopup === "battery") return powerPill
        if (activePopup === "performance") return performancePill
        if (activePopup === "bluetooth") return connectivityPill
        return rightPills
    }
    
    readonly property var config: QsConfig.Config
    readonly property var appearance: QsConfig.AppearanceConfig
    readonly property var pywal: QsServices.Pywal
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property var time: QsServices.Time
    readonly property var weather: QsServices.Weather

    function formatSpeed(bytesPerSec: real): string {
        if (bytesPerSec >= 1024 * 1024) return `${(bytesPerSec / (1024 * 1024)).toFixed(1)}M`
        if (bytesPerSec >= 1024) return `${Math.round(bytesPerSec / 1024)}K`
        return `${Math.round(bytesPerSec)}`
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // MINIMAL AESTHETIC BAR
    // Clean, professional, beautiful - inspired by modern Linux rice
    // ═══════════════════════════════════════════════════════════════════════
    
    // Main bar container with floating effect — pinned to top bar strip
    Item {
        id: barContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        anchors.topMargin: 1
        height: config.bar.height - 2  // bar height minus top+bottom margin
        
        // ═══════════════════════════════════════════════════════════════
        // LEFT MODULE - Workspaces
        // ═══════════════════════════════════════════════════════════════
        AuroraSurface {
            id: leftModule
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            width: leftContent.implicitWidth + 18
            
            radius: 20
            color: pywal.surfaceContainerHigh
            strokeColor: pywal.outlineVariant
            borderWidth: 0
            accentColor: pywal.primary
            elevation: 3
            
            // Smooth transitions
            Behavior on color {
                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
            }
            
            Behavior on width {
                NumberAnimation { duration: 350; easing.bezierCurve: [0.34, 1.56, 0.64, 1] }
            }
            
            RowLayout {
                id: leftContent
                anchors.centerIn: parent
                spacing: 10
                
                // Workspaces
                Loader {
                    id: workspacesLoader
                    Layout.alignment: Qt.AlignVCenter
                    asynchronous: true
                    source: "components/Workspaces.qml"
                    
                    Binding {
                        target: workspacesLoader.item
                        property: "screen"
                        value: root.screen
                        when: workspacesLoader.status === Loader.Ready && root.screen !== undefined
                        restoreMode: Binding.RestoreBinding
                    }
                }
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // RIGHT SIDE - Pills
        // ═══════════════════════════════════════════════════════════════
        Row {
            id: rightPills
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            
            // ═══ PILL 0b: Performance CPU/MEM (wifi-style) ═══
            AuroraSurface {
                id: performancePill
                height: 32
                width: performanceContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.secondary
                elevation: 3

                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                Row {
                    id: performanceContent
                    anchors.centerIn: parent
                    spacing: 4

                    Loader {
                        id: performanceLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Performance.qml"

                        Binding {
                            target: performanceLoader.item
                            property: "bar"
                            value: root
                            when: performanceLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }

            // ═══ PILL 1: Network + Bluetooth (Connectivity) ═══
            AuroraSurface {
                id: connectivityPill
                height: 32
                width: connectivityContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.info
                elevation: 3
                
                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                
                Row {
                    id: connectivityContent
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Loader {
                        id: networkLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Network.qml"
                        
                        Binding {
                            target: networkLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: networkLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                        
                        Binding {
                            target: networkLoader.item
                            property: "bar"
                            value: root
                            when: networkLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }

                    // Traffic monitor (live up/down speeds)
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `↓ ${root.formatSpeed(systemUsage.downloadSpeed)} ↑ ${root.formatSpeed(systemUsage.uploadSpeed)}`
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.75)
                    }
                }
            }
            
            // ═══ PILL 2: Brightness + Volume (Audio/Display) ═══
            AuroraSurface {
                id: audioPill
                height: 32
                width: audioContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.secondary
                elevation: 3
                
                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                
                Row {
                    id: audioContent
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Loader {
                        id: brightnessLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Brightness.qml"
                        
                        Binding {
                            target: brightnessLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: brightnessLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }
                    
                    Loader {
                        id: volumeLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Volume.qml"
                        
                        Binding {
                            target: volumeLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: volumeLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }
            
            // ═══ PILL 3: Battery + Control Center + Tray ═══
            AuroraSurface {
                id: powerPill
                height: 32
                width: powerContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.primary
                elevation: 3
                
                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                
                Row {
                    id: powerContent
                    anchors.centerIn: parent
                    spacing: 6
                    
                    // Status Indicators (Caffeine, DND)
                    Loader {
                        id: statusIndicatorsLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/StatusIndicators.qml"
                        visible: item?.hasActiveIndicators ?? false
                    }
                    
                    // Separator (only if status indicators visible)
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                        visible: statusIndicatorsLoader.item?.hasActiveIndicators ?? false
                    }
                    
                    // Battery
                    Loader {
                        id: batteryLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Battery.qml"

                        Binding {
                            target: batteryLoader.item
                            property: "bar"
                            value: root
                            when: batteryLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // MEDIA MODULE - Always visible (shows "No media" when not playing)
        // ═══════════════════════════════════════════════════════════════
        AuroraSurface {
            id: mediaModule
            anchors.left: leftModule.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            width: mediaPlayerLoader.implicitWidth + 18
            
            radius: 20
            color: pywal.surfaceContainerHigh
            strokeColor: pywal.outlineVariant
            borderWidth: 0
            accentColor: pywal.secondary
            elevation: 3
            
            clip: true
            
            Behavior on width {
                NumberAnimation { 
                    duration: 400
                    easing.bezierCurve: [0.34, 1.56, 0.64, 1]
                }
            }
            
            Loader {
                id: mediaPlayerLoader
                anchors.centerIn: parent
                asynchronous: true
                source: "components/MediaPlayer.qml"
                
                Binding {
                    target: mediaPlayerLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: mediaPlayerLoader.status === Loader.Ready && root.barWindow !== undefined
                    restoreMode: Binding.RestoreBinding
                }
                
                Binding {
                    target: mediaPlayerLoader.item
                    property: "mediaPopup"
                    value: null
                    when: mediaPlayerLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // CENTER MODULE - Raw date + weather + time text, no pill
        // e.g. "10/10/2026 <icon>21°C 8:14:12 AM"
        // ═══════════════════════════════════════════════════════════════
        Item {
            id: centerModule
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(centerRow.implicitWidth + 8, parent.width * 0.45)
            height: 32
            clip: true

            Row {
                id: centerRow
                anchors.centerIn: parent
                spacing: 6

                // Date
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.time.format("M/d/yyyy")
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.letterSpacing: 0.3
                    color: pywal.foreground
                }

                // Weather icon glued to the temperature
                Row {
                    id: weatherGroup
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.weather.icon
                        font.family: "Material Design Icons"
                        font.pixelSize: 15
                        color: pywal.primary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // Time ticks every second; tempC already includes the ° symbol
                        text: root.weather.tempC
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        font.letterSpacing: 0.3
                        color: pywal.foreground
                    }
                }

                // Time
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.time.format("h:mm:ss AP")
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.letterSpacing: 0.3
                    color: pywal.foreground
                }
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // INLINE POPUP HOST — popups expand below the bar within the same window
    // ═══════════════════════════════════════════════════════════════════════
    Item {
        id: popupHost
        anchors.top: barContainer.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: hasPopup ? popupContentWrapper.height + 12 : 0
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        // Match Control Center behavior: close after leaving popup focus area
        property bool mouseHasEntered: false
        property bool mouseInside: popupHoverHandler.hovered

        onVisibleChanged: {
            if (!visible) {
                mouseHasEntered = false
                popupCloseTimer.stop()
            }
        }

        Connections {
            target: root
            function onHasPopupChanged() {
                if (root.hasPopup) {
                    popupHost.mouseHasEntered = false
                    popupCloseTimer.stop()
                } else {
                    popupCloseTimer.stop()
                }
            }
        }

        Timer {
            id: popupCloseTimer
            interval: 400
            onTriggered: {
                if (!popupHost.mouseInside && popupHost.mouseHasEntered && root.hasPopup) {
                    root.closePopup()
                }
            }
        }
        
        // Click-outside scrim to dismiss popup
        MouseArea {
            anchors.fill: parent
            visible: hasPopup
            onClicked: root.closePopup()
        }
        
        // Popup content container — positioned below the triggering pill
        Item {
            id: popupContentWrapper
            y: 4
            x: {
                // Center popup under its trigger and clamp to host bounds
                const w = width
                const hostPadding = 12
                const anchor = root.popupAnchorTarget()

                if (anchor) {
                    const centerInHost = anchor.mapToItem(popupHost, anchor.width / 2, anchor.height).x
                    return Math.max(hostPadding, Math.min(popupHost.width - w - hostPadding, centerInHost - (w / 2)))
                }

                return Math.max(hostPadding, popupHost.width - w - hostPadding)
            }
            width: activePopup === "battery" ? 320 : 340
            height: {
                if (batPanelLoader.active && batPanelLoader.item)
                    return batPanelLoader.item.implicitHeight
                if (netPanelLoader.active && netPanelLoader.item)
                    return netPanelLoader.item.implicitHeight
                if (perfPanelLoader.active && perfPanelLoader.item)
                    return perfPanelLoader.item.implicitHeight
                if (btPanelLoader.active && btPanelLoader.item)
                    return btPanelLoader.item.implicitHeight
                return 0
            }

            // Entry animation
            scale: hasPopup ? 1.0 : 0.92
            opacity: hasPopup ? 1 : 0
            transformOrigin: Item.TopRight

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            HoverHandler {
                id: popupHoverHandler
                onHoveredChanged: {
                    if (hovered) {
                        popupHost.mouseHasEntered = true
                        popupCloseTimer.stop()
                    } else if (popupHost.mouseHasEntered && root.hasPopup) {
                        popupCloseTimer.restart()
                    }
                }
            }
            
            // Network Panel
            Loader {
                id: netPanelLoader
                anchors.fill: parent
                active: root.activePopup === "network"
                source: "components/NetworkPanel.qml"

                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }

                Connections {
                    target: netPanelLoader.item
                    enabled: netPanelLoader.status === Loader.Ready
                    function onCloseRequested() { root.closePopup() }
                }
            }

            // Battery Panel (power mode selector)
            Loader {
                id: batPanelLoader
                anchors.fill: parent
                active: root.activePopup === "battery"
                source: "components/BatteryPanel.qml"

                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }

                Connections {
                    target: batPanelLoader.item
                    enabled: batPanelLoader.status === Loader.Ready
                    function onCloseRequested() { root.closePopup() }
                }
            }

            // Performance Panel (system charts)
            Loader {
                id: perfPanelLoader
                anchors.fill: parent
                active: root.activePopup === "performance"
                source: "components/PerformancePanel.qml"

                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }

                Connections {
                    target: perfPanelLoader.item
                    enabled: perfPanelLoader.status === Loader.Ready
                    function onCloseRequested() { root.closePopup() }
                }
            }

            // Bluetooth Panel
            Loader {
                id: btPanelLoader
                anchors.fill: parent
                active: root.activePopup === "bluetooth"
                source: "components/BluetoothPanel.qml"

                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }

                Connections {
                    target: btPanelLoader.item
                    enabled: btPanelLoader.status === Loader.Ready
                    function onCloseRequested() { root.closePopup() }
                }
            }
        }
    }
}
