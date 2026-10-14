import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../config" as QsConfig
import "../../../services" as QsServices

// Clean workspace container - no outer pill
Item {
    id: root
    
    property var screen
    
    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var hypr: QsServices.Hypr
    // Per-screen active workspace — the old global hypr.activeWsId lit up
    // the same workspace on every monitor.
    readonly property int activeWsId: hypr.activeWsIdFor(root.screen)
    readonly property var occupied: hypr.getOccupiedWorkspaces()
    
    implicitWidth: layout.implicitWidth
    implicitHeight: config.bar.height - config.bar.padding * 2
    
    RowLayout {
        id: layout
        
        anchors.centerIn: parent
        spacing: root.config.bar.workspaces.spacing
        
        Repeater {
            id: workspaceRepeater
            model: root.config.bar.workspaces.count
            
            delegate: Loader {
                required property int index

                source: "Workspace.qml"
                asynchronous: true
                
                onLoaded: {
                    item.workspaceId = index + 1
                    item.isActive = Qt.binding(() => root.activeWsId === (index + 1))
                    item.isOccupied = Qt.binding(() => root.occupied[index + 1] ?? false)
                    item.clicked.connect(function() {
                        if (root.hypr.activeWsId !== item.workspaceId) {
                            // NOTE: Hyprland ≥0.55 IPC is lua-based; dispatch
                            // takes a dispatcher object, not "workspace N".
                            root.hypr.dispatch(`hl.dsp.focus({ workspace = ${item.workspaceId} })`)
                        }
                    })
                }
            }
        }
    }
}
