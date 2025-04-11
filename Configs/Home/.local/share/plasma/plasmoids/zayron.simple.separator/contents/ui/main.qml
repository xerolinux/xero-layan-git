import QtQuick
import QtQuick.Layouts 1.2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property int anchoDeSepardor: isVertical ? (width < 40) ? thickness : (width < 60) ? thickness*1.5 : thickness*2 : (height < 40) ? thickness : (height < 60) ? thickness*1.5 : thickness*2
    property int margins: Plasmoid.configuration.lengthMargin
    property bool customColorCheck: Plasmoid.configuration.checkColorCustom
    property string customColor: Plasmoid.configuration.customColors
    property int lengthPorcent: Plasmoid.configuration.lengthSeparator
    property int thickness: Plasmoid.configuration.thicknessSeparator
    property bool pointDesing: Plasmoid.configuration.pointDesing

    preferredRepresentation: fullRepresentation

    fullRepresentation: RowLayout {
       id: base
       Layout.minimumWidth: isVertical ? root.width : anchoDeSepardor + margins
       Layout.maximumHeight: isVertical ? anchoDeSepardor + margins : root.height

       Row {
          height: separator.height
          width: separator.width
          anchors.centerIn: parent

          Row {
             id: separator
             height: isVertical ? anchoDeSepardor + margins : root.height
             width: isVertical ? root.height : anchoDeSepardor + margins
             anchors.centerIn: parent

             Rectangle {
                width: pointDesing ? root.width/100*lengthPorcent : isVertical ? root.width/100*lengthPorcent : anchoDeSepardor
                height: pointDesing ? root.width/100*lengthPorcent : isVertical ? anchoDeSepardor : root.height/100*lengthPorcent
                color: customColorCheck ? customColor: Kirigami.Theme.textColor
                opacity: Plasmoid.configuration.opacity/100
                anchors.centerIn: parent
                radius: pointDesing ? height/2 : 0
             }
          }
       }
    }
}
