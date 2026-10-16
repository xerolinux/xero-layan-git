import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

GridLayout {
    id: root

    required property var view
    property int count: 4
    property bool rows: false

    columns: rows ? 1 : Math.min(count, view.chipColumns)
    columnSpacing: Kirigami.Units.smallSpacing
    rowSpacing: Kirigami.Units.smallSpacing

    Repeater {
        model: root.count

        delegate: Rectangle {
            required property int index

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: root.rows ? Kirigami.Units.gridUnit * 1.9 : Kirigami.Units.gridUnit * 2.8
            radius: root.view.style.radius * 0.5
            color: Qt.alpha(Kirigami.Theme.textColor, 0.08)

            GridLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                columns: root.rows ? 2 : 1
                rowSpacing: 0

                QQC2.Label {
                    Layout.fillWidth: root.rows
                    Layout.alignment: root.rows ? Qt.AlignVCenter : (Qt.AlignHCenter | Qt.AlignBottom)
                    text: root.view.chipLabels[index].toUpperCase()
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.letterSpacing: 1
                }
                QQC2.Label {
                    Layout.alignment: root.rows ? Qt.AlignVCenter : (Qt.AlignHCenter | Qt.AlignTop)
                    text: root.view.chipValue(index)
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
