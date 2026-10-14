import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../components"
import "../controlcenter/components"

// Performance block extracted from DashboardWindow.
// Owns SystemStats + CPU/GPU hero cards. Previously inline in
// DashboardWindow.qml mixed under the date/time header — now standalone
// so datetime and performance evolve independently.
ColumnLayout {
    id: root

    required property var systemUsage
    required property var pywal

    spacing: 16

    SystemStats {
        Layout.fillWidth: true
        systemUsage: root.systemUsage
        pywal: root.pywal
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        PerfChartCard {
            Layout.fillWidth: true
            pywal: root.pywal
            icon: "󰻠"
            label: "CPU"
            subLabel: root.systemUsage.cpuName !== "" ? root.systemUsage.cpuName : "Processor"
            usage: (root.systemUsage.cpuPerc ?? 0) * 100
            accent: root.pywal.primary
            history: root.systemUsage.cpuHistory
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        PerfChartCard {
            Layout.fillWidth: true
            pywal: root.pywal
            icon: "󰍛"
            label: "Memory"
            subLabel: `${(root.systemUsage.memUsed / (1024 ** 3)).toFixed(1)} / ${(root.systemUsage.memTotal / (1024 ** 3)).toFixed(1)} GB`
            usage: (root.systemUsage.memPerc ?? 0) * 100
            accent: root.pywal.color2 ?? root.pywal.tertiary
            history: root.systemUsage.memHistory
        }
    }
}
