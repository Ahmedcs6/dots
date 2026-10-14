import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../controlcenter/components"

PanelWindow {
    id: root

    property bool shouldShow: false

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var time: QsServices.Time
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property var players: QsServices.Players
    readonly property var screenshot: QsServices.Screenshot
    readonly property var network: QsServices.Network
    readonly property var audio: QsServices.Audio
    readonly property var powerProfiles: QsServices.PowerProfiles
    readonly property var notifs: QsServices.Notifs
    readonly property var bluetooth: QsServices.Bluetooth
    readonly property var battery: UPower.displayDevice

    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cSurfaceContainer: pywal.surfaceContainerHigh
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: pywal.outlineVariant
    readonly property int batteryPercent: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool hasMedia: players?.active !== null
    readonly property var currentDate: time.date
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear: currentDate.getFullYear()
    readonly property int currentDay: currentDate.getDate()
    readonly property var dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property int calendarOffset: {
        const first = new Date(currentYear, currentMonth, 1).getDay()
        return (first + 6) % 7
    }
    readonly property int calendarDays: new Date(currentYear, currentMonth + 1, 0).getDate()
    readonly property var calendarCells: {
        const cells = []
        const prevMonthDays = new Date(currentYear, currentMonth, 0).getDate()
        for (let index = 0; index < 42; index++) {
            const dayNumber = index - calendarOffset + 1
            if (dayNumber < 1) {
                cells.push({ day: prevMonthDays + dayNumber, current: false, today: false })
            } else if (dayNumber > calendarDays) {
                cells.push({ day: dayNumber - calendarDays, current: false, today: false })
            } else {
                cells.push({ day: dayNumber, current: true, today: dayNumber === currentDay })
            }
        }
        return cells
    }

    function closeDashboard() {
        shouldShow = false
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    screen: QsServices.Hypr.focusedScreen ?? Quickshell.screens[0]
    anchors {
        top: true
        left: true
    }
    margins {
        top: (config.bar.height ?? 34) + config.dashboard.margin
        left: Math.max(0, Math.round((screen.width - config.dashboard.width) / 2))
    }
    implicitWidth: config.dashboard.width
    implicitHeight: shouldShow || panel.opacity > 0 ? Math.min(config.dashboard.height, screen.height - margins.top - 24) : 0
    visible: config.dashboard.enabled && (shouldShow || panel.opacity > 0)
    color: "transparent"

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        property real revealOffset: shouldShow ? 0 : -18
        scale: shouldShow ? 1.0 : 0.975
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Keys.onEscapePressed: root.closeDashboard()

        Behavior on scale {
            NumberAnimation { duration: 240; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        Behavior on revealOffset {
            NumberAnimation { duration: 260; easing.bezierCurve: [0.05, 0.7, 0.1, 1.0] }
        }

        AuroraSurface {
            anchors.fill: parent
            radius: 28
            color: root.cSurface
            strokeColor: root.cBorder
            accentColor: root.cPrimary
            elevation: 4
            highlighted: root.shouldShow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16

                // Date/time header — standalone component (separated from performance)
                DashboardDateTime {
                    Layout.fillWidth: true
                    time: root.time
                    notifs: root.notifs
                    network: root.network
                    bluetooth: root.bluetooth
                    pywal: root.pywal
                    cText: root.cText
                    cSubText: root.cSubText
                    cPrimary: root.cPrimary
                    fontFamily: QsConfig.Config.appearance.fontFamily
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        spacing: 16

                        SurfaceCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 254

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Calendar"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: root.cText
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: time.format("MMMM yyyy")
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 12
                                        color: root.cSubText
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 7
                                    rowSpacing: 6
                                    columnSpacing: 6

                                    Repeater {
                                        model: root.dayLabels

                                        Text {
                                            id: dayHeader
                                            required property var modelData
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            text: dayHeader.modelData
                                            font.family: QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: root.cSubText
                                        }
                                    }

                                    Repeater {
                                        model: root.calendarCells

                                        Rectangle {
                                            id: dayCell
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredHeight: 24
                                            radius: 12
                                            color: dayCell.modelData.today
                                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                                : dayCell.modelData.current
                                                    ? "transparent"
                                                    : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.03)
                                            border.width: dayCell.modelData.today ? 1 : 0
                                            border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.36)

                                            Text {
                                                anchors.centerIn: parent
                                                text: `${dayCell.modelData.day}`
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: 11
                                                font.weight: dayCell.modelData.today ? Font.Bold : Font.Medium
                                                color: dayCell.modelData.current ? root.cText : root.cSubText
                                                opacity: dayCell.modelData.current ? 1.0 : 0.45
                                            }
                                        }
                                    }
                                }
                            }
                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        spacing: 16

                        // Performance block — standalone component (separated from datetime)
                        DashboardPerformance {
                            Layout.fillWidth: true
                            systemUsage: root.systemUsage
                            pywal: root.pywal
                        }

                        SurfaceCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.hasMedia ? 124 : 88

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 0
                                spacing: 0

                                Text {
                                    visible: !root.hasMedia
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 22
                                    text: "No media playing"
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: root.cSubText
                                }

                                MediaCard {
                                    visible: root.hasMedia
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    mpris: root.players
                                    pywal: root.pywal
                                }
                            }
                        }

                    }
                }
            }
        }
    }

    component SurfaceCard: Rectangle {
        radius: 22
        color: root.cSurfaceContainer
        border.width: 1
        border.color: root.cBorder
    }

}