import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Rectangle {
		Layout.preferredWidth: 24
		Layout.preferredHeight: 24
		color: "transparent"

		Image {
				anchors.fill: parent
				source: "file:///home/ahmed/Gabimaru.jpg"
				fillMode: Image.PreserveAspectFit
		}
}

