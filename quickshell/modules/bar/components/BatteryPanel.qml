import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell.Services.UPower
import "../../../services" as QsServices
import "../../../components/effects"

FocusScope {
    id: popupPanel

    property bool shouldShow: false
    signal closeRequested()
    readonly property var pywal: QsServices.Pywal
    readonly property var powerProfiles: QsServices.PowerProfiles
    readonly property var battery: UPower.displayDevice

    readonly property color cSurface: pywal.surface
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cOnSurface: pywal.foreground
    readonly property color cOnSurfaceVariant: pywal.onSurfaceMuted

    readonly property int batteryPercent: Math.round((battery?.percentage ?? 0) * 100)
    readonly property string batteryState: battery?.state === UPowerDevice.Charging ? "Charging" : battery?.state === UPowerDevice.FullyCharged ? "Fully charged" : "Discharging"

    implicitWidth: 320
    implicitHeight: contentColumn.implicitHeight + 32
    focus: true

    Keys.onEscapePressed: closeRequested()

    // Power profiles are a closed set (performance/balanced/power-saver),
    // so rows are explicit: a Repeater over a JS-array model can leave
    // stale delegates when the array instance is replaced at startup.
    component ModeRow: Rectangle {
        id: rowRoot
        required property string profile
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        radius: 14
        color: powerProfiles.activeProfile === profile
            ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.16)
            : Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.05)
        border.width: 1
        border.color: powerProfiles.activeProfile === profile
            ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.4)
            : Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.08)

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
                width: 10
                height: 10
                radius: 5
                Layout.alignment: Qt.AlignVCenter
                color: powerProfiles.activeProfile === rowRoot.profile ? cPrimary : Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.25)
            }

            Text {
                Layout.fillWidth: true
                text: powerProfiles.getProfileLabel(rowRoot.profile)
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: powerProfiles.activeProfile === rowRoot.profile ? cPrimary : cOnSurface
            }

            Text {
                visible: powerProfiles.activeProfile === rowRoot.profile
                text: "󰌒"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: cPrimary
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: powerProfiles.setProfile(rowRoot.profile)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: cSurface

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 36
                    height: 36
                    radius: 12
                    color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: "󰁹"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: cPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Battery"
                        font.family: "Inter"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: cOnSurface
                    }

                    Text {
                        text: `${batteryPercent}% · ${batteryState}`
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: cOnSurfaceVariant
                    }
                }
            }

            // Power mode selector
            Text {
                text: "Power mode"
                font.family: "Inter"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: cOnSurfaceVariant
            }

            ModeRow {
                profile: "performance"
                visible: powerProfiles.hasPerformance
            }

            ModeRow {
                profile: "balanced"
            }

            ModeRow {
                profile: "power-saver"
            }

            Text {
                visible: !powerProfiles.isAvailable
                Layout.fillWidth: true
                text: "powerprofilesctl not available"
                font.family: "Inter"
                font.pixelSize: 11
                color: cOnSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
