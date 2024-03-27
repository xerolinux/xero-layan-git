import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    id: configString
    Layout.fillWidth: true

    property alias value: configString.text

    ToolButton {
        icon.name: "edit-clear"
        onClicked: configString.value = ""

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        width: height
    }
}
