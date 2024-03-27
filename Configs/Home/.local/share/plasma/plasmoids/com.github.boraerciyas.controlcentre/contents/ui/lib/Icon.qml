import QtQuick 2.0
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami as Kirigami

Item
{
    property alias sourceColor:rect.color
    property alias source: icon.source

    Rectangle {
        id: rect
        radius: width/2
        color: Kirigami.Theme.highlightColor
        anchors.fill: parent
        

        Kirigami.Icon {
            id: icon
            anchors.fill: parent
            anchors.margins: root.smallSpacing
            anchors.centerIn: parent
        }
    }
}
