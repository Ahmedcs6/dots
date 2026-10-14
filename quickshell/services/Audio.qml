pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

// Event-driven audio state via PipeWire.
// PwObjectTracker binds the nodes so volume/mute properties push updates;
// no polling processes are spawned. See docs:
// https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Pipewire/PwNodeAudio
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // Required: audio.volume/muted only emit while the node is bound.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    readonly property bool ready: sink?.ready ?? false
    readonly property bool muted: sink?.audio.muted ?? false
    readonly property real volume: Math.max(0, Math.min(1.5, sink?.audio.volume ?? 0))
    readonly property int percentage: Math.round(volume * 100)

    readonly property bool sourceReady: source?.ready ?? false
    readonly property bool sourceMuted: source?.audio.muted ?? false
    readonly property real sourceVolume: Math.max(0, Math.min(1.5, source?.audio.volume ?? 0))
    readonly property int sourcePercentage: Math.round(sourceVolume * 100)

    function setVolume(newVolume) {
        if (!sink?.audio) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1.5, newVolume))
    }

    function increaseVolume() {
        setVolume(volume + 0.05)
    }

    function decreaseVolume() {
        setVolume(volume - 0.05)
    }

    function setMute(m) {
        if (!sink?.audio) return
        sink.audio.muted = m
    }

    function toggleMute() {
        if (!sink?.audio) return
        sink.audio.muted = !sink.audio.muted
    }

    function setSourceVolume(newVolume) {
        if (!source?.audio) return
        source.audio.muted = false
        source.audio.volume = Math.max(0, Math.min(1.5, newVolume))
    }

    function setSourceMute(m) {
        if (!source?.audio) return
        source.audio.muted = m
    }

    function toggleSourceMute() {
        if (!source?.audio) return
        source.audio.muted = !source.audio.muted
    }
}
