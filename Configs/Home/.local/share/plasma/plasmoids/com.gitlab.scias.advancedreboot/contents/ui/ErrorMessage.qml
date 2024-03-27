import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Item {
    property bool show: false
    property string sIcon
    property string message
    //property var action: null

    implicitWidth: parent.width
    implicitHeight: err.implicitHeight + Kirigami.Units.largeSpacing * 2

    Layout.maximumWidth: implicitWidth
    Layout.minimumWidth: implicitWidth
    Layout.maximumHeight: implicitHeight
    Layout.minimumHeight: implicitHeight

    Kirigami.PlaceholderMessage {
        id: err
        width: parent.width - Kirigami.Units.largeSpacing * 2
        anchors.horizontalCenter: parent.horizontalCenter
        icon.name: sIcon
        text: message
        visible: show
        //TODO: Configure button - Help link
        //helpfulAction: action
    }
}
