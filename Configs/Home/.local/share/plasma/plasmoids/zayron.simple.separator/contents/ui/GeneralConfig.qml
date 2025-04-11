import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import Qt.labs.platform

Item {
    id: configRoot

    property alias cfg_checkColorCustom: checkColorCustom.checked
    property alias cfg_lengthMargin: lengthMargin.value
    property alias cfg_opacity: porcetageOpacity.value
    property alias cfg_lengthSeparator: lengthSeparator.value
    property alias cfg_thicknessSeparator: thickness.value
    property alias cfg_customColors: colorDialog.color
    property alias cfg_pointDesing: checkPoinDesing.checked

    ColorDialog {
        id: colorDialog
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: units.largeSpacing
        Layout.fillWidth: true

        GridLayout{
            columns: 2

            Label {
                Layout.minimumWidth: configRoot.width/2
                text: i18n("replace linear design with point:")
                horizontalAlignment: Text.AlignRight
            }

            CheckBox {
                id: checkPoinDesing
            }
            Label {
                Layout.minimumWidth: configRoot.width/2
                text: i18n("Margin length:")
                horizontalAlignment: Text.AlignRight
            }

            SpinBox{
                id: lengthMargin

                from: 5
                to: 100
                stepSize: 5
                // suffix: " " + i18nc("pixels","px.")
            }

            Label {
                Layout.minimumWidth: configRoot.width/2
                text: i18n("separator length percentage:")
                horizontalAlignment: Text.AlignRight
            }

            SpinBox{
                id: lengthSeparator

                from: 10
                to: 100
                stepSize: 10
                // suffix: " " + i18nc("pixels","px.")
            }
            Label {
                Layout.minimumWidth: configRoot.width/2
                text: i18n("thickness:")
                horizontalAlignment: Text.AlignRight
                visible: !checkPoinDesing.checked
            }
            SpinBox{
                id: thickness

                from: 1
                to: 4
                stepSize: 1
                // suffix: " " + i18nc("pixels","px.")
                visible: !checkPoinDesing.checked
            }
            Label {
                Layout.minimumWidth: configRoot.width/2
                text: i18n("Custom RGB Color:")
                horizontalAlignment: Text.AlignRight
            }
            CheckBox {
                id: checkColorCustom
            }
            Label {

            }

            Item {
                width: 64
                height: 24
                opacity: checkColorCustom.checked ? 1.0 : 0.2
                Rectangle {
                    width: 64
                    radius: 4
                    height: 24
                    border.color: "black"
                    opacity: 0.5
                    color: "transparent"
                    border.width: 2
                }
                Rectangle {
                    color: colorDialog.color
                    border.color: "#B3FFFFFF"
                    border.width: 1
                    width: 64
                    radius: 4
                    height: 24
                    MouseArea {
                        anchors.fill: parent
                        enabled: checkColorCustom.checked
                        onClicked: {
                            colorDialog.open()
                        }
                    }
                }
            }
            Label {
                Layout.minimumWidth: configRoot.width/2
                text: i18n("Opacity:")
                horizontalAlignment: Text.AlignRight
            }

            SpinBox{
                id: porcetageOpacity

                from: 30
                to: 100
                stepSize: 5
                // suffix: " " + i18nc("pixels","px.")
            }
        }

    }

}
