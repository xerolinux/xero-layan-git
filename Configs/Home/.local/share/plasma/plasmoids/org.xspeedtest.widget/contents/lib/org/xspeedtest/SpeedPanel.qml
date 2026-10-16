import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property SpeedTestRunner runner
    required property SpeedSettings settings
    required property HistoryModel history
    property PlasmoidInstaller installer: null
    property bool compact: false
    property bool pagesCompact: compact
    property real pagesMinWidth: pagesCompact ? Kirigami.Units.gridUnit * 17 : Kirigami.Units.gridUnit * 22
    property bool animate: true
    property bool idleDrift: true
    property string page: "main"
    property string settingsTitle: qsTr("Settings")
    property real padding: Kirigami.Units.gridUnit * 1.5
    property real controlsInset: 0

    readonly property var style: view.style
    readonly property bool canCopyResults: page === "main" && runner.phase === SpeedTestRunner.Done

    property int copyState: 0 // 0 idle, 1 copied, 2 failed

    function toggle(name) {
        page = page === name ? "main" : name;
    }

    function copyResults() {
        shareCard.capture(function (image) {
            root.copyState = shareHelper.copyImage(image) ? 1 : 2;
            copyStateTimer.restart();
        });
    }

    ResultShare {
        id: shareHelper
    }

    ShareCard {
        id: shareCard
        runner: root.runner
        settings: root.settings
    }

    Timer {
        id: copyStateTimer
        interval: 2000
        onTriggered: root.copyState = 0
    }

    function pageWidth() {
        if (!pagesCompact)
            return Math.max(view.implicitWidth, settingsPage.implicitWidth, historyPage.implicitWidth);
        switch (page) {
        case "history":
            return historyPage.implicitWidth;
        case "settings":
            return settingsPage.implicitWidth;
        default:
            return view.implicitWidth;
        }
    }

    function pageHeight() {
        if (!pagesCompact)
            return Math.max(view.implicitHeight, settingsPage.implicitHeight, historyPage.implicitHeight);
        switch (page) {
        case "history":
            return historyPage.implicitHeight;
        case "settings":
            return settingsPage.implicitHeight;
        default:
            return view.implicitHeight;
        }
    }

    implicitWidth: pageWidth() + padding * 2
    implicitHeight: header.implicitHeight + column.spacing + pageHeight() + padding * 2

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            id: header
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing - root.padding
            Layout.rightMargin: Kirigami.Units.smallSpacing - root.padding + root.controlsInset
            spacing: 0

            Kirigami.Heading {
                visible: root.page !== "main"
                text: root.page === "history" ? qsTr("Test History") : root.settingsTitle
                level: 2
            }
            Item {
                Layout.fillWidth: true
            }
            QQC2.ToolButton {
                visible: root.canCopyResults
                icon.name: root.copyState === 1 ? "emblem-checked-symbolic" : root.copyState === 2 ? "emblem-error-symbolic" : "edit-copy-symbolic"
                onClicked: root.copyResults()
                QQC2.ToolTip.text: root.copyState === 1 ? qsTr("Copied to clipboard") : root.copyState === 2 ? qsTr("Could not copy the image") : qsTr("Copy result image")
                QQC2.ToolTip.visible: hovered
            }
            QQC2.ToolButton {
                checkable: true
                checked: root.page === "history"
                icon.name: "view-history"
                onClicked: root.toggle("history")
                QQC2.ToolTip.text: qsTr("Test History")
                QQC2.ToolTip.visible: hovered
            }
            QQC2.ToolButton {
                checkable: true
                checked: root.page === "settings"
                icon.name: "configure-symbolic"
                onClicked: root.toggle("settings")
                QQC2.ToolTip.text: qsTr("Settings")
                QQC2.ToolTip.visible: hovered
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: root.pageWidth()
            implicitHeight: root.pageHeight()

            SpeedView {
                id: view
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: implicitHeight
                visible: root.page === "main"
                runner: root.runner
                settings: root.settings
                compact: root.compact
                animate: root.animate && root.page === "main"
                idleDrift: root.idleDrift
            }

            HistoryPage {
                id: historyPage
                anchors.fill: parent
                visible: root.page === "history"
                settings: root.settings
                history: root.history
                compact: root.pagesCompact
                minWidth: root.pagesMinWidth
            }

            SettingsPage {
                id: settingsPage
                anchors.fill: parent
                visible: root.page === "settings"
                settings: root.settings
                installer: root.installer
                showOpacity: !root.compact
                compact: root.pagesCompact
                minWidth: root.pagesMinWidth
            }
        }
    }
}
