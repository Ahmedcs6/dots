import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts


Text {
		id: clockText
		text: Qt.formatDateTime(new Date(), "ddd, MMM dd - hh:mm AP")
		color: root.colCyan
		font.pixelSize: root.fontSize
		font.family: root.fontFamily
		font.bold: true
		Layout.rightMargin: 8

		Timer {
				interval: 1000
				running: true
				repeat: true
				onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, MMM dd - hh:mm AP")
		}
}
