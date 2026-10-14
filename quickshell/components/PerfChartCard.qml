import QtQuick 6.10
import QtQuick.Layouts 6.10

// PerfChartCard.qml — Caelestia-style performance widget with live chart.
// This is the "by charts" CPU / RAM / GPU card moved out of
// modules/bar/components/PerformancePanel.qml so any window
// (dashboard, control-center, bar popup) can reuse it.
//
// Copy-paste usage:
//   PerfChartCard {
//       pywal: QsServices.Pywal
//       icon: "󰻠"
//       label: "CPU"
//       subLabel: SystemUsage.cpuName
//       usage: SystemUsage.cpuPerc * 100
//       accent: pywal.primary
//       history: SystemUsage.cpuHistory
//   }
Rectangle {
    id: root

    required property var pywal
    property string icon: ""
    property string label: ""
    property string subLabel: ""
    property real usage: -1 // 0-100, < 0 = unknown
    property color accent: pywal.primary
    property var history: []

    readonly property bool usageKnown: usage >= 0
    readonly property color cOnSurface: pywal.foreground
    readonly property color cOnSurfaceVariant: pywal.onSurfaceMuted ?? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.6)

    radius: 14
    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
    implicitHeight: 116

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 9
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
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
                    color: root.cOnSurface
                }

                Text {
                    Layout.fillWidth: true
                    text: root.subLabel
                    font.family: "Inter"
                    font.pixelSize: 10
                    color: root.cOnSurfaceVariant
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            Text {
                text: root.usageKnown ? `${Math.round(root.usage)}%` : "—"
                font.family: "Inter"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: root.cOnSurface
            }
        }

        // Live history sparkline (0-100 values)
        Canvas {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            property var points: root.history
            onPointsChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var data = points
                if (!data || data.length < 2)
                    return
                var w = width, h = height, n = data.length
                var stepX = w / 59
                function xAt(i) { return w - (n - 1 - i) * stepX }
                function yAt(v) {
                    var c = Math.max(0, Math.min(100, v))
                    return h - 2 - (c / 100) * (h - 4)
                }
                var a = root.accent
                // fill
                ctx.beginPath()
                ctx.moveTo(xAt(0), h)
                for (var i = 0; i < n; i++)
                    ctx.lineTo(xAt(i), yAt(data[i]))
                ctx.lineTo(xAt(n - 1), h)
                ctx.closePath()
                ctx.fillStyle = Qt.rgba(a.r, a.g, a.b, 0.18)
                ctx.fill()
                // line
                ctx.beginPath()
                for (var j = 0; j < n; j++) {
                    if (j === 0)
                        ctx.moveTo(xAt(j), yAt(data[j]))
                    else
                        ctx.lineTo(xAt(j), yAt(data[j]))
                }
                ctx.strokeStyle = a
                ctx.lineWidth = 1.5
                ctx.stroke()
            }
        }
    }
}
