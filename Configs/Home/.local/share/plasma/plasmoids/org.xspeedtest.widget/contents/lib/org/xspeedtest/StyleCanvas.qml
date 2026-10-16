import QtQuick
import org.kde.kirigami as Kirigami
import "Visualizers.js" as Viz

Item {
    id: root

    required property SpeedTestRunner runner
    required property var style

    property string channel: "auto"
    property bool animate: true
    property bool idleDrift: true

    property var draw: Viz.create(style.viz)
    property real level: 0
    property real clock: 0
    property real sampleClock: 0
    property var downHistory: []
    property var upHistory: []
    property var frame: ({ch: "idle", f: 0, p: 0, active: false, t: 0, dt: 0, hist: [], pd: 0, pu: 0})

    readonly property color ink: Kirigami.Theme.textColor
    readonly property var theme: ({
        d: [style.down[0], style.down[1]],
        u: [style.up[0], style.up[1]],
        p: ["#8f98ad", "#c7cee0"],
        track: css(ink, 0.12),
        fg: hex(ink),
        dim: css(ink, 0.6)
    })

    function css(color, alpha) {
        return "rgba(" + Math.round(color.r * 255) + "," + Math.round(color.g * 255) + "," + Math.round(color.b * 255) + "," + alpha + ")";
    }

    function hex(color) {
        var part = function (v) { return ("0" + Math.round(v * 255).toString(16)).slice(-2); };
        return "#" + part(color.r) + part(color.g) + part(color.b);
    }

    function advance(dt) {
        var phase = runner.phase;
        var downloading = phase === SpeedTestRunner.Downloading;
        var uploading = phase === SpeedTestRunner.Uploading;
        var done = phase === SpeedTestRunner.Done;
        clock += dt;

        var ch = channel;
        if (ch === "auto")
            ch = downloading || done ? "down" : uploading ? "up" : phase === SpeedTestRunner.Searching ? "ping" : "idle";

        var value = 0, progress = 0, active = false, hist = [];
        if (ch === "down") {
            value = runner.download;
            progress = downloading ? runner.progress : (uploading || done) ? 1 : 0;
            active = downloading;
            hist = downHistory;
        } else if (ch === "up") {
            value = runner.upload;
            progress = uploading ? runner.progress : done ? 1 : 0;
            active = uploading;
            hist = upHistory;
        } else if (ch === "ping") {
            progress = runner.progress;
            active = true;
        }

        var target = ch === "ping" && channel === "auto" ? 0.05 + 0.05 * Math.sin(clock * 6) : Viz.fraction(value);
        level += (target - level) * Math.min(1, dt * 6);

        sampleClock += dt;
        while (sampleClock > 0.08) {
            sampleClock -= 0.08;
            var list = downloading ? downHistory : uploading ? upHistory : null;
            if (list) {
                list.push(Viz.fraction(downloading ? runner.download : runner.upload));
                if (list.length > 70)
                    list.shift();
            }
        }

        frame = {
            ch: ch, f: level, p: progress, active: active, t: clock, dt: dt, hist: hist,
            pd: downloading ? runner.progress : (uploading || done) ? 1 : 0,
            pu: uploading ? runner.progress : done ? 1 : 0
        };
    }

    Connections {
        target: root.runner
        function onPhaseChanged() {
            if (root.runner.phase === SpeedTestRunner.Searching) {
                root.downHistory = [];
                root.upHistory = [];
            }
        }
    }

    FrameAnimation {
        running: root.animate && root.visible && root.width > 0 && root.height > 0
            && root.Window.window && root.Window.window.visible
            && (root.idleDrift || root.runner.busy || root.level > 0.01)
        onTriggered: {
            root.advance(Math.min(frameTime, 0.05));
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        // The FBO render target can be left holding a stretched frame from before a resize
        // settles (seen on the panel popup, whose size changes every time it opens). Force a
        // fresh paint at the final size instead of relying on Canvas to notice by itself.
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            if (width > 0 && height > 0)
                root.draw(ctx, width, height, root.frame, root.theme);
        }
    }
}
