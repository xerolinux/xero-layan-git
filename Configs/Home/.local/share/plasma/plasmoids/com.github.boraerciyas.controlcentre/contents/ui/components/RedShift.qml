import QtQml 2.0
import QtQuick
import QtQuick.Layouts

import org.kde.kcmutils // KCMLauncher
import org.kde.config as KConfig  // KAuthorized.authorizeControlModule
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import org.kde.plasma.private.brightnesscontrolplugin

import "../lib" as Lib
import "../js/funcs.js" as Funcs


Lib.CardButton {
    // NIGHT COLOUR CONTROL
    visible: root.showNightColor
    property var monitor: monitor
    property var inhibitor: inhibitor
    /* Redshift.Monitor {
        id: redMonitor
    }
    Redshift.Inhibitor {
        id: inhibitor
    } */
    Layout.fillWidth: true
    Layout.fillHeight: true
    title: i18n("Night Color")
    Kirigami.Icon {
        anchors.fill: parent
        source: {
            if (!monitor.enabled) {
                    return "redshift-status-on"; // not configured: show generic night light icon rather "manually turned off" icon
                } else if (!monitor.running) {
                    return "redshift-status-off";
                } else if (monitor.daylight && monitor.targetTemperature != 6500) { // show daylight icon only when temperature during the day is actually modified
                    return "redshift-status-day";
                } else {
                    return "redshift-status-on";
                }
        }
    }
    onClicked: toggleInhibition()

    function toggleInhibition() {
        if (!monitor.available) {
            return;
        }
        switch (inhibitor.state) {
        case NightColorInhibitor.Inhibiting:
        case NightColorInhibitor.Inhibited:
            inhibitor.uninhibit();
            break;
        case NightColorInhibitor.Uninhibiting:
        case NightColorInhibitor.Uninhibited:
            inhibitor.inhibit();
            break;
        }
    }

    NightColorInhibitor {
        id: inhibitor
    }

    NightColorMonitor {
        id: monitor

        readonly property bool transitioning: monitor.currentTemperature != monitor.targetTemperature
        readonly property bool hasSwitchingTimes: monitor.mode != 3
    }
}