import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "components" as Components
//import org.kde.plasma.private.sessions as Sessions


PlasmoidItem {
    id: root


    compactRepresentation: MouseArea {
        id: compactRoot

        // Taken from DigitalClock to ensure uniform sizing when next to each other
        readonly property bool tooSmall: Plasmoid.formFactor === PlasmaCore.Types.Horizontal && Math.round(2 * (compactRoot.height / 5)) <= PlasmaCore.Theme.smallestFont.pixelSize

        Layout.minimumWidth: isVertical ? 0 : compactRow.implicitWidth
        Layout.maximumWidth: isVertical ? Infinity : Layout.minimumWidth
        Layout.preferredWidth: isVertical ? undefined : Layout.minimumWidth

        Layout.minimumHeight: isVertical ? label.height : Kirigami.Theme.smallestFont.pixelSize
        Layout.maximumHeight: isVertical ? Layout.minimumHeight : Infinity
        Layout.preferredHeight: isVertical ? Layout.minimumHeight : Kirigami.Theme.mSize(Kirigami.Theme.defaultFont).height * 2

        property bool wasExpanded
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded

        Row {
            id: compactRow
            layoutDirection: iconPositionRight ? Qt.RightToLeft : Qt.LeftToRight
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing
            Rectangle {
                width: root.height
                height: root.height
                color: "transparent"
                Kirigami.Icon {
                    width: 22
                    height: 22
                    source: "configure"
                    //color: Kirigami.Theme.TextColor
                    anchors.centerIn: parent
                }
            }
        }
    }

    fullRepresentation: FullRepresentation {
    }

}

