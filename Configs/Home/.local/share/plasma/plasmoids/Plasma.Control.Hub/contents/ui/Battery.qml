import QtQuick
import org.kde.plasma.private.battery
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Item {
    width: conteiner.width
    property bool hasBattery: batteryControl.hasBatteries
    property bool batteryChargid: batteryControl.state === BatteryControlModel.Charging
    property int percent: !hasBattery ? 100: batteryControl.percent

    BatteryControlModel {
        id: batteryControl

        readonly property int remainingTime: batteryControl.smoothedRemainingMsec
        readonly property bool isSomehowFullyCharged: batteryControl.pluggedIn && batteryControl.state === BatteryControlModel.FullyCharged
    }

    function determineIcon(value) {
        var icon = "";
        if (value < 10) {
            icon = "battery-000";
        } else if (value < 20) {
            icon = "battery-010";
        } else if (value < 30) {
            icon = "battery-020";
        } else if (value < 40) {
            icon = "battery-030";
        } else if (value < 50) {
            icon = "battery-040";
        } else if (value < 60) {
            icon = "battery-050";
        } else if (value < 70) {
            icon = "battery-060";
        } else if (value < 80) {
            icon = "battery-070";
        } else if (value < 90) {
            icon = "battery-080";
        } else if (value < 100) {
            icon = "battery-090";
        } else {
            icon = "battery-100";
        }

        if (batteryChargid) {
            return icon + "-charging-symbolic"
        } else {
            return icon + "-symbolic"
        }

    }

    Row {
        id: conteiner
        height: parent.height
        width: logo.width + text.implicitWidth
        spacing: 2
        anchors.left: parent.left

        Controls.Label {
            id: text
            width: parent.width - logo.width - 2
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: percent + "%"
            //font.pixelSize: Kirigami.Theme.defaultFont.pointSize
        }
        Kirigami.Icon {
            id: logo
            width: 24
            height: 24
            color: Kirigami.Theme.textColor
            anchors.verticalCenter: parent.verticalCenter
            source: determineIcon(percent)
        }

    }

}

