import QtQuick
import QtQuick.Controls
import QtCore
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.brightnesscontrolplugin
import "js/funcs.js" as Funcs
import "lib" as Lib
import org.kde.plasma.private.sessions as Sessions
import "components" as Components
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.plasmoid
import org.kde.bluezqt 1.0 as BluezQt
import org.kde.kcmutils // KCMLauncher
import org.kde.plasma.networkmanagement as PlasmaNM


Item {
    id: menu

    property QtObject btManager : BluezQt.Manager

    property var network: network

    property color iconsSettingsColor:  {
        var color = Kirigami.Theme.highlightColor;
        const luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;

        if (luminance < 0.6) {
            return "white"; // Use white if the color is dark
        } else {
            return "black"
        }
    }

    property var monitor: monitor
    property var inhibitor: inhibitor


    UserInfo {
        id: userInfo
    }

    SourceMultimedia {
        id: multimedia
    }

    // NOTIFICATION MANAGER
    property var notificationSettings: notificationSettings

    NotificationManager.Settings {
        id: notificationSettings
    }

    //SvgColorMonochrome {
    //  id: svgColor
    //}

    Sessions.SessionManagement {
        id: sm
    }

    Settings {
        id: plasmaHubNightLightControl
        category: "NightLightControl"
        // property var files: []
    }

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    property string iconNotifications: "notifications"

    property bool infoUserAvailable: Plasmoid.configuration.userAndAvaAveilable

    // brightnesscontrolplugin
    readonly property int brightnessMax: sbControl.brightnessMax
    readonly property int brightnessMin: (brightnessMax > 100 ? 1 : 0)

    property bool nightLight: plasmaHubNightLightControl.value("toggleInhibition") !== undefined ? typeof plasmaHubNightLightControl.value("toggleInhibition") !== "boolean" ? plasmaHubNightLightControl.value("toggleInhibition") === "true" ? true : (false) : plasmaHubNightLightControl.value("toggleInhibition") : false


    // Lists all available network connections
    Components.SectionNetworks{
        id: sectionNetworks
    }
    Components.Network {
        id: network
    }

    property bool xpan: root.expanded
    onXpanChanged: {
        weatherInfo.resetFullRep = true
    }

    property int heightCard: Kirigami.Units.gridUnit * 4
    property int marginSeperator: 10


    Layout.preferredWidth: Kirigami.Units.gridUnit * 18
    Layout.preferredHeight: wrapper.implicitHeight + marginSeperator
    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.maximumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: Layout.preferredHeight
    Layout.maximumHeight: Layout.preferredHeight
    clip: true
    // Lists all available network connections

    Component.onCompleted: {
        console.log(nightLight, "pruebas de asignacio de luz nocturna", control.running )
        if (!control.running && !nightLight) {
            control.toggleInhibition()
        }
    }

    Column {
        id: wrapper
        anchors.verticalCenter: parent.verticalCenter
        width: menu.width - marginSeperator *2
        height: menu.height - marginSeperator*2
        anchors.left: parent.left
        anchors.leftMargin: marginSeperator
        anchors.top: parent.top
        anchors.topMargin: marginSeperator
        Row {
            id: username
            width: parent.width
            height: (Kirigami.Units.gridUnit * 1.5) + marginSeperator
            spacing: 10
            visible: infoUserAvailable
            Lib.Card {
                id: backgroundNameInfo // seccion de botones de red, bluetooth y config
                //anchors.right: parent.right
                anchors.left: parent.left
                width: parent.width - 10 - batteryAndShutdown.width
                height: Kirigami.Units.gridUnit * 1.5
                Rectangle {
                    id: maskavatar
                    height: parent.height*.75
                    width: height
                    radius: height/2
                    visible: false
                }
                Image {
                    id: avatar
                    source: userInfo.urlAvatar
                    height: parent.height*.75
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: height/2
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: maskavatar
                    }
                }

                Kirigami.Heading {
                    height: parent.height
                    anchors.left: parent.left
                    anchors.leftMargin: avatar.height*2
                    verticalAlignment: Text.AlignVCenter
                    font.weight: Font.DemiBold
                    text: userInfo.name
                    level: 5
                }


            }
            Lib.Card {
                id: batteryAndShutdown
                width: battery.hasBattery ? (battery.width + 12) < ((parent.width *0.10) + 12 ) ? parent.width *0.20 + 17 : battery.width + 10 + parent.width *0.10 : parent.width *0.10
                height: Kirigami.Units.gridUnit * 1.5
                anchors.right: parent.right
                Battery {
                    id: battery
                    height: parent.height
                    anchors.left: parent.left
                    anchors.leftMargin: 5
                    visible: hasBattery
                    //width: implicitWidth
                }

                Row {
                    width: 2
                    height: parent.height
                    anchors.left: battery.right
                    anchors.leftMargin: 5
                    visible: battery.hasBattery
                    Rectangle {
                        color: "white"
                        width: 1
                        height: parent.height
                        opacity: 0.1
                    }
                    Rectangle {
                        color: "black"
                        width: 1
                        height: parent.height
                        opacity: 0.1
                    }
                }

                Kirigami.Icon {
                    source: "system-shutdown.svg"
                    width: 24
                    height: width
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: battery.hasBattery ? battery.width +  (parent.width - battery.width + 7)/2 - width/2 : (
                    parent.width - width)/2
                    MouseArea {
                        height: parent.height
                        width: parent.width
                        anchors.centerIn: parent
                        onClicked: {
                            sm.requestLogoutPrompt()
                        }
                    }
                }

            }
        }
        Row {
            id: utilities // Primera mitad el widget
            width: parent.width
            height: heightCard * 2 + marginSeperator*2
            spacing: marginSeperator

            Column {
                width: parent.width/2
                height: heightCard * 2 + marginSeperator


                Lib.Card {
                    id: backgrounNetBlueSettings // seccion de botones de red, bluetooth y config

                    anchors.right: parent.right
                    anchors.left: parent.left
                    width: parent.width - marginSeperator
                    height: heightCard * 2 + marginSeperator
                    Column {
                        width: parent.width
                        height: parent.height

                        Item {
                            id: networkItem
                            width: parent.width
                            height:  parent.height/3
                            Row {
                                width: parent.width*.3
                                height: parent.height
                                Rectangle {
                                    id: bubbleButtonNet
                                    color: Kirigami.Theme.highlightColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.height*.6
                                    height: width
                                    radius: height/2
                                    Kirigami.Icon {
                                        //isMask: true
                                        implicitWidth: parent.width*.8
                                        color: iconsSettingsColor
                                        anchors.centerIn: parent
                                        source: network.activeConnectionIcon
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            sectionNetworks.toggleNetworkSection()
                                        }
                                    }
                                }
                            }
                            Item {
                                width: parent.width*.7
                                height: parent.height
                                anchors.right: parent.right
                                Kirigami.Heading {
                                    id: nameNetwork
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width*.9
                                    text: i18n("Network")
                                    //font.pixelSize: networkItem.height*.22
                                    font.weight: Font.DemiBold
                                    level: 5
                                }

                            }
                        }
                        Item {
                            id: bluetooth
                            width: parent.width
                            height: parent.height/3
                            Row {
                                width: parent.width*.3
                                height: parent.height
                                Rectangle {
                                    id: bubbleButtonBlue
                                    color: Kirigami.Theme.highlightColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.height*.6
                                    height: width
                                    radius: height/2
                                    Kirigami.Icon {
                                        id: bluetoothIcon
                                        implicitWidth: parent.width*.8// Kirigami.Units.iconSizes.medium
                                        color: iconsSettingsColor
                                        //isMask: true
                                        anchors.centerIn: parent
                                        source: Funcs.getBtDevice() === i18n("Disabled") || Funcs.getBtDevice() === i18n("Unavailable")  ? "network-bluetooth-inactive-symbolic" : Funcs.getBtDevice() === i18n("Not Connected") ? "network-bluetooth-symbolic" : Funcs.getBtDevice() === i18n("Offline") ? "network-bluetooth-inactive-symbolic" : "network-bluetooth-activated" //Funcs.getBtDevice() === "Unavailable" ? "network-bluetooth-inactive-symbolic" : "network-bluetooth-activated-symbolic" : "network-bluetooth"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            Funcs.toggleBluetooth()
                                        }
                                    }
                                }
                            }
                            Item {
                                width: parent.width*.7
                                height: parent.height
                                anchors.right: parent.right
                                Column {
                                    width: parent.width
                                    height: nameBluetooth.height+subNameBluetooth.height
                                    anchors.verticalCenter: parent.verticalCenter
                                    Kirigami.Heading {
                                        id: nameBluetooth
                                        width: parent.width*.9
                                        text: i18n("Bluetooth")
                                        //font.pixelSize: bluetooth.height*.22
                                        font.weight: Font.DemiBold
                                        level: 5
                                    }
                                    PlasmaComponents3.Label {
                                        id: subNameBluetooth
                                        width: parent.width*.9
                                        font.pixelSize: nameBluetooth.font.pixelSize*.8
                                        text: Funcs.getBtDevice()
                                    }
                                }
                            }
                        }

                        Item {
                            id: settings
                            width: parent.width

                            height: parent.height/3
                            Row {
                                width: parent.width*.3
                                height: parent.height
                                Rectangle {
                                    id: bubbleButtonSettings
                                    color: Kirigami.Theme.highlightColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.height*.6
                                    height: width
                                    radius: height/2

                                    Kirigami.Icon {
                                        id: settingsIcon
                                        implicitWidth: parent.width*.8
                                        color: iconsSettingsColor
                                        anchors.centerIn: parent
                                        source: "configure"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            KCMLauncher.openSystemSettings("")
                                        }
                                    }
                                }

                            }
                            Item {
                                width: parent.width*.7
                                height: parent.height
                                anchors.right: parent.right
                                Column {
                                    width: parent.width
                                    height: nameSettigns.height+subNameSettigns.height
                                    anchors.verticalCenter: parent.verticalCenter

                                    Kirigami.Heading {
                                        id: nameSettigns
                                        width: parent.width*.9
                                        text: i18n("Settings")
                                        //font.pixelSize: bluetooth.height*.22
                                        font.weight: Font.DemiBold
                                        level: 5
                                    }
                                    PlasmaComponents3.Label {
                                        id: subNameSettigns
                                        width: parent.width*.9
                                        text: i18n("System Settings")
                                        elide: Text.ElideRight
                                        font.pixelSize: nameSettigns.font.pixelSize*.8
                                    }
                                }
                            }
                        }
                    }
                }

            }
            Column {
                width:  parent.width/2 - marginSeperator
                height: heightCard * 2 + marginSeperator*2

                Column {
                    id: minimalweatherAndToggles
                    width: parent.width
                    height: (heightCard) + marginSeperator

                    Lib.Card {
                        anchors.right: parent.right
                        anchors.left: parent.left
                        width: parent.width
                        height: heightCard

                        Item {
                            id: volumeText
                            width: parent.width
                            height: vl.implicitHeight
                            anchors.left: parent.left
                            anchors.leftMargin: (parent.width - ((parent.width - 37) *.9) - 32)/2
                            anchors.top: parent.top
                            anchors.topMargin: Kirigami.Units.gridUnit /2
                            Kirigami.Heading  {
                                id: vl
                                text: i18n("Volume")
                                font.weight: Font.DemiBold
                                level: 5
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        VolumeSlider {
                            id: volumeSlider
                            width: parent.width
                            height: 32
                            anchors.top: volumeText.bottom
                            //anchors.topMargin: 5

                        }

                    }

                }
                Row {
                    width: parent.width - marginSeperator/2
                    height: heightCard + marginSeperator
                    spacing: marginSeperator
                    visible: minimalweatherAndToggles.visible
                    Item {
                        id: itemredshitbutton
                        width: weatherToggle.visible ? (parent.width/2) - 2.5 : parent.width
                        height: parent.height
                        visible: true
                        Lib.Card {
                            anchors.right: parent.right
                            anchors.left: parent.left
                            width: parent.width
                            height: heightCard

                            Column {
                                width: parent.width
                                height: parent.height
                                Item {
                                    width: parent.width
                                    height: parent.height*.6
                                    Kirigami.Icon {
                                        id: iconOfRedshift
                                        implicitHeight: parent.height*.9

                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        source: nightLight ? "redshift-status-on" : "redshift-status-off"
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                control.toggleInhibition()
                                                plasmaHubNightLightControl.setValue("toggleInhibition", !nightLight)
                                                nightLight = plasmaHubNightLightControl.value("toggleInhibition") !== undefined ? typeof plasmaHubNightLightControl.value("toggleInhibition") !== "boolean" ? plasmaHubNightLightControl.value("toggleInhibition") === "true" ? true : (false) : plasmaHubNightLightControl.value("toggleInhibition") : false
                                            }
                                        }
                                    }
                                }
                                Item {
                                    id: labelredfish
                                    width: parent.width
                                    height: parent.height*.4
                                    Kirigami.Heading {
                                        id: textOfNightLight
                                        width: parent.width
                                        text: nightLight ? "On" : "Off"
                                        //font.pixelSize: labelredfish.height*.35
                                        level: 5
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }



                            }
                        }
                        NightLightControl {
                            id: control

                            readonly property bool transitioning: control.currentTemperature != control.targetTemperature
                            readonly property bool hasSwitchingTimes: control.mode != 3
                            readonly property bool togglable: nightLight || !control.inhibited || control.inhibitedFromApplet

                        }
                    }
                    Item {
                        id: weatherToggle
                        width: itemredshitbutton.visible ? (parent.width/2) -2.5 : (parent.width) -2.5
                        height: heightCard
                        visible: minimalweatherAndToggles.visible
                        Lib.Card {
                            //magePath: "opaque/dialogs/background"
                            //clip: true
                            anchors.right: parent.right
                            anchors.left: parent.left
                            width: parent.width
                            height: parent.height
                            Column {
                                width: parent.width
                                height: parent.height

                                Item {
                                    width: parent.width
                                    height: parent.height*.6
                                    Kirigami.Icon {
                                        implicitHeight: parent.height*.9
                                        color: Kirigami.Theme.TextColor
                                        source: Funcs.checkInhibition() ? "notifications-disabled" : "notifications"
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: Funcs.toggleDnd();
                                        }
                                    }
                                }
                                Item {
                                    id: boxDontDisturb
                                    width: parent.width
                                    height: parent.height*.4

                                    Kirigami.Heading {
                                        id: textdontDis
                                        text: i18n("DND")
                                        width: parent.width
                                        level: 5
                                        //font.pixelSize: weatherToggle.height < weatherToggle.width ? weatherToggle.height*.15 : weatherToggle.width*.15
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter

                                        //font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } // fin Primera mitad el widget
        //****************************************************//

        Item {
            id: brillo
            width: parent.width
            height: heightCard *.9
            visible: brightness.active
            Lib.Card {
                anchors.right: parent.right
                anchors.left: parent.left
                width: parent.width
                height: parent.height - marginSeperator

                Brightness {
                    id: brightness
                    width: parent.width
                    height: parent.height
                }

            }
        }

        Item {
            id: weatherCard
            width: parent.width
            height: heightCard + marginSeperator //brillo.visible ? (infoUserAvailable ? wrapper.height*.9 : wrapper.height)*.2 : (infoUserAvailable ? wrapper.height*.9 : wrapper.height)*.25
            visible: weatherInfo.value && Plasmoid.configuration.weatheCardActive
            Lib.Card {
                anchors.right: parent.right
                anchors.left: parent.left
                width: parent.width
                height: parent.height - marginSeperator

                WeatherInfo {
                    id: weatherInfo
                    width: parent.width
                    height: parent.height
                    resetFullRep: true
                }

            }

        }
        Item {
            id: mutimedia
            width: parent.width
            height: heightCard + marginSeperator // brillo.visible ? (infoUserAvailable ? wrapper.height*.9 : wrapper.height)*.2 : (infoUserAvailable ? wrapper.height*.9 : wrapper.height)*.25
            //visible: false
            Lib.Card {
                id: rect

                //imagePath: "opaque/dialogs/background"
                //clip: true
                anchors.right: parent.right
                anchors.left: parent.left
                width: parent.width
                height: heightCard
                Row {
                    id: baseMultimedia
                    width: parent.width
                    height: parent.height
                    Rectangle {
                        id: margin
                        width: 8
                        height: parent.height
                        color: "transparent"
                    }
                    Rectangle {
                        id: maskalbum
                        color: "red"
                        width: height
                        height: mutimedia.height*.65
                        radius: height/8
                        visible: false
                    }
                    Image {
                        id: nocover
                        width: maskalbum.width
                        height: maskalbum.height
                        source: "img/nocover.svg"
                        sourceSize: Qt.size(width, width)
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !multimedia.cover
                        Kirigami.Icon {
                            source: "multimedia-audio-player"
                            width: parent.width *.6
                            height: width
                            anchors.centerIn: parent
                        }
                    }
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: maskalbum.width
                        height: maskalbum.height
                        source: multimedia.cover
                        visible: !multimedia.cover ? false : true
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: maskalbum
                        }
                    }
                    Rectangle {
                        id: margin2
                        width: 8
                        height: parent.height
                        color: "transparent"
                    }
                    Rectangle {
                        id: contenedorInfoMusic
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - maskalbum.width - margin.width*3 - controlsMultimedia.width
                        height: artist2.text.length > 1 ? title2.height + artist2.height : title2.height
                        color: "transparent"
                        Column {
                            width: parent.width
                            height: parent.height
                            PlasmaComponents3.Label {
                                id: title2
                                width: (contenedorInfoMusic.width - controlsMultimedia.width)
                                text: mpris2Model.currentPlayer?.track
                                font.pixelSize: mutimedia.height*.15
                                font.weight: Font.DemiBold
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                maximumLineCount: 2
                            }
                            PlasmaComponents3.Label {
                                width: (contenedorInfoMusic.width - controlsMultimedia.width)
                                id: artist2
                                text: mpris2Model.currentPlayer?.artist ?? ""
                                font.pixelSize: mutimedia.height*.14
                                elide: Text.ElideRight
                                visible: artist2.text.length > 1 ? true : false
                                opacity: .80
                            }
                        }

                    }
                    Row {
                        id: controlsMultimedia
                        width: 46
                        height: 22
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        Kirigami.Icon {
                            id: iconplay
                            width: 22
                            height: width
                            source: (mpris2Model.currentPlayer?.playbackStatus ?? 0) === Mpris.PlaybackStatus.Playing ? "media-playback-pause" : "media-playback-start"
                            roundToIconSize: false
                            MouseArea {
                                anchors.fill: parent
                                onClicked: multimedia.playPause()
                            }
                        }
                        Kirigami.Icon {
                            id: nextplay
                            width: 22
                            height: width
                            source: "media-skip-forward"
                            roundToIconSize: false
                            MouseArea {
                                anchors.fill: parent
                                onClicked: multimedia.nextTrack()
                            }
                        }
                    }
                }
            }
        }
    }
}
