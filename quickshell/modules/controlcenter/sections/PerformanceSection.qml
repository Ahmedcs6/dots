import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../components"
import "../../../services" as QsServices

// Caelestia-style performance overview: hero cards for CPU / GPU (with
// temperatures) plus memory, storage and network activity.
Item {
    readonly property var pywal: QsServices.Pywal
    readonly property var sysUsage: QsServices.SystemUsage

    function gb(bytes: real): string {
        return (bytes / (1024 ** 3)).toFixed(1)
    }

    function speed(bytesPerSec: real): string {
        if (bytesPerSec >= 1024 ** 2) return `${(bytesPerSec / (1024 ** 2)).toFixed(1)} MB/s`
        if (bytesPerSec >= 1024) return `${Math.round(bytesPerSec / 1024)} KB/s`
        return `${Math.round(bytesPerSec)} B/s`
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
            text: "System Performance"
            font.family: "Inter"
            font.pixelSize: 16
            font.weight: Font.Bold
            color: pywal.foreground
        }

        // CPU + GPU hero row — now with live charts
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            PerfChartCard {
                Layout.fillWidth: true
                pywal: pywal
                icon: "󰻠"
                label: "CPU"
                subLabel: sysUsage.cpuName !== "" ? sysUsage.cpuName : "Processor"
                usage: sysUsage.cpuPerc * 100
                accent: pywal.primary
                history: sysUsage.cpuHistory
            }
        }

        // Memory + Storage hero row
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            PerfChartCard {
                Layout.fillWidth: true
                pywal: pywal
                icon: "󰍛"
                label: "Memory"
                subLabel: `${gb(sysUsage.memUsed)} / ${gb(sysUsage.memTotal)} GB`
                usage: sysUsage.memPerc * 100
                accent: pywal.color2
                history: sysUsage.memHistory
            }

            PerfHeroCard {
                Layout.fillWidth: true
                pywal: pywal
                icon: "󰋊"
                label: "Storage"
                subLabel: `${gb(sysUsage.diskUsed)} / ${gb(sysUsage.diskTotal)} GB`
                usage: sysUsage.diskPerc * 100
                accent: pywal.color3
            }
        }

        Item { Layout.fillHeight: true }
    }
}
