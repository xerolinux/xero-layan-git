import QtQuick 2.12
import QtQuick.Layouts 1.1
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property int anchoDeSepardor: isVertical ? (width < 40) ? 1 : (width < 60) ? 1.5 : 2 : (height < 40) ? 1 : (height < 60) ? 1.5 : 2

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground
    preferredRepresentation: fullRepresentation


          fullRepresentation: RowLayout {
             id: base
             Layout.minimumWidth: isVertical ? root.width : anchoDeSepardor
             Row {
                height: isVertical ? anchoDeSepardor : root.height
                width: isVertical ? root.width : anchoDeSepardor
                anchors.centerIn: parent

             Row {
                   id: separator
                   height: isVertical ? anchoDeSepardor : root.height
                   width: isVertical ? root.height : anchoDeSepardor
                   anchors.centerIn: parent
                   Rectangle {
                     width: isVertical ? root.width*.9 : anchoDeSepardor
                     height: isVertical ? anchoDeSepardor : root.height*.9
                     color: Kirigami.Theme.textColor
                     opacity: 0.4
                     anchors.centerIn: parent
                  }

                 }

              }

}
          }
