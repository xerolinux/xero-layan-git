import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore;
import org.kde.plasma.components 2.0 as Plasma;
import org.kde.kwin 2.0;

Item {
    id: root

    readonly property var patterns: (
        KWin.readConfig("patterns", "yakuake\nurxvt\nkeepassxc")
            .split("\n")
            .map(function(rule) {
                return rule.trim().toLowerCase();
            })
    )

    readonly property var blurMatching: (
        KWin.readConfig("blurMatching", true)
    )

    readonly property var blurContent: (
        KWin.readConfig("blurContent", false)
    )

    PlasmaCore.DataSource {
        id: shell
        engine: 'executable'

        connectedSources: []

        function run(cmd) {
            shell.connectSource(cmd);
        }

        onNewData: {
            shell.disconnectSource(sourceName);
        }
    }

    function onClientAdded(client) {
        if (!shell) return;

        var cls = client.resourceClass.toString().toLowerCase();
        var name = client.resourceName.toString().toLowerCase();
        var clsMatches = root.patterns.indexOf(cls) >= 0 || root.patterns.indexOf(name) >= 0;

        if (clsMatches == root.blurMatching) {
            if (root.blurContent) {
                registerHintUpdater(client);
            } else {
                var wid = "0x" + client.windowId.toString(16);
                shell.run("xprop -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION 0 -id " + wid);
            }
        }
    }

    function registerHintUpdater(client) {
        var prevWidth  = client.geometry.width;
        var prevHeight = client.geometry.height;
        var handler = function() {
            try { if (!root) return; } catch(e) {
                client.geometryChanged.disconnect(handler);
                throw e;
            }

            root.onClientGeometryChanged(client, prevWidth, prevHeight);

            prevWidth  = client.geometry.width;
            prevHeight = client.geometry.height;
        }

        client.geometryChanged.connect(handler);
        root.onClientGeometryChanged(client, 0, 0);
    }

    function onClientGeometryChanged(client, prevWidth, prevHeight) {
        if (!shell) return;

        /* Skip if window *size* isn't really changed */
        if (client.geometry.width === prevWidth && client.geometry.height === prevHeight)
            return;

        var wid = "0x" + client.windowId.toString(16);
        var region = "0,0," + client.geometry.width + "," + client.geometry.height;
        var cmd = "xprop -id " + wid + " -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION " + region
        shell.run(cmd);
    }

    Component.onCompleted: {
        console.log("FORCE-BLUR: starting the script");
        console.log(JSON.stringify(root.patterns));

        var clients = workspace.clientList();
        for (var i = 0; i < clients.length; i++) {
            root.onClientAdded(clients[i]);
        }

        workspace.onClientAdded.connect(root.onClientAdded);
    }
}
