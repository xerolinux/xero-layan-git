pragma Singleton
import QtQuick
import "Visualizers.js" as Viz

QtObject {
    readonly property var palettes: ({
        aurora: {down: ["#38e8ff", "#7c5cff"], up: ["#ff6ad5", "#ffb86b"]},
        sunset: {down: ["#ffb347", "#ff5e7e"], up: ["#c471ed", "#5f8bff"]},
        forest: {down: ["#7be495", "#1fb6a5"], up: ["#d4f06a", "#48c774"]},
        ocean: {down: ["#4fd1ff", "#2f6bff"], up: ["#7cf7d4", "#19b5a5"]},
        rose: {down: ["#ff8fab", "#ff4d8d"], up: ["#ffc2d1", "#d946ef"]},
        amber: {down: ["#ffd166", "#ff8c42"], up: ["#ffe8a3", "#f4a261"]},
        neon: {down: ["#b8ff3c", "#00e5a0"], up: ["#ff2bd6", "#7a5cff"]},
        nord: {down: ["#88c0d0", "#5e81ac"], up: ["#a3be8c", "#8fbcbb"]},
        crimson: {down: ["#ff5a5f", "#c81d4e"], up: ["#ffa26b", "#ff5a5f"]},
        lav: {down: ["#b79cff", "#7a5cff"], up: ["#8bd3ff", "#5b8def"]},
        mint: {down: ["#5eead4", "#22c1a3"], up: ["#a7f3d0", "#34d399"]}
    })

    readonly property var weights: [Font.DemiBold, Font.ExtraLight, Font.DemiBold, Font.Medium, Font.DemiBold, Font.Light]
    readonly property var radii: [10, 14, 18, 22, 6]

    readonly property var catalog: [
        [14, "downpour", "Downpour", "particles", "wide", "ocean"],
        [1, "aurora-arc", "Aurora Arc", "arc", "center", "aurora"],
        [2, "northern-ring", "Northern Ring", "ring", "center", "aurora"],
        [3, "redline-tach", "Redline Tach", "ticks", "center", "crimson"],
        [4, "frost-needle", "Frost Needle", "dial", "split", "nord"],
        [5, "glass-bar", "Glass Bar", "bar", "minimal", "ocean"],
        [7, "spectrum-deck", "Spectrum Deck", "eq", "wide", "neon"],
        [8, "live-trace", "Live Trace", "spark", "wide", "mint"],
        [9, "orbit-lab", "Orbit Lab", "orbit", "center", "lav"],
        [10, "lava-orb", "Lava Orb", "liquid", "center", "sunset"],
        [11, "led-halo", "LED Halo", "seg", "center", "amber"],
        [12, "twin-rings", "Twin Rings", "dualring", "center", "aurora"],
        [13, "sonar-sweep", "Sonar Sweep", "radar", "split", "forest"],
        [15, "cockpit-dial", "Cockpit Dial", "dial", "center", "amber"],
        [16, "honeycomb", "Honeycomb", "hex", "center", "sunset"],
        [17, "data-pipe", "Data Pipe", "pipe", "wide", "lav"],
        [18, "sunburst", "Sunburst", "spiral", "center", "sunset"],
        [19, "dot-matrix", "Dot Matrix", "dots", "wide", "neon"],
        [20, "ripple-pond", "Ripple Pond", "ripple", "center", "mint"],
        [21, "column-history", "Column History", "bars", "wide", "rose"],
        [22, "ribbon-flow", "Ribbon Flow", "ribbon", "wide", "aurora"],
        [34, "rail-arc", "Rail Arc", "arc", "sidebar", "aurora"],
        [35, "rail-trace", "Rail Trace", "spark", "sidebar", "ocean"],
        [37, "rail-history", "Rail History", "bars", "sidebar", "sunset"],
        [38, "rail-spectrum", "Rail Spectrum", "eq", "sidebar", "neon"],
        [39, "rail-wave", "Rail Wave", "wave", "sidebar", "lav"],
        [40, "rail-tach", "Rail Tach", "ticks", "sidebar", "amber"],
        [41, "dual-arc", "Dual Arc", "arc", "dual", "aurora"],
        [42, "dual-ring", "Dual Ring", "ring", "dual", "mint"],
        [44, "dual-orb", "Dual Orb", "liquid", "dual", "sunset"],
        [45, "dual-trace", "Dual Trace", "spark", "dual", "lav"],
        [46, "dual-spectrum", "Dual Spectrum", "eq", "dual", "neon"],
        [47, "dual-dial", "Dual Dial", "dial", "dual", "nord"],
        [48, "quiet-ribbon", "Quiet Ribbon", "ribbon", "minimal", "lav"],
        [50, "pulse-spectrum", "Pulse Spectrum", "eq", "minimal", "sunset"]
    ]

    readonly property var list: catalog.map(function (row) {
        return {id: row[1], name: row[2]};
    })

    function resolve(id) {
        var row = catalog[0];
        for (var i = 0; i < catalog.length; ++i) {
            if (catalog[i][1] === id) {
                row = catalog[i];
                break;
            }
        }
        var index = row[0] - 1;
        return {
            id: row[1],
            name: row[2],
            viz: row[3],
            layout: row[4],
            down: palettes[row[5]].down,
            up: palettes[row[5]].up,
            radius: radii[index % radii.length],
            fontWeight: row[1] === "downpour" ? Font.DemiBold : weights[index % weights.length]
        };
    }

    function overlay(viz, layout) {
        return Viz.overlay(viz) && ["center", "split", "sidebar", "compact"].indexOf(layout) >= 0;
    }

    function valid() {
        var ids = {};
        for (var i = 0; i < catalog.length; ++i) {
            var row = catalog[i];
            if (ids[row[1]] || !Viz.known(row[3]) || !palettes[row[5]])
                return false;
            ids[row[1]] = true;
        }
        return true;
    }
}
