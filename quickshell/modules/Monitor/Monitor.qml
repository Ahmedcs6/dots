import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

Item {
    id: root
    width: 200
    height: 100

    Button {
        id: monitorBtn
        text: "System Monitor"
        anchors.centerIn: parent

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: popup.open()
            onEntered: popup.open()
            onExited: popup.close()
        }
    }

    Popup {
        id: popup
        x: root.width
        y: 0
        width: 400
        height: 300
        modal: false

        Rectangle {
            anchors.fill: parent
            color: "#202020"
            radius: 8
            border.color: "#888"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                ChartView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    antialiasing: true

                    PieSeries {
                        PieSlice { label: "CPU"; value: monitorData.cpu_total }
                        PieSlice { label: "RAM"; value: monitorData.ram }
                        PieSlice { label: "GPU"; value: monitorData.gpu_usage }
                    }
                }

                ChartView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    antialiasing: true

                    BarSeries {
                        id: coreBars
                        Repeater {
                            model: monitorData.cores.length
                            BarSet {
                                label: "Core " + (index+1)
                                value: monitorData.cores[index]
                            }
                        }
                    }
                }
            }
        }
    }
}
