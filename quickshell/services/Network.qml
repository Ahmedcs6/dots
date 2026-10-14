pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "." as QsServices

Singleton {
    id: root

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: true
    readonly property bool scanning: rescanProc.running
    
    // Convenience properties for Control Center
    readonly property bool connected: active !== null
    readonly property string ssid: active?.ssid ?? "Not Connected"
    readonly property int signalStrength: active?.strength ?? 0
    
    property var savedNetworks: []

    function enableWifi(enabled: bool): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi(): void {
        const cmd = wifiEnabled ? "off" : "on";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function rescanWifi(): void {
        rescanProc.running = true;
    }

    function connectToNetwork(ssid: string, password: string): void {
        if (!ssid || ssid.trim().length === 0) {
            QsServices.Logger.warn("Network", "Invalid SSID: empty")
            return
        }

        // NOTE: no character denylist here. `exec(["nmcli", ...])` passes
        // argv directly (no shell), so SSIDs like `Tom & Jerry` or `a;b`
        // are safe. A denylist only broke legitimate network names.
        QsServices.Logger.info("Network", `Connecting to: ${ssid} ${password.length > 0 ? "(with password)" : "(saved)"}`)
        
        if (password && password.length > 0) {
            // Connect to new network with password
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ssid, "password", password]);
        } else {
            // Connect to saved network using connection name (which is usually the SSID)
            connectProc.exec(["nmcli", "connection", "up", "id", ssid]);
        }
    }

    function refreshSavedNetworks(): void {
        checkSavedProc.running = true;
    }
    
    function isNetworkSaved(ssid: string): bool {
        return savedNetworks.includes(ssid);
    }

    function disconnectFromNetwork(): void {
        if (active) {
            disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
        }
    }

    function getWifiStatus(): void {
        wifiStatusProc.running = true;
    }

    // Coalesced list refresh: `Process.running = true` on a running
    // process is a silent no-op, so bursts (monitor events + user
    // actions) used to drop refreshes. Queue instead.
    property bool _listPending: false
    function requestList(): void {
        if (getNetworks.running)
            root._listPending = true
        else
            getNetworks.running = true
    }

    // Event-driven refresh: `nmcli monitor` streams NetworkManager events
    // (device state, connections, connectivity). Any event re-lists visible
    // networks, and the list completion refreshes saved networks, so no
    // polling timer is needed. The cooldown timer below only fires if the
    // monitor process itself dies (e.g. NM restart).
    Process {
        id: monitorProc
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: requestList()
        }
        onExited: monitorRestartTimer.start()
    }

    Timer {
        id: monitorRestartTimer
        interval: 5000
        repeat: false
        running: false
        onTriggered: {
            if (!monitorProc.running)
                monitorProc.running = true
        }
    }

    Process {
        id: wifiStatusProc

        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: enableWifiProc

        onExited: {
            root.getWifiStatus();
            requestList();
        }
    }

    Process {
        id: rescanProc

        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            requestList();
        }
    }

    Process {
        id: connectProc

        stdout: SplitParser {
            onRead: data => {
                QsServices.Logger.debug("Network", `Connection output: ${data}`)
                requestList()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    QsServices.Logger.warn("Network", `Connection error: ${text.trim()}`)
                }
            }
        }
        onExited: (code, status) => {
            QsServices.Logger.debug("Network", `Connection exited code=${code} status=${status}`)
            requestList()
        }
    }

    Process {
        id: disconnectProc

        stdout: SplitParser {
            onRead: requestList()
        }
    }
    
    Process {
        id: checkSavedProc
        
        command: ["nmcli", "-g", "NAME", "connection", "show"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedNetworks = text.trim().split('\n').filter(n => n.length > 0);
                // Keep logs quiet during periodic refresh; only emit on actual changes.
                const current = root.savedNetworks
                const prev = root._prevSavedNetworks
                let changed = current.length !== prev.length
                if (!changed) {
                    for (let i = 0; i < current.length; i++) {
                        if (current[i] !== prev[i]) {
                            changed = true
                            break
                        }
                    }
                }
                if (changed) {
                    root._prevSavedNetworks = current.slice(0)
                    QsServices.Logger.debug("Network", `Saved networks: ${root.savedNetworks.length}`)
                }
            }
        }
    }

    property var _prevSavedNetworks: []
    
    Component.onCompleted: {
        refreshSavedNetworks();
    }

    // NOTE: `pollingActive` is retained for compatibility but no longer drives
    // a timer: saved networks refresh on NetworkManager events (see
    // monitorProc above) and after every user action.
    property bool pollingActive: true

    Process {
        id: getNetworks

        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3]?.replace(rep2, ":") ?? "",
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] ?? ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const networks = Array.from(networkMap.values());

                const rNetworks = root.networks;

                const destroyed = rNetworks.filter(rn => !networks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of networks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }

                // Piggyback: every visible-network refresh (startup, NM
                // monitor events, user actions) also refreshes saved networks.
                root.refreshSavedNetworks();
            }
        }
        onExited: {
            // Drain one coalesced refresh queued while we were running.
            if (root._listPending) {
                root._listPending = false
                getNetworks.running = true
            }
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
    }

    Component {
        id: apComp

        AccessPoint {}
    }
}
