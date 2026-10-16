import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property var view

    readonly property bool rail: view.layoutName === "sidebar"
    readonly property real gu: Kirigami.Units.gridUnit

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: root.gu

        Rectangle {
            visible: root.rail
            Layout.fillHeight: true
            Layout.preferredWidth: 4
            radius: 2
            gradient: Gradient {
                GradientStop { position: 0; color: root.view.style.down[0] }
                GradientStop { position: 1; color: root.view.style.down[1] }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: root.gu * (root.rail ? 21 : 24)
            spacing: root.gu * 0.7

            QQC2.Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.view.serverText
                color: root.view.errorState ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.disabledTextColor
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.view.phaseText.toUpperCase()
                color: Kirigami.Theme.disabledTextColor
                font.letterSpacing: 1
                font.weight: Font.DemiBold
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            }

            StyleCanvas {
                Layout.fillWidth: true
                Layout.preferredHeight: root.view.u * (root.rail ? 190 : 200)
                runner: root.view.runner
                style: root.view.style
                animate: root.view.animate
                idleDrift: root.view.idleDrift

                Readout {
                    anchors.centerIn: parent
                    visible: root.view.overlay
                    view: root.view
                    stacked: true
                    text: root.view.readout
                    unit: root.view.unit
                    pixelSize: root.gu * 2.1
                }
            }

            Readout {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.view.overlay
                view: root.view
                text: root.view.readout
                unit: root.view.unit
                pixelSize: root.gu * 2.6
            }

            StatChips {
                Layout.fillWidth: true
                view: root.view
            }

            ActionButton {
                view: root.view
            }
        }
    }
}
