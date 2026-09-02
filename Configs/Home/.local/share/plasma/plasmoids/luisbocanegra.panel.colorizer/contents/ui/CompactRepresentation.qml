import QtQuick
import "components" as Components
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3

MouseArea {
    id: compact

    property bool isPanelVertical: plasmoid.formFactor === PlasmaCore.Types.Vertical
    property real itemSize: Math.min(compact.height, compact.width)
    property string icon

    signal widgetClicked

    anchors.fill: parent
    hoverEnabled: true
    onClicked: {
        widgetClicked();
    }

    Item {
        id: container

        height: compact.itemSize
        width: compact.width
        anchors.centerIn: parent

        Components.PlasmoidIcon {
            id: plasmoidIcon

            height: Kirigami.Units.iconSizes.roundedIconSize(Math.min(parent.width, parent.height))
            width: height
            source: compact.icon
        }

        PC3.Label {
            font: Kirigami.Theme.smallFont
            text: main.toolTipSubText
            width: compact.width
            wrapMode: PC3.Label.WordWrap
            visible: main.onDesktop
            textFormat: PC3.Label.RichText
        }
    }
}
