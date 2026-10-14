import QtQuick 6.10
import QtQuick.Layouts 6.10

// CircleCard.qml — Caelestia-style circle gauge card (~/src/shell MemoryCard / dash/Resources).
// Copy-paste usage:
//
//   CircleCard {
//       pywal: QsServices.Pywal
//       icon: "󰻠"
//       label: "CPU"
//       usage: SystemUsage.cpuPerc        // 0-1
//       subText: SystemUsage.cpuName
//       accent: pywal.primary
//   }
//   CircleCard {
//       pywal: pywal
//       icon: "󰍛"
//       label: "Memory"
//       usage: SystemUsage.memPerc        // 0-1
//       subText: `${gb(memUsed)} / ${gb(memTotal)} GB`
//       accent: pywal.color2
//       gauge: true                        // 270° gauge like Caelestia, false = full ring
//   }
Rectangle {
    id: root

    required property var pywal
    property string icon: ""
    property string label: ""
    property string subText: ""
    property real usage: 0 // 0-1
    property color accent: pywal.primary
    property bool gauge: true

    readonly property string pctText: `${Math.round(Math.max(0, Math.min(1, isNaN(usage) ? 0 : usage)) * 100)}%`

    radius: 14
    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
    implicitWidth: layout.implicitWidth + 32
    implicitHeight: layout.implicitHeight + 28

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 4

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                text: root.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: root.accent
            }
            Text {
                text: root.label
                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: pywal.foreground
            }
        }

        CircleProgress {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            implicitSize: 110
            strokeWidth: 9
            startAngle: root.gauge ? -225 : -90
            sweepAngle: root.gauge ? 270 : 360
            fgColour: root.accent
            bgColour: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
            value: root.usage

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.pctText
                    font.family: "Inter"
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    color: root.accent
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Used"
                    font.family: "Inter"
                    font.pixelSize: 10
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.55)
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            Layout.maximumWidth: 160
            text: root.subText
            font.family: "Inter"
            font.pixelSize: 11
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.7)
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
