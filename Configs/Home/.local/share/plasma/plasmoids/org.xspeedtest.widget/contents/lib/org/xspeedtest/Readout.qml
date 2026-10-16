import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

GridLayout {
    id: root

    required property var view
    property string text: ""
    property string unit: ""
    property real pixelSize: Kirigami.Units.gridUnit * 2.4
    property bool stacked: false

    columns: stacked ? 1 : 2
    columnSpacing: Kirigami.Units.smallSpacing
    rowSpacing: 0

    QQC2.Label {
        Layout.alignment: root.stacked ? Qt.AlignHCenter : Qt.AlignBaseline
        text: root.text
        font.pixelSize: root.pixelSize
        font.weight: root.view.style.fontWeight
        font.features: {"tnum": 1}
    }
    QQC2.Label {
        Layout.alignment: root.stacked ? Qt.AlignHCenter : Qt.AlignBaseline
        text: root.unit
        color: Kirigami.Theme.disabledTextColor
    }
}
