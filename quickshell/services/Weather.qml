pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

Singleton {
    id: root

    // Consumer visibility control - set to false to pause polling when UI is hidden
    property bool active: true

    // Formatted as "21°C" (matches bar's raw-text style)
    property string tempC: "--°C"
    // Human-readable condition, e.g. "Sunny" (useful for tooltips)
    property string condition: ""
    // Material Design Icons glyph for the current condition, e.g. sunny/cloudy/rainy
    property string icon: String.fromCodePoint(0xF0599)
    property bool ready: false

    function refresh() {
        if (!fetchProc.running)
            fetchProc.running = true
    }

    // WorldWeatherOnline condition codes (what wttr.in j1 reports) to MDI codepoints
    function iconForCode(code: string): int {
        const c = parseInt(code, 10)
        switch (c) {
        case 113: {
            // Clear - sunny by day, clear night after dark
            const h = new Date().getHours()
            return (h >= 6 && h < 19) ? 0xF0599 : 0xF0594
        }
        case 116:
            return 0xF0595 // partly cloudy
        case 119:
        case 122:
            return 0xF0590 // cloudy / overcast
        case 143:
        case 248:
        case 260:
            return 0xF0591 // mist / fog
        case 200:
        case 386:
        case 389:
        case 392:
        case 395:
            return 0xF067E // thunder + rain
        case 227:
        case 230:
        case 320:
        case 323:
        case 326:
        case 329:
        case 332:
        case 335:
        case 338:
        case 368:
        case 371:
            return 0xF0598 // snow
        case 179:
        case 281:
        case 284:
        case 311:
        case 314:
        case 317:
        case 350:
        case 362:
        case 365:
            return 0xF067F // sleet / wintry mix
        case 182:
        case 185:
        case 263:
        case 266:
        case 293:
        case 296:
        case 299:
        case 302:
        case 305:
        case 308:
        case 353:
        case 356:
        case 359:
        case 374:
        case 377:
            return c === 305 || c === 308 ? 0xF0596 : 0xF0597 // heavy -> pouring, else rainy
        default:
            return 0xF0597
        }
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 600000 // 10 minutes - weather changes slowly
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: fetchProc
        command: ["curl", "-s", "--max-time", "15", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const conds = data ? data.current_condition : null
                    const cur = (conds && conds.length > 0) ? conds[0] : null
                    if (cur) {
                        const descs = cur.weatherDesc
                        root.tempC = `${cur.temp_C}°C`
                        root.condition = (descs && descs.length > 0 && descs[0].value) ? descs[0].value : ""
                        root.icon = String.fromCodePoint(root.iconForCode(cur.weatherCode))
                        root.ready = true
                    }
                } catch (e) {
                    // Keep previous values on parse/network failure
                }
            }
        }
    }
}
