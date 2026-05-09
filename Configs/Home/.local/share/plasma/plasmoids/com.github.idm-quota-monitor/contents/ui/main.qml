import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    readonly property string scriptPath: Qt.resolvedUrl("../../fetch_quota.py").toString().replace("file://", "")

    // Per-connection data
    property var adsl: ({ percent: 0, remaining: "", updated: "", days_left: null, expiry: "", expiry_time: null, error: "" })
    property var lte:  ({ percent: 0, remaining: "", updated: "", days_left: null, expiry: "", expiry_time: null, error: "" })
    property var adslHistory: []
    property var lteHistory:  []

    property bool loading: false

    readonly property bool configured: Plasmoid.configuration.username !== ""
                                    && Plasmoid.configuration.password !== ""

    readonly property string connChoice: Plasmoid.configuration.connectionChoice

    function pctColor(pct) {
        return pct >= 90 ? "#e74c3c" : pct >= 70 ? "#f39c12" : "#2ecc71"
    }

    preferredRepresentation: compactRepresentation

    // ── Sync credentials to ~/.config/IDMQuota/config.conf ───────────────
    property bool _refreshAfterWrite: false

    P5Support.DataSource {
        id: fileWriter
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            fileWriter.disconnectSource(source)
            if (root._refreshAfterWrite) {
                root._refreshAfterWrite = false
                Qt.callLater(root.runScript)
            }
        }
    }

    function toHex(str) {
        var r = ""
        for (var i = 0; i < str.length; i++)
            r += str.charCodeAt(i).toString(16).padStart(2, "0")
        return r
    }

    function writeConfigFile() {
        if (!configured) return
        var u = toHex(Plasmoid.configuration.username)
        var p = toHex(Plasmoid.configuration.password)
        fileWriter.connectSource("python3 " + scriptPath + " --write-config " + u + " " + p)
    }

    Timer {
        id: credentialsChangedTimer
        interval: 50
        repeat: false
        onTriggered: {
            root._refreshAfterWrite = true
            root.writeConfigFile()
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onUsernameChanged() { credentialsChangedTimer.restart() }
        function onPasswordChanged() { credentialsChangedTimer.restart() }
    }

    Component.onCompleted: writeConfigFile()

    // ── Fetch both connections ────────────────────────────────────────────
    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            runner.disconnectSource(source)
            root.loading = false
            try {
                var d = JSON.parse(data["stdout"])
                if (d.adsl) root.adsl = d.adsl
                if (d.lte)  root.lte  = d.lte
                if (d.adsl_history) root.adslHistory = d.adsl_history
                if (d.lte_history)  root.lteHistory  = d.lte_history
            } catch (e) {
                root.adsl = { percent: 0, remaining: "", updated: "", error: "Parse error" }
                root.lte  = { percent: 0, remaining: "", updated: "", error: "Parse error" }
            }
        }
    }

    function runScript() {
        if (!configured) return
        loading = true
        runner.connectSource("python3 " + scriptPath)
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.runScript()
    }

    // ── Compact: panel bar with clickable connection toggle ───────────────
    compactRepresentation: MouseArea {
        id: compactArea
        implicitWidth: panelLayout.implicitWidth + Kirigami.Units.largeSpacing * 2
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: panelLayout
            anchors.centerIn: parent
            spacing: 4

            // activeData lives on the RowLayout so all children can use parent.activeData
            readonly property var activeData: root.connChoice === "lte" ? root.lte : root.adsl

            // ── Connection toggle badge ───────────────────────────────────
            Item {
                id: connToggle
                implicitWidth: connLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                height: 14

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r,
                                   Kirigami.Theme.highlightColor.g,
                                   Kirigami.Theme.highlightColor.b,
                                   toggleArea.containsMouse ? 0.35 : 0.18)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                PC3.Label {
                    id: connLabel
                    anchors.centerIn: parent
                    text: root.connChoice === "lte" ? "LTE" : "ADSL"
                    font.pixelSize: 9
                    font.bold: true
                }

                // Intercepts clicks here — stops propagation to outer MouseArea
                MouseArea {
                    id: toggleArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Plasmoid.configuration.connectionChoice =
                            (root.connChoice === "lte" ? "adsl" : "lte")
                    }
                }
            }

            // ── Progress bar ──────────────────────────────────────────────
            Item {
                width: 55
                height: 5

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Qt.rgba(Kirigami.Theme.textColor.r,
                                   Kirigami.Theme.textColor.g,
                                   Kirigami.Theme.textColor.b, 0.15)
                }
                Rectangle {
                    width: !root.configured || panelLayout.activeData.error
                           ? 0
                           : parent.width * Math.min(panelLayout.activeData.percent / 100, 1)
                    height: parent.height
                    radius: 2
                    color: root.loading
                           ? Kirigami.Theme.disabledTextColor
                           : root.pctColor(panelLayout.activeData.percent)
                    Behavior on width { NumberAnimation { duration: 500 } }
                    Behavior on color { ColorAnimation  { duration: 400 } }
                }
            }

            // ── Percentage label ──────────────────────────────────────────
            PC3.Label {
                text: !root.configured                    ? "setup"
                    : root.loading                        ? "…"
                    : panelLayout.activeData.error        ? "err"
                    : panelLayout.activeData.percent.toFixed(1) + "%"
                font.pixelSize: 10
                font.bold: true
                color: !root.configured || panelLayout.activeData.error
                       ? Kirigami.Theme.disabledTextColor
                       : root.loading
                         ? Kirigami.Theme.textColor
                         : root.pctColor(panelLayout.activeData.percent)
            }

            // Trailing gap so widget doesn't crowd its neighbour
            Item { width: Kirigami.Units.smallSpacing }
        }
    }

    // ── Full popup: single view, ADSL left — logo center — LTE right ─────
    fullRepresentation: Item {
        Layout.preferredWidth:  958
        Layout.preferredHeight: 327

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: 0

            // Main row
            RowLayout {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                spacing: 0

                ConnectionTab {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    data_:    root.adsl
                    loading:  root.loading
                    pctColor: root.pctColor(root.adsl.percent)
                    label:    "ADSL"
                }

                Image {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: -25
                    source: Qt.resolvedUrl("../images/logo.png")
                    fillMode: Image.PreserveAspectFit
                    width:  230
                    height: 115
                    sourceSize.width:  230
                    sourceSize.height: 115
                    opacity: 0.85
                }

                ConnectionTab {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    data_:    root.lte
                    loading:  root.loading
                    pctColor: root.pctColor(root.lte.percent)
                    label:    "LTE"
                }
            }

            // ── Footer ────────────────────────────────────────────────────
            Canvas {
                id: eolBar
                Layout.fillWidth: true
                height: 38

                property real tick: 0

                Timer {
                    interval: 32; running: true; repeat: true
                    onTriggered: { eolBar.tick += 0.016; eolBar.requestPaint() }
                }

                function hsl(h, s, l, a) {
                    h = ((h % 360) + 360) % 360 / 360
                    var q = l < 0.5 ? l*(1+s) : l+s-l*s
                    var p = 2*l - q
                    function c(t) {
                        if (t<0) t+=1; if (t>1) t-=1
                        if (t<1/6) return p+(q-p)*6*t
                        if (t<1/2) return q
                        if (t<2/3) return p+(q-p)*(2/3-t)*6
                        return p
                    }
                    return Qt.rgba(c(h+1/3), c(h), c(h-1/3), a)
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var cx      = width / 2
                    var cy      = height / 2
                    var hueBase = (tick * 40) % 360
                    var pulse   = 0.5 + 0.5 * Math.sin(tick * 1.8)
                    var text    = "~~~~~~~~~~~~  End Of Line  ~~~~~~~~~~~~"

                    ctx.font         = "bold 19px sans-serif"
                    ctx.textAlign    = "center"
                    ctx.textBaseline = "middle"

                    // Glow passes
                    for (var g = 3; g >= 1; g--) {
                        ctx.shadowColor = hsl(hueBase + 180, 1.0, 0.65, 0.6 * pulse)
                        ctx.shadowBlur  = g * 11
                        var grad = ctx.createLinearGradient(0, 0, width, 0)
                        grad.addColorStop(0.00, hsl(hueBase +   0, 0.95, 0.65, 0.15))
                        grad.addColorStop(0.25, hsl(hueBase +  90, 0.95, 0.65, 0.15))
                        grad.addColorStop(0.50, hsl(hueBase + 180, 0.95, 0.65, 0.15))
                        grad.addColorStop(0.75, hsl(hueBase + 270, 0.95, 0.65, 0.15))
                        grad.addColorStop(1.00, hsl(hueBase + 360, 0.95, 0.65, 0.15))
                        ctx.fillStyle = grad
                        ctx.fillText(text, cx, cy)
                    }

                    // Main text with RGB gradient
                    ctx.shadowBlur  = 14 * pulse
                    ctx.shadowColor = hsl(hueBase + 180, 1.0, 0.65, 0.7 * pulse)
                    var mainGrad = ctx.createLinearGradient(0, 0, width, 0)
                    mainGrad.addColorStop(0.00, hsl(hueBase +   0, 0.95, 0.70, 0.85))
                    mainGrad.addColorStop(0.25, hsl(hueBase +  90, 0.95, 0.70, 0.85))
                    mainGrad.addColorStop(0.50, hsl(hueBase + 180, 0.95, 0.70, 0.85))
                    mainGrad.addColorStop(0.75, hsl(hueBase + 270, 0.95, 0.70, 0.85))
                    mainGrad.addColorStop(1.00, hsl(hueBase + 360, 0.95, 0.70, 0.85))
                    ctx.fillStyle = mainGrad
                    ctx.fillText(text, cx, cy)
                    ctx.shadowBlur  = 0
                    ctx.shadowColor = "transparent"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing

                PC3.Button {
                    text: "Settings"
                    icon.name: "configure"
                    onClicked: Plasmoid.internalAction("configure").trigger()
                }

                Item { Layout.fillWidth: true }

                PC3.Button {
                    text: root.loading ? "Loading…" : "Refresh"
                    icon.name: "view-refresh"
                    enabled: !root.loading && root.configured
                    onClicked: root.runScript()
                }
            }
        }
    }
}
