import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices

// Performance pill content — wifi-style single icon.
// Click toggles the performance popup (charts) in Bar.qml,
// mirroring components/Network.qml behavior.
Item {
    id: root

    property var bar  // Reference to Bar.qml root for inline popup toggle

    readonly property var pywal: QsServices.Pywal
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property real load: Math.max((systemUsage.cpuPerc ?? 0) * 100, (systemUsage.memPerc ?? 0) * 100)

    implicitWidth: perfRow.implicitWidth
    implicitHeight: 20

    RowLayout {
        id: perfRow
        anchors.centerIn: parent
        spacing: 5

        // CPU icon — single icon, no text values
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "󰘚"
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: {
                if (root.isHovered) return pywal.primary
                if (root.load > 80) return pywal.error
                return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.8)
            }

            Behavior on color { ColorAnimation { duration: 150 } }

            scale: root.isHovered ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
    }

    // Click handler — toggles performance charts popup
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: {
            if (root.bar) {
                root.bar.togglePopup("performance")
            }
        }
    }
}
