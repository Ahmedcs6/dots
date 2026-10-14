import QtQuick 6.10
import QtQuick.Layouts 6.10

// Date/time header extracted from DashboardWindow.
// Owns the weekday + full date/time labels plus the status SummaryChips.
// Previously inline in DashboardWindow.qml (top RowLayout) mixed with the
// performance cards below — now a standalone component.
RowLayout {
    id: root

    required property var time
    required property var notifs
    required property var network
    required property var bluetooth
    required property var pywal
    required property color cText
    required property color cSubText
    required property color cPrimary
    property string fontFamily: "Inter"

    spacing: 8

    ColumnLayout {
        spacing: 2

        Text {
            text: root.time.format("dddd")
            font.family: root.fontFamily
            font.pixelSize: 28
            font.weight: Font.Bold
            color: root.cText
        }

        Text {
            text: root.time.format("MMMM d, yyyy  •  hh:mm")
            font.family: root.fontFamily
            font.pixelSize: 12
            color: root.cSubText
        }
    }

    Item { Layout.fillWidth: true }

    SummaryChip {
        icon: root.notifs.unreadCount > 0 ? "󰂚" : "󰂜"
        label: root.notifs.unreadCount > 0 ? `${root.notifs.unreadCount} unread` : "Inbox clear"
        accent: root.cPrimary
        textColor: root.cText
        fontFamily: root.fontFamily
    }

    SummaryChip {
        icon: root.network.connected ? "󰖩" : "󰖪"
        label: root.network.connected ? (root.network.ssid || "Wi‑Fi") : "Offline"
        accent: root.network.connected ? root.pywal.info : root.cSubText
        textColor: root.cText
        fontFamily: root.fontFamily
    }

    SummaryChip {
        icon: root.bluetooth.connected ? "󰂱" : "󰂲"
        label: root.bluetooth.connected ? (root.bluetooth.deviceName || "Bluetooth") : "Bluetooth"
        accent: root.bluetooth.connected ? root.pywal.secondary : root.cSubText
        textColor: root.cText
        fontFamily: root.fontFamily
    }

    component SummaryChip: Rectangle {
        id: chipRoot
        required property string icon
        required property string label
        required property color accent
        property color textColor: "#ffffff"
        property string fontFamily: "Inter"
        width: chipRow.implicitWidth + 18
        height: 34
        radius: 17
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.14)
        border.width: 1
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.18)

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: chipRoot.icon
                font.family: "Material Design Icons"
                font.pixelSize: 15
                color: chipRoot.accent
            }
            Text {
                text: chipRoot.label
                font.family: chipRoot.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                color: chipRoot.textColor
            }
        }
    }
}
