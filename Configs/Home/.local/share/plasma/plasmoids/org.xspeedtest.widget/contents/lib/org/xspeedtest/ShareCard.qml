import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property SpeedTestRunner runner
    required property SpeedSettings settings
    property var style: Styles.resolve(settings.style)

    readonly property real shadowMargin: Kirigami.Units.gridUnit
    readonly property real cardPadding: Kirigami.Units.gridUnit * 1.4
    readonly property real cardWidth: shareView.implicitWidth + cardPadding * 2
    readonly property real cardHeight: shareView.implicitHeight + cardPadding * 2

    visible: false
    width: cardWidth + shadowMargin * 2
    height: cardHeight + shadowMargin * 2

    function capture(callback) {
        visible = true;
        Qt.callLater(function () {
            grabToImage(function (result) {
                root.visible = false;
                callback(result.image);
            });
        });
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: root.cardWidth
        height: root.cardHeight
        radius: Math.max(root.style.radius, 10) + 4
        color: Qt.alpha(Kirigami.Theme.backgroundColor, root.settings.glassOpacity)
        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
    }

    MultiEffect {
        anchors.fill: parent
        source: card
        autoPaddingEnabled: true
        shadowEnabled: true
        shadowColor: "#aa000000"
        shadowBlur: 0.8
        shadowVerticalOffset: root.shadowMargin * 0.4
        shadowHorizontalOffset: 0
    }

    SpeedView {
        id: shareView
        anchors.centerIn: card
        width: implicitWidth
        height: implicitHeight
        runner: root.runner
        settings: root.settings
        animate: false
        idleDrift: false
    }
}
