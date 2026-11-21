import QtQuick 6.10

// Pruned to the members actually consumed by modules/bar/*.qml
// (Bar.qml uses `height`; Workspaces.qml uses `padding`, `workspaces.count`,
// `workspaces.spacing`). Removed as dead code: the seven hardcoded color
// tokens (Workspaces.qml colors come straight from the Pywal singleton),
// deprecated `unifiedPill`/`pillPadding` (built into Bar.qml), indicator and
// animation flags with no readers, and the unused `islands` styling object.
QtObject {
    readonly property var workspaces: QtObject {
        property int count: 8
        property int spacing: 6
    }

    // Floating island bar design
    readonly property int height: 36                // Compact floating islands
    readonly property int padding: 4                // Tight padding around content
}
