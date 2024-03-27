import QtQuick
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support


PlasmoidItem {
    id: root
    
    clip: true

    // PROPERTIES
    property bool enableTransparency: Plasmoid.configuration.transparency
    property var animationDuration: Kirigami.Units.veryShortDuration
    property bool playVolumeFeedback: Plasmoid.configuration.playVolumeFeedback

    property var scale: Plasmoid.configuration.scale * 0.01
    property int fullRepWidth: 360 * scale
    property int fullRepHeight: 360 * scale
    property int sectionHeight: 180 * scale

    property int largeSpacing: 12 * scale
    property int mediumSpacing: 8 * scale
    property int smallSpacing: 6 * scale

    property int buttonMargin: 4 * scale
    property int buttonHeight: 48 * scale

    property int largeFontSize: 15 * scale
    property int mediumFontSize: 12 * scale
    property int smallFontSize: 7 * scale
    
    // Main Icon
    property string mainIconName: Plasmoid.configuration.mainIconName
    property string mainIconHeight: Plasmoid.configuration.mainIconHeight
    
    // Components
    property bool showKDEConnect: Plasmoid.configuration.showKDEConnect
    property bool showNightColor: Plasmoid.configuration.showNightColor
    property bool showColorSwitcher: Plasmoid.configuration.showColorSwitcher
    property bool showDnd: Plasmoid.configuration.showDnd
    property bool showVolume: Plasmoid.configuration.showVolume
    property bool showBrightness: Plasmoid.configuration.showBrightness
    property bool showMediaPlayer: Plasmoid.configuration.showMediaPlayer
    property bool showCmd1: Plasmoid.configuration.showCmd1
    property bool showCmd2: Plasmoid.configuration.showCmd2
    property bool showPercentage: Plasmoid.configuration.showPercentage
    
    property string cmdRun1: Plasmoid.configuration.cmdRun1
    property string cmdTitle1: Plasmoid.configuration.cmdTitle1
    property string cmdIcon1: Plasmoid.configuration.cmdIcon1
    property string cmdRun2: Plasmoid.configuration.cmdRun2
    property string cmdTitle2: Plasmoid.configuration.cmdTitle2
    property string cmdIcon2: Plasmoid.configuration.cmdIcon2

    readonly property bool inPanel: (root.location === PlasmaCore.Types.TopEdge
        || root.location === PlasmaCore.Types.RightEdge
        || root.location === PlasmaCore.Types.BottomEdge
        || root.location === PlasmaCore.Types.LeftEdge)

    switchHeight: fullRepHeight
    switchWidth: fullRepWidth
    preferredRepresentation: inPanel ? Plasmoid.compactRepresentation : Plasmoid.fullRepresentation
    fullRepresentation: FullRepresentation {}
    compactRepresentation: CompactRepresentation {}
}
