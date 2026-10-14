import QtQuick 6.10
import "../config" as QsConfig

NumberAnimation {
    duration: QsConfig.Config.appearanceTokens.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: QsConfig.Config.appearanceTokens.anim.curves.standard
}
