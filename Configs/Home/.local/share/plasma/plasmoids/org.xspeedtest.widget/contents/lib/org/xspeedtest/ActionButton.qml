import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.Button {
    id: root

    required property var view

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
    highlighted: !view.runner.busy
    text: Stream.buttonText(view.runner)
    onClicked: Stream.toggle(view.runner)
}
