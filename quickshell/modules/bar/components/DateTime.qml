import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices

// Date/time pill content — wifi-style (icon + text).
// Display-only: hovering the pill swaps the compact clock for full date info.
Item {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var time: QsServices.Time
    readonly property bool isHovered: hoverArea.containsMouse

    implicitWidth: dateTimeRow.implicitWidth
    implicitHeight: 20

    RowLayout {
        id: dateTimeRow
        anchors.centerIn: parent
        spacing: 5

        // Calendar/clock icon
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "󰃭"
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: root.isHovered ? pywal.primary : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.8)

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Compact clock normally, full date details on hover
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.isHovered
                ? time.format("dddd, MMMM d, yyyy")
                : `${time.format("h:mm AP")} · ${time.format("ddd d")}`
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            elide: Text.ElideRight
            color: root.isHovered ? pywal.foreground : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.75)

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // Hover-only area (no click action)
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
