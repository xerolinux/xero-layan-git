import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property var view

    readonly property real gu: Kirigami.Units.gridUnit

    implicitWidth: gu * 24
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: root.gu

        StyleCanvas {
            Layout.preferredWidth: root.gu * 10
            Layout.preferredHeight: root.view.u * 172
            Layout.alignment: Qt.AlignVCenter
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
                pixelSize: root.gu * 1.9
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.gu * 0.7

            QQC2.Label {
                text: root.view.phaseText.toUpperCase()
                color: Kirigami.Theme.disabledTextColor
                font.letterSpacing: 1
                font.weight: Font.DemiBold
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            }
            Readout {
                visible: !root.view.overlay
                view: root.view
                text: root.view.readout
                unit: root.view.unit
                pixelSize: root.gu * 2.3
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                elide: Text.ElideRight
                text: root.view.serverText
                color: root.view.errorState ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.disabledTextColor
            }
            StatChips {
                Layout.fillWidth: true
                view: root.view
                rows: true
            }
            ActionButton {
                view: root.view
            }
        }
    }
}
