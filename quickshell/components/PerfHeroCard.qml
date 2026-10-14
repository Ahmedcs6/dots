import QtQuick 6.10
import QtQuick.Layouts 6.10

// Caelestia-style performance hero card: icon + label/sublabel, big usage
// readout, slim progress bar and a temperature row.
// usage: 0-100 percent, < 0 means unknown (shows an em dash).
// tempC: celsius, <= 0 hides the temperature row.
Rectangle {
    id: root

    required property var pywal
    property string icon: ""
    property string label: ""
    property string subLabel: ""
    property real usage: -1
    property real tempC: 0
    property color accent: pywal.primary

    readonly property bool usageKnown: usage >= 0
    readonly property string usageText: usageKnown ? `${Math.round(usage)}%` : "—"
    readonly property color tempColor: tempC >= 85 ? pywal.error : tempC >= 70 ? pywal.warning : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.6)

    radius: 14
    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
    implicitHeight: 138

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Icon badge
            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: root.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.label
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: pywal.foreground
                }

                Text {
                    Layout.fillWidth: true
                    text: root.subLabel
                    font.family: "Inter"
                    font.pixelSize: 10
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.55)
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            // Big usage readout
            Text {
                text: root.usageText
                font.family: "Inter"
                font.pixelSize: 26
                font.weight: Font.Bold
                color: pywal.foreground
            }
        }

        // Slim progress bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 5
            radius: 2.5
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.usageKnown ? parent.width * Math.max(0, Math.min(1, root.usage / 100)) : 0
                radius: 2.5
                color: root.accent

                Behavior on width {
                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                }
            }
        }

        // Temperature row
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.tempC > 0

            Item { Layout.fillWidth: true }

            Text {
                text: "󰔏"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: root.tempColor
            }

            Text {
                text: `${Math.round(root.tempC)}°C`
                font.family: "Inter"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.tempColor
            }
        }
    }
}
