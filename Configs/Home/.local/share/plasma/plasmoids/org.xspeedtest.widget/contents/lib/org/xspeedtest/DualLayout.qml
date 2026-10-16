import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property var view

    readonly property real gu: Kirigami.Units.gridUnit

    implicitWidth: gu * 24
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: root.gu * 0.8

        QQC2.Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.view.serverText
            color: root.view.errorState ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: root.gu

            Repeater {
                model: [
                    {label: qsTr("Download"), channel: "down"},
                    {label: qsTr("Upload"), channel: "up"}
                ]

                delegate: ColumnLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: root.gu * 0.4

                    QQC2.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.label.toUpperCase()
                        color: Kirigami.Theme.disabledTextColor
                        font.letterSpacing: 1
                        font.weight: Font.DemiBold
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                    StyleCanvas {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.view.u * 150
                        runner: root.view.runner
                        style: root.view.style
                        channel: modelData.channel
                        animate: root.view.animate
                        idleDrift: root.view.idleDrift
                    }
                    Readout {
                        Layout.alignment: Qt.AlignHCenter
                        view: root.view
                        stacked: true
                        text: modelData.channel === "down" ? root.view.downText : root.view.upText
                        unit: root.view.settings.unitLabel
                        pixelSize: root.gu * 1.9
                    }
                }
            }
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.view.phaseText.toUpperCase()
            color: Kirigami.Theme.disabledTextColor
            font.letterSpacing: 1
            font.weight: Font.DemiBold
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }

        StatChips {
            Layout.fillWidth: true
            view: root.view
            count: 2
        }

        ActionButton {
            view: root.view
        }
    }
}
