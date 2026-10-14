import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Services.SystemTray

RowLayout {
    id: root
    spacing: 4
    visible: hasItems

    // Icons hidden from the battery pill. You already have a dedicated
    // wifi widget (Network.qml) and don't want CopyQ in the bar.
    // Matched case-insensitively against id/title/tooltip.
    readonly property var hiddenPatterns: ["copyq", "nm-applet", "networkmanager", "org.kde.network", "network management"]

    function trayText(item): string {
        if (!item)
            return ""
        return `${item.id ?? ""} ${item.titleId ?? ""} ${item.title ?? ""} ${item.tooltipTitle ?? ""} ${item.tooltipSubTitle ?? ""}`
    }

    function isHidden(item): bool {
        const hay = trayText(item).toLowerCase()
        for (let i = 0; i < hiddenPatterns.length; i++) {
            if (hay.includes(hiddenPatterns[i]))
                return true
        }
        return false
    }

    readonly property int visibleCount: {
        const items = SystemTray.items?.values ?? []
        let n = 0
        for (let i = 0; i < items.length; i++) {
            if (!isHidden(items[i]))
                n++
        }
        return n
    }
    readonly property bool hasItems: visibleCount > 0
    
    Repeater {
        model: SystemTray.items
        
        delegate: Rectangle {
            readonly property bool filtered: root.isHidden(modelData)
            Layout.preferredWidth: filtered ? 0 : 24
            Layout.preferredHeight: 24
            visible: !filtered
            radius: 4
            color: "transparent"
            
            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: {
                    const icon = modelData.icon ?? ""
                    if (typeof icon === "string" && icon.includes("?path=")) {
                        const parts = icon.split("?path=")
                        const name = parts[0]
                        const base = parts[1] ?? ""
                        const fileName = name.slice(name.lastIndexOf("/") + 1)
                        return Qt.resolvedUrl(`${base}/${fileName}`)
                    }
                    return icon
                }
                visible: status === Image.Ready
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: {
                    if (!modelData)
                        return
                    if (mouse.button === Qt.LeftButton) {
                        if (typeof modelData.activate === "function")
                            modelData.activate(0, 0)
                    } else if (mouse.button === Qt.RightButton) {
                        if (modelData.menu && typeof modelData.menu.open === "function")
                            modelData.menu.open(0, 0)
                    }
                }
            }
        }
    }
}
