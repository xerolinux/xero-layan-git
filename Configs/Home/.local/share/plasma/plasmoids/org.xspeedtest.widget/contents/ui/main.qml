import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../lib/org/xspeedtest"

PlasmoidItem {
    id: root

    readonly property bool desktop: Plasmoid.formFactor === PlasmaCore.Types.Planar
    readonly property var style: Styles.resolve(testSettings.style)

    Plasmoid.icon: "xspeedtest"
    Plasmoid.backgroundHints: desktop ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground

    toolTipMainText: "xSpeedTest"
    toolTipSubText: testRunner.busy ? Stream.phaseText(testRunner) + ": " + Stream.readout(testRunner, testRunner.mbps, testSettings) + " " + Stream.unit(testRunner, testSettings)
        : testHistory.count > 0 ? qsTr("Last: %1 down, %2 up, %3 ms").arg(Stream.speed(testHistory.lastDownload, testSettings) + " " + testSettings.unitLabel).arg(Stream.speed(testHistory.lastUpload, testSettings) + " " + testSettings.unitLabel).arg(testHistory.lastPing.toFixed(0))
        : qsTr("Click to run a speed test")

    SpeedSettings {
        id: testSettings
        profile: "plasmoid"
    }

    HistoryModel {
        id: testHistory
    }

    SpeedTestRunner {
        id: testRunner
        history: testHistory
        backend: testSettings.backend
    }

    compactRepresentation: MouseArea {
        id: compact

        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: compact.containsMouse
        }

        Rectangle {
            visible: testRunner.busy
            width: Math.max(6, compact.width * 0.28)
            height: width
            radius: width / 2
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: testRunner.phase === SpeedTestRunner.Uploading ? root.style.up[0] : root.style.down[0]
            border.color: Kirigami.Theme.backgroundColor
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: panel.implicitWidth
        Layout.minimumHeight: panel.implicitHeight
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight
        Layout.maximumWidth: Layout.minimumWidth
        Layout.maximumHeight: Layout.minimumHeight

        Rectangle {
            anchors.fill: parent
            visible: root.desktop
            radius: Math.max(panel.style.radius, 10) + 4
            color: Qt.alpha(Kirigami.Theme.backgroundColor, testSettings.glassOpacity)
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
        }

        SpeedPanel {
            id: panel
            anchors.fill: parent
            padding: Kirigami.Units.gridUnit * (root.desktop ? 1.4 : 0.9)
            compact: !root.desktop
            pagesCompact: true
            pagesMinWidth: Kirigami.Units.gridUnit * (root.desktop ? 24 : 17)
            animate: root.expanded || root.desktop
            idleDrift: false
            runner: testRunner
            settings: testSettings
            history: testHistory
            settingsTitle: qsTr("Widget settings")
        }
    }
}
