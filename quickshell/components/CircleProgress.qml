import QtQuick 6.10
import QtQuick.Shapes 6.10

// CircleProgress.qml — standalone port of ~/src/shell/components/controls/CircularProgress.qml
// No Caelestia deps (no Tokens / Colours / WavyLine). Just QtQuick.Shapes.
//
// value: 0-1 (clamped). Use SystemUsage.cpuPerc / memPerc directly.
// startAngle / sweepAngle: -90/360 = full ring, -225/270 = gauge like Caelestia MemoryCard.
Item {
    id: root

    property real value: 0
    property int startAngle: -90
    property int sweepAngle: 360
    property int strokeWidth: 8
    property color fgColour: "#ffffff"
    property color bgColour: Qt.rgba(fgColour.r, fgColour.g, fgColour.b, 0.18)
    property int implicitSize: 80

    property real clampedVal: Math.max(0.003, Math.min(1, isNaN(value) ? 0 : value)) // NOT readonly so Behavior animation works
    readonly property real size: Math.min(width, height)
    readonly property real arcRadius: Math.max(1, (size - strokeWidth) / 2)
    readonly property real gapAngle: sweepAngle >= 360 ? 4 : 0

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    // Background track
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bgColour
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle
                sweepAngle: root.sweepAngle
            }
        }
    }

    // Foreground value arc
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.fgColour
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle
                sweepAngle: Math.max(1, root.sweepAngle * root.clampedVal - root.gapAngle)
            }
        }
    }

    Behavior on clampedVal {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }
    Behavior on fgColour {
        ColorAnimation { duration: 300 }
    }
}
