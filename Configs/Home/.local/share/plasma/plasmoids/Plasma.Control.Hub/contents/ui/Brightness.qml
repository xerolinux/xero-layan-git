import org.kde.plasma.private.brightnesscontrolplugin
import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels

Item {

    property bool active: systemBrightnessControl.isBrightnessAvailable

    ScreenBrightnessControl {
        id: systemBrightnessControl
        isSilent: false
    }
    Connections {
        id: displayModelConnections
        target: systemBrightnessControl.displays
        property var screenBrightnessInfo: []

        function update() {
            const [labelRole, brightnessRole, maxBrightnessRole, displayNameRole] = ["label", "brightness", "maxBrightness", "displayName"].map(
                (roleName) => target.KItemModels.KRoleNames.role(roleName));

            screenBrightnessInfo = [...Array(target.rowCount()).keys()].map((i) => { // for each display index
                const modelIndex = target.index(i, 0);
                return {
                    displayName: target.data(modelIndex, displayNameRole),
                    label: target.data(modelIndex, labelRole),
                    brightness: target.data(modelIndex, brightnessRole),
                    maxBrightness: target.data(modelIndex, maxBrightnessRole),
                };
            });
            brightnessControl.mainScreen = screenBrightnessInfo[0];
        }
        function onDataChanged() { update(); }
        function onModelReset() { update(); }
        function onRowsInserted() { update(); }
        function onRowsMoved() { update(); }
        function onRowsRemoved() { update(); }
    }

    property var mainScreen: displayModelConnections.screenBrightnessInfo[0]
    property bool disableBrightnessUpdate: true
    readonly property int brightnessMin: (mainScreen.maxBrightness > 100 ? 1 : 0)

    Kirigami.Heading {
        id: name
        text: i18n("Brightness")
        font.weight: Font.DemiBold
        level: 4
        anchors.left: slider.left
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.gridUnit /2
    }

    Slider {
        id: slider
        width: parent.width - Kirigami.Units.gridUnit
        height: 24
        //anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: ((parent.height - height)/2) + name.implicitHeight/2
        from: 0
        to: mainScreen.maxBrightness
        value: mainScreen.brightness
        snapMode: Slider.SnapAlways
        onMoved: {
            systemBrightnessControl.setBrightness(mainScreen.displayName, Math.max(brightnessMin, Math.min(mainScreen.maxBrightness, value))) ;
        }
    }

    Connections {
        target: systemBrightnessControl
    }
}
