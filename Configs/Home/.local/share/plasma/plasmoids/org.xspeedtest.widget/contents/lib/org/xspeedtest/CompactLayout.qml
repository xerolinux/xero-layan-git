import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property var view

    readonly property real gu: Kirigami.Units.gridUnit

    implicitWidth: gu * 19
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: root.gu * 0.7

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

            Readout {
                view: root.view
                text: root.view.readout
                unit: root.view.unit
                pixelSize: root.gu * 2.2
            }
            Item {
                Layout.fillWidth: true
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignBottom
                text: root.view.phaseText.toUpperCase()
                color: Kirigami.Theme.disabledTextColor
                font.letterSpacing: 1
                font.weight: Font.DemiBold
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            }
        }

        StyleCanvas {
            Layout.fillWidth: true
            Layout.preferredHeight: root.view.u * 110
            runner: root.view.runner
            style: root.view.style
            animate: root.view.animate
            idleDrift: root.view.idleDrift
        }

        StatChips {
            Layout.fillWidth: true
            view: root.view
        }

        ActionButton {
            view: root.view
        }

        // Extra bottom slack: Plasma's popup dialog eats some of our declared height on its own
        // edge, clipping the bottom of the card before this was added. The canvas itself never
        // clips its own drawing (verified per-pixel), so this is purely for the dialog's shortfall.
        Item {
            Layout.preferredHeight: Math.max(0, 40 - column.spacing)
        }
    }
}
