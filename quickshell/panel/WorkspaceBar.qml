import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts


Repeater {
		model: 9

		Rectangle {
				Layout.preferredWidth: 20
				Layout.preferredHeight: parent.height
				color: "transparent"

				property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
				property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
				property bool hasWindows: workspace !== null

				Text {
						text: index + 1
						color: parent.isActive ? root.colCyan : (parent.hasWindows ? root.colCyan : root.colMuted)
						font.pixelSize: root.fontSize
						font.family: root.fontFamily
						font.bold: true
						anchors.centerIn: parent
				}

				Rectangle {
						width: 20
						height: 3
						color: parent.isActive ? root.colPurple : root.colBg
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.bottom: parent.bottom
				}

				MouseArea {
						anchors.fill: parent
						onClicked: Hyprland.dispatch("workspace " + (index + 1))
				}
		}
}
