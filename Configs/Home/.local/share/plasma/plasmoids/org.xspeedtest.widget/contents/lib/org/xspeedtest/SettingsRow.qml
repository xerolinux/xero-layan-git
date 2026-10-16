import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: root

    property string label

    Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing

    QQC2.Label {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        text: root.label
    }
}
