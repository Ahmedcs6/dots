pragma Singleton

import Quickshell

Singleton {
    // Backwards-compat shim over the real tokens in AppearanceConfig.
    // Config.appearance only exposes fontFamily/materialIconFont;
    // layout tokens live in Config.appearanceTokens.
    readonly property var rounding: Config.appearanceTokens.rounding
    readonly property var spacing: Config.appearanceTokens.spacing
    readonly property var padding: Config.appearanceTokens.padding
    readonly property var font: Config.appearanceTokens.font
    readonly property var anim: Config.appearanceTokens.anim
    readonly property var transparency: Config.appearanceTokens.transparency
}
