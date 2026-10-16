import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property SpeedTestRunner runner
    required property SpeedSettings settings
    property bool compact: false
    property bool animate: true
    property bool idleDrift: true

    readonly property var style: Styles.resolve(settings.style)
    readonly property string layoutName: compact ? "compact" : style.layout
    readonly property bool overlay: Styles.overlay(style.viz, layoutName)
    readonly property real u: Kirigami.Units.gridUnit / 18
    readonly property int chipColumns: layoutName === "center" || layoutName === "wide" || layoutName === "minimal" || layoutName === "compact" ? 4 : 2
    readonly property bool errorState: runner.phase === SpeedTestRunner.Error
    readonly property var chipLabels: [qsTr("Ping"), qsTr("Jitter"), qsTr("Down"), qsTr("Up")]

    property real shownMbps: runner.mbps
    Behavior on shownMbps {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    readonly property string readout: Stream.readout(runner, shownMbps, settings)
    readonly property string unit: Stream.unit(runner, settings)
    readonly property string phaseText: Stream.phaseText(runner)
    readonly property string downText: Stream.speed(runner.download, settings)
    readonly property string upText: Stream.speed(runner.upload, settings)
    readonly property string serverText: errorState ? runner.errorString : (runner.server || qsTr("Ready to measure your connection"))

    function chipValue(index) {
        const value = [runner.ping, runner.jitter, runner.download, runner.upload][index];
        if (value <= 0)
            return "--";
        return index < 2 ? Stream.format(value) + " ms" : Stream.speed(value, settings) + " " + settings.unitLabel;
    }

    function layoutComponent(name) {
        switch (name) {
        case "wide":
            return wideLayout;
        case "split":
            return splitLayout;
        case "dual":
            return dualLayout;
        case "minimal":
            return minimalLayout;
        case "compact":
            return compactLayout;
        default:
            return centerLayout;
        }
    }

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Component { id: centerLayout; CenterLayout { view: root } }
    Component { id: wideLayout; WideLayout { view: root } }
    Component { id: splitLayout; SplitLayout { view: root } }
    Component { id: dualLayout; DualLayout { view: root } }
    Component { id: minimalLayout; MinimalLayout { view: root } }
    Component { id: compactLayout; CompactLayout { view: root } }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: root.layoutComponent(root.layoutName)
    }
}
