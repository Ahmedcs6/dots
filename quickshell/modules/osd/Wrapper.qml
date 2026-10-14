import Quickshell
import Quickshell.Wayland
import QtQuick 6.10
import QtQuick.Layouts
import "../../services" as QsServices
import "../../config" as QsConfig

// Vertical pill OSD (ported from ~/src/quickshell-config/osd/OSD.qml).
// Single per-screen overlay, right-center, with stacked volume + brightness pills.
// Reacts to Audio / Brightness services, auto-hides via Config timeouts.
Scope {
    id: root

    required property var pywal

    readonly property var audio: QsServices.Audio
    readonly property var brightnessService: QsServices.Brightness
    readonly property var config: QsConfig.Config

    property bool showVolume: false
    property bool showBrightness: false
    property int currentVolume: 0
    property bool currentMuted: false
    property int currentBrightness: 50

    property int _prevVolume: -1
    property bool _prevMuted: false
    property int _prevBrightness: -1

    Component.onCompleted: {
        root.currentVolume = audio.percentage
        root.currentMuted = audio.muted
        root._prevVolume = root.currentVolume
        root._prevMuted = root.currentMuted
        root.currentBrightness = brightnessService.percentage
        root._prevBrightness = root.currentBrightness
    }

    Timer {
        id: volumeHideTimer
        interval: config.osd.volumeTimeoutMs
        onTriggered: root.showVolume = false
    }

    Timer {
        id: brightnessHideTimer
        interval: config.osd.brightnessTimeoutMs
        onTriggered: root.showBrightness = false
    }

    Connections {
        target: audio

        function onPercentageChanged() {
            root.currentVolume = audio.percentage
            if (root._prevVolume !== -1 && root.currentVolume !== root._prevVolume) {
                root.showVolume = true
                volumeHideTimer.restart()
            }
            root._prevVolume = root.currentVolume
        }

        function onMutedChanged() {
            root.currentMuted = audio.muted
            if (root.currentMuted !== root._prevMuted) {
                root.showVolume = true
                volumeHideTimer.restart()
            }
            root._prevMuted = root.currentMuted
        }
    }

    Connections {
        target: brightnessService

        function onPercentageChanged() {
            root.currentBrightness = brightnessService.percentage
            if (root._prevBrightness !== -1 && root.currentBrightness !== root._prevBrightness) {
                root.showBrightness = true
                brightnessHideTimer.restart()
            }
            root._prevBrightness = root.currentBrightness
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            visible: root.showVolume || root.showBrightness
            focusable: false
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell-osd"

            exclusionMode: ExclusionMode.Ignore
            mask: Region {}

            anchors {
                right: true
                top: true
                bottom: true
            }

            implicitWidth: 70

            Column {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // Volume pill — vertical
                Rectangle {
                    width: 36
                    height: 200
                    radius: 25
                    color: root.pywal.surfaceContainerHighest
                    border.color: root.pywal.outlineVariant
                    border.width: 1
                    opacity: root.showVolume ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    Accessible.role: Accessible.ProgressBar
                    Accessible.name: root.currentMuted ? "Volume: muted" : "Volume: " + root.currentVolume + "%"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 8

                        Text {
                            text: root.currentMuted ? "Mute" : root.currentVolume + "%"
                            color: root.pywal.onSurfaceVariant
                            font.pixelSize: 10
                            font.family: root.config.appearance.fontFamily
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Rectangle {
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignHCenter
                            width: 8
                            radius: 4
                            color: Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.12)
                            border.color: root.pywal.outlineVariant
                            border.width: 1
                            clip: true

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 2
                                height: Math.max(0, (parent.height - 4) * Math.max(0, Math.min(1, root.currentMuted ? 0 : root.currentVolume / 100)))
                                radius: 3
                                color: root.currentMuted ? Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.4) : root.pywal.primary

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 100
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        Text {
                            text: {
                                if (root.currentMuted || root.currentVolume <= 0)
                                    return "󰖁"
                                if (root.currentVolume < 33)
                                    return "󰕿"
                                if (root.currentVolume < 66)
                                    return "󰖀"
                                return "󰕾"
                            }
                            color: root.currentMuted ? Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.5) : root.pywal.primary
                            font.pixelSize: 15
                            font.family: root.config.appearance.materialIconFont
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Brightness pill — vertical
                Rectangle {
                    width: 36
                    height: 200
                    radius: 25
                    color: root.pywal.surfaceContainerHighest
                    border.color: root.pywal.outlineVariant
                    border.width: 1
                    opacity: root.showBrightness ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    Accessible.role: Accessible.ProgressBar
                    Accessible.name: "Brightness: " + root.currentBrightness + "%"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 8

                        Text {
                            text: root.currentBrightness + "%"
                            color: root.pywal.onSurfaceVariant
                            font.pixelSize: 10
                            font.family: root.config.appearance.fontFamily
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Rectangle {
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignHCenter
                            width: 8
                            radius: 4
                            color: Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.12)
                            border.color: root.pywal.outlineVariant
                            border.width: 1
                            clip: true

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 2
                                height: Math.max(0, (parent.height - 4) * Math.max(0, Math.min(1, root.currentBrightness / 100)))
                                radius: 3
                                color: root.pywal.warning

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 100
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        Text {
                            text: "󰃠"
                            color: root.pywal.warning
                            font.pixelSize: 15
                            font.family: root.config.appearance.materialIconFont
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
