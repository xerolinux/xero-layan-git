pragma Singleton
import QtQuick

QtObject {
    function format(value) {
        return value.toLocaleString(Qt.locale(), "f", value >= 100 ? 0 : 1);
    }

    function speed(mbps, settings) {
        return format(settings.convert(mbps));
    }

    function readout(runner, mbps, settings) {
        switch (runner.phase) {
        case SpeedTestRunner.Searching:
            return runner.ping > 0 ? runner.ping.toFixed(0) : "...";
        case SpeedTestRunner.Downloading:
        case SpeedTestRunner.Uploading:
            return speed(mbps, settings);
        case SpeedTestRunner.Done:
            return speed(runner.download, settings);
        case SpeedTestRunner.Error:
            return "--";
        default:
            return "0";
        }
    }

    function unit(runner, settings) {
        return runner.phase === SpeedTestRunner.Searching ? "ms" : settings.unitLabel;
    }

    function phaseText(runner) {
        switch (runner.phase) {
        case SpeedTestRunner.Searching:
            return qsTr("Finding best server");
        case SpeedTestRunner.Downloading:
            return qsTr("Testing download");
        case SpeedTestRunner.Uploading:
            return qsTr("Testing upload");
        case SpeedTestRunner.Done:
            return qsTr("Test complete");
        case SpeedTestRunner.Error:
            return qsTr("Test failed");
        default:
            return qsTr("Ready");
        }
    }

    function buttonText(runner) {
        if (runner.busy)
            return qsTr("Cancel");
        switch (runner.phase) {
        case SpeedTestRunner.Idle:
            return qsTr("Start test");
        case SpeedTestRunner.Error:
            return qsTr("Retry");
        default:
            return qsTr("Test again");
        }
    }

    function toggle(runner) {
        if (runner.busy)
            runner.cancel();
        else
            runner.start();
    }
}
