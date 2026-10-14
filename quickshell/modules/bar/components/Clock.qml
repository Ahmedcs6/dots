import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices
import "../../../components/effects"

Item {
    id: root

    property var launcher
    property var controlCenter
    property var sidebar
    
    implicitWidth: clockRow.implicitWidth
    implicitHeight: clockRow.implicitHeight
    
    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8
        
        // Compact time display
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            
            // Hours (12-hour format)
            Text {
                id: hoursText
                text: QsServices.Time.format("hh AP").split(" ")[0]
                color: QsServices.Pywal.foreground
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "Inter"
                font.letterSpacing: 0.3
            }
            
            // Animated colon separator
            Text {
                id: colonSeparator
                text: ":"
                color: QsServices.Pywal.primary
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "Inter"
                opacity: 0.4
                
                // Blinks once per second via timer instead of continuous animation
                // to avoid constant GPU repaints
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: colonSeparator.opacity = colonSeparator.opacity === 1.0 ? 0.4 : 1.0
                }
            }
            
            // Minutes
            Text {
                id: minutesText
                text: QsServices.Time.format("mm")
                color: QsServices.Pywal.foreground
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "Inter"
                font.letterSpacing: 0.3
            }

            // AM/PM marker (12-hour format)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: QsServices.Time.format("AP")
                color: Qt.rgba(QsServices.Pywal.foreground.r, QsServices.Pywal.foreground.g, QsServices.Pywal.foreground.b, 0.6)
                font.pixelSize: 9
                font.weight: Font.Bold
                font.family: "Inter"
            }
        }
        
        // Compact date
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: QsServices.Time.format("ddd d")
            color: Qt.rgba(QsServices.Pywal.foreground.r, QsServices.Pywal.foreground.g, QsServices.Pywal.foreground.b, 0.6)
            font.pixelSize: 10
            font.weight: Font.Medium
            font.family: "Inter"
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                return
            }

            if (!root.launcher)
                return

            root.launcher.shouldShow = !root.launcher.shouldShow
            if (root.launcher.shouldShow) {
                if (root.controlCenter)
                    root.controlCenter.shouldShow = false
                if (root.sidebar)
                    root.sidebar.shouldShow = false
            }
        }
    }
}
