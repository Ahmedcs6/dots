import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "panel"

ShellRoot {
    id: root

    // Theme colors
    property color colBg: "#1a1b26"
    property color colFg: "#a9b1d6"
    property color colMuted: "#444b6a"
    property color colCyan: "#0db9d7"
    property color colPurple: "#ad8ee6"
    property color colRed: "#f7768e"
    property color colYellow: "#e0af68"
    property color colBlue: "#7aa2f7"

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    // System info properties
    property string kernelVersion: "Linux"
    property int diskUsage: 0
    property int volumeLevel: 0
    property string activeWindow: "Window"
    property string currentLayout: "Tile"

    // Kernel version
    Process {
        id: kernelProc
        command: ["uname", "-r"]
        stdout: SplitParser {
            onRead: data => {
                if (data) kernelVersion = data.trim()
            }
        }
        Component.onCompleted: running = true
    }

    // Disk usage
    Process {
        id: diskProc
        command: ["sh", "-c", "df / | tail -1"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var percentStr = parts[4] || "0%"
                diskUsage = parseInt(percentStr.replace('%', '')) || 0
            }
        }
        Component.onCompleted: running = true
    }

    // Volume level (wpctl for PipeWire)
    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var match = data.match(/Volume:\s*([\d.]+)/)
                if (match) {
                    volumeLevel = Math.round(parseFloat(match[1]) * 100)
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Active window title
    Process {
        id: windowProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    activeWindow = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Current layout (Hyprland: dwindle/master/floating)
    Process {
        id: layoutProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r 'if .floating then \"Floating\" elif .fullscreen == 1 then \"Fullscreen\" else \"Tiled\" end'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    currentLayout = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Event-based updates for window/layout (instant)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowProc.running = true
            layoutProc.running = true
        }
    }

    // Backup timer for window/layout (catches edge cases)
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            windowProc.running = true
            layoutProc.running = true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors {
								top: true
								left: true
                right: true
            }

            implicitHeight: 30
            color: root.colBg

            margins {
                top: 0
                bottom: 0
                left: 0
                right: 0
            }

            Rectangle {
                anchors.fill: parent
                color: root.colBg

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item { width: 8 }
										
										Logo {}

                    Item { width: 8 }

                    WorkspaceBar {}

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Text {
                        text: activeWindow
                        color: root.colPurple
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }


                    Text {
                        text: "Vol: " + volumeLevel + "%"
                        color: root.colPurple
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 0
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    DateTime {}
                    Item { width: 8 }
                }
            }
        }
    }
}

