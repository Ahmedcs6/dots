pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "../config" as QsConfig
import "." as QsServices

// Screenshot/Screen Recording Service
Singleton {
    id: root
    
    property bool isRecording: false
    property string lastScreenshotPath: ""
    property string lastRecordingPath: ""
    property string screenshotsDir: QsConfig.Config.paths.screenshotsDir

    property string _slurpGeometry: ""
    property string _windowGeomText: ""
    // Pending capture path: only promoted to lastScreenshotPath on exit code 0.
    // Prevents stale paths to nonexistent files and wrong-file announces on
    // concurrent captures (single shared screenshotProc).
    property string _pendingScreenshotPath: ""
    property bool _captureBusy: false
    
    Component.onCompleted: {
        // Create screenshots directory if it doesn't exist
        mkdirProc.running = true
    }
    
    Process {
        id: mkdirProc
        command: ["mkdir", "-p", root.screenshotsDir]
    }
    
    function takeScreenshot(mode: string) {
        // mode: "screen", "window", "region"
        if (root._captureBusy) {
            QsServices.Logger.warn("Screenshot", "Capture already in progress, ignoring")
            return
        }
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
        const filename = `screenshot-${timestamp}.png`
        const filepath = `${screenshotsDir}/${filename}`

        if (mode === "region") {
            // For region selection, use slurp to get geometry then grim to capture
            root._captureBusy = true
            slurpProc.exec(["slurp"])
        } else if (mode === "screen") {
            // Capture entire screen
            root._captureBusy = true
            root._pendingScreenshotPath = filepath
            screenshotProc.exec(["grim", filepath])
        } else if (mode === "window") {
            // For active window, we need to use hyprctl to get window geometry
            // then use slurp with those coordinates
            root._captureBusy = true
            windowGeomProc.exec(["sh", "-c", "hyprctl activewindow -j | jq -r '.at[0],.at[1],.size[0],.size[1]' | paste -sd ' '"])
        }
    }
    
    // Get region geometry with slurp
    Process {
        id: slurpProc
        stdout: StdioCollector {
            onStreamFinished: root._slurpGeometry = text.trim()
        }
        onExited: code => {
            const geometry = root._slurpGeometry
            root._slurpGeometry = ""

            if (code !== 0) {
                root._captureBusy = false
                QsServices.Logger.error("Screenshot", `slurp failed with code: ${code}`)
                return
            }
            if (geometry === "") {
                root._captureBusy = false
                return
            }

            const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
            const filename = `screenshot-${timestamp}.png`
            const filepath = `${root.screenshotsDir}/${filename}`

            QsServices.Logger.debug("Screenshot", `Capturing region: ${geometry}`)
            root._pendingScreenshotPath = filepath
            screenshotProc.exec(["grim", "-g", geometry, filepath])
        }
    }
    
    // Get active window geometry
    Process {
        id: windowGeomProc
        stdout: StdioCollector {
            onStreamFinished: root._windowGeomText = text.trim()
        }
        onExited: code => {
            const out = root._windowGeomText
            root._windowGeomText = ""

            if (code !== 0) {
                root._captureBusy = false
                QsServices.Logger.error("Screenshot", `window geometry failed with code: ${code}`)
                return
            }
            if (out === "") {
                root._captureBusy = false
                return
            }

            const parts = out.split(' ')
            if (parts.length !== 4) {
                root._captureBusy = false
                QsServices.Logger.warn("Screenshot", `Unexpected window geometry format: ${out}`)
                return
            }

            const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
            const filename = `screenshot-${timestamp}.png`
            const filepath = `${root.screenshotsDir}/${filename}`
            const geometry = `${parts[0]},${parts[1]} ${parts[2]}x${parts[3]}`

            QsServices.Logger.debug("Screenshot", `Capturing window: ${geometry}`)
            root._pendingScreenshotPath = filepath
            screenshotProc.exec(["grim", "-g", geometry, filepath])
        }
    }
    
    Process {
        id: screenshotProc
        onExited: code => {
            root._captureBusy = false
            if (code === 0 && root._pendingScreenshotPath !== "") {
                root.lastScreenshotPath = root._pendingScreenshotPath
                QsServices.Logger.info("Screenshot", `Saved: ${root.lastScreenshotPath}`)
                
                // Copy to clipboard using wl-copy with shell redirection
                var path = root.lastScreenshotPath
                clipboardProc.exec(["sh", "-c", "wl-copy < \"$1\"", "sh", path])
                
                notifyProc.exec([
                    "notify-send",
                    "-i", root.lastScreenshotPath,
                    "Screenshot captured",
                    `Saved and copied to clipboard`
                ])
            } else {
                root._pendingScreenshotPath = ""
                QsServices.Logger.error("Screenshot", `Failed with code: ${code}`)
            }
        }
    }
    
    Process {
        id: clipboardProc
    }
    
    Process {
        id: notifyProc
    }
    
    function startRecording() {
        if (isRecording) return

        const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
        const filename = `recording-${timestamp}.mp4`
        const filepath = `${screenshotsDir}/${filename}`
        root.lastRecordingPath = filepath

        // Portable defaults: wf-recorder's built-in encoder works on
        // Intel/AMD/NVIDIA. The old hardcoded h264_vaapi + renderD128 broke
        // every non-Intel-VAAPI machine with a silent failure.
        recordProc.exec([
            "wf-recorder",
            "-f", filepath
        ])

        root.isRecording = true
        QsServices.Logger.info("Screenshot", "Recording started")
    }
    
    Process {
        id: recordProc
        onExited: code => {
            root.isRecording = false
            if (code === 0) {
                QsServices.Logger.info("Screenshot", `Recording saved: ${root.lastRecordingPath}`)
                notifyProc.exec([
                    "notify-send",
                    "-i", "video-x-generic",
                    "Screen recording saved",
                    root.lastRecordingPath
                ])
            }
        }
    }
    
    function stopRecording() {
        if (!isRecording) return

        // Narrow pkill to our own output file so foreign recordings survive.
        const path = root.lastRecordingPath
        const base = path.length > 0 ? path.slice(path.lastIndexOf("/") + 1) : ""
        stopRecordProc.command = base !== ""
            ? ["pkill", "-SIGINT", "-f", `wf-recorder.*${base}`]
            : ["pkill", "-SIGINT", "-f", "wf-recorder"]
        stopRecordProc.running = true
        // isRecording will be set to false when the recording process finishes
    }

    Process {
        id: stopRecordProc
        running: false
    }
    
    function openScreenshotsFolder() {
        openProc.exec(["xdg-open", screenshotsDir])
    }
    
    Process {
        id: openProc
    }
    
    function copyLastScreenshot() {
        if (!lastScreenshotPath) return

        var path = lastScreenshotPath
        copyProc.exec(["sh", "-c", "wl-copy < \"$1\"", "sh", path])
    }
    
    Process {
        id: copyProc
    }
    
    function deleteLastScreenshot() {
        if (!lastScreenshotPath) return
        
        deleteProc.exec(["rm", lastScreenshotPath])
    }
    
    Process {
        id: deleteProc
        onExited: code => {
            if (code === 0) {
                QsServices.Logger.info("Screenshot", `Deleted: ${root.lastScreenshotPath}`)
                root.lastScreenshotPath = ""
            }
        }
    }
}
