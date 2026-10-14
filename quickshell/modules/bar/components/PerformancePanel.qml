import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices
import "../../../components"

FocusScope {
    id: root

    property bool shouldShow: false
    signal closeRequested()
    readonly property var pywal: QsServices.Pywal
    readonly property var sysUsage: QsServices.SystemUsage

    readonly property color cSurface: pywal.surface
    readonly property color cOnSurface: pywal.foreground
    readonly property color cOnSurfaceVariant: pywal.onSurfaceMuted
    readonly property color cPrimary: pywal.primary

    // Rolling history buffers (0-100), sampled while the popup is open
    property var cpuHistory: []
    property var memHistory: []
    property var gpuHistory: []

    function gb(bytes: real): string {
        return (bytes / (1024 ** 3)).toFixed(1)
    }

    function speed(bytesPerSec: real): string {
        if (bytesPerSec >= 1024 ** 2) return `${(bytesPerSec / (1024 ** 2)).toFixed(1)} MB/s`
        if (bytesPerSec >= 1024) return `${Math.round(bytesPerSec / 1024)} KB/s`
        return `${Math.round(bytesPerSec)} B/s`
    }

    Component.onCompleted: {
        const c = Math.max(0, sysUsage.cpuPerc * 100)
        const m = Math.max(0, sysUsage.memPerc * 100)
        const g = Math.max(0, sysUsage.gpuUsage)
        root.cpuHistory = Array(60).fill(c)
        root.memHistory = Array(60).fill(m)
        root.gpuHistory = Array(60).fill(g)
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: {
            root.cpuHistory = [...root.cpuHistory.slice(-59), Math.max(0, sysUsage.cpuPerc * 100)]
            root.memHistory = [...root.memHistory.slice(-59), Math.max(0, sysUsage.memPerc * 100)]
            if (sysUsage.hasGpu)
                root.gpuHistory = [...root.gpuHistory.slice(-59), Math.max(0, sysUsage.gpuUsage)]
        }
    }

    implicitWidth: 340
    implicitHeight: contentColumn.implicitHeight + 32
    focus: true

    Keys.onEscapePressed: closeRequested()

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
                        text: "󰘚"
                        font.family: "Material Design Icons"
                        font.pixelSize: 18
                        color: cPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Performance"
                        font.family: "Inter"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: cOnSurface
                    }

                    Text {
                        text: `${Math.round(sysUsage.cpuPerc * 100)}% CPU · ${Math.round(sysUsage.memPerc * 100)}% MEM`
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: cOnSurfaceVariant
                    }
                }
            }

            // CPU + Memory as CIRCLES (like ~/src/shell), side by side
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                CircleCard {
                    Layout.fillWidth: true
                    pywal: root.pywal
                    icon: "󰻠"
                    label: "CPU"
                    subText: sysUsage.cpuTemp > 0 ? `${sysUsage.cpuName} · ${Math.round(sysUsage.cpuTemp)}°C` : sysUsage.cpuName
                    usage: sysUsage.cpuPerc
                    accent: pywal.primary
                    gauge: true
                }

                CircleCard {
                    Layout.fillWidth: true
                    pywal: root.pywal
                    icon: "󰍛"
                    label: "Memory"
                    subText: `${gb(sysUsage.memUsed)} / ${gb(sysUsage.memTotal)} GB`
                    usage: sysUsage.memPerc
                    accent: pywal.color2
                    gauge: true
                }
            }

            // Storage — slim bar row (no history sampling for disk)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: 14
                color: Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.05)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "󰋊"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: pywal.color3
                        }

                        Text {
                            text: "Storage"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: cOnSurface
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: `${gb(sysUsage.diskUsed)} / ${gb(sysUsage.diskTotal)} GB`
                            font.family: "Inter"
                            font.pixelSize: 10
                            color: cOnSurfaceVariant
                        }

                        Text {
                            text: `${Math.round(sysUsage.diskPerc * 100)}%`
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: cOnSurface
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 5
                        radius: 2.5
                        color: Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.1)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(0, Math.min(1, sysUsage.diskPerc))
                            radius: 2.5
                            color: pywal.color3

                            Behavior on width {
                                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
            }

        }
    }

    // Chart card: icon + label, big % readout, live history sparkline
    component ChartCard: Rectangle {
        id: chartRoot
        required property var pywal
        property string icon: ""
        property string label: ""
        property string subLabel: ""
        property real usage: -1
        property color accent: "#ffffff"
        required property var history

        readonly property bool usageKnown: usage >= 0

        Layout.preferredHeight: 116
        radius: 14
        color: Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.05)

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
                    color: Qt.rgba(chartRoot.accent.r, chartRoot.accent.g, chartRoot.accent.b, 0.16)

                    Text {
                        anchors.centerIn: parent
                        text: chartRoot.icon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: chartRoot.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: chartRoot.label
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: cOnSurface
                    }

                    Text {
                        Layout.fillWidth: true
                        text: chartRoot.subLabel
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: cOnSurfaceVariant
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                Text {
                    text: chartRoot.usageKnown ? `${Math.round(chartRoot.usage)}%` : "—"
                    font.family: "Inter"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: cOnSurface
                }
            }

            Canvas {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                property var points: chartRoot.history
                onPointsChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var data = points
                    if (!data || data.length < 2) return
                    var w = width, h = height, n = data.length
                    var stepX = w / 59
                    function xAt(i) { return w - (n - 1 - i) * stepX }
                    function yAt(v) {
                        var c = Math.max(0, Math.min(100, v))
                        return h - 2 - (c / 100) * (h - 4)
                    }
                    var a = chartRoot.accent
                    ctx.beginPath()
                    ctx.moveTo(xAt(0), h)
                    for (var i = 0; i < n; i++) ctx.lineTo(xAt(i), yAt(data[i]))
                    ctx.lineTo(xAt(n - 1), h)
                    ctx.closePath()
                    ctx.fillStyle = Qt.rgba(a.r, a.g, a.b, 0.18)
                    ctx.fill()
                    ctx.beginPath()
                    for (var j = 0; j < n; j++) {
                        if (j === 0) ctx.moveTo(xAt(j), yAt(data[j]))
                        else ctx.lineTo(xAt(j), yAt(data[j]))
                    }
                    ctx.strokeStyle = a
                    ctx.lineWidth = 1.5
                    ctx.stroke()
                }
            }
        }
    }
}
