import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.mediacontroller 1.0
import org.kde.plasma.private.mpris as Mpris
import org.kde.kirigami as Kirigami

import "../lib" as Lib

Lib.Card {
    id: mediaPlayer
    visible: root.showMediaPlayer
    Layout.fillWidth: true
    Layout.preferredHeight: root.sectionHeight / 2
    
    /* Plasma5Support.DataSource {
        id: musicSource
        engine: "mpris2"
        
        onDataChanged: {
            connectedSources = ["@multiplex"]
            var audioData = data["@multiplex"]
            var playing = audioData["PlaybackStatus"] === "Playing"
            
            
            // show if and only if the audio source exists and the audio is currently playing
            if (audioData && playing) {
                
                var audioMetadata = audioData["Metadata"]
                var title = audioMetadata["xesam:title"]
                var artist = audioMetadata["xesam:artist"]
                var thumb = audioMetadata["mpris:artUrl"]   
                
                audioTitle.text = title ? title : i18n("Unknown Media")
                audioThumb.source = thumb ? thumb : "../../assets/music.png"
                
                audioArtist.visible = true
                audioThumb.visible = true
                audioControls.visible = true
                audioTitle.horizontalAlignment = Qt.AlignLeft
                playIcon.source = "media-playback-pause"
                try {
                    audioArtist.text = artist.join(", ")
                } catch(err) {
                    audioArtist.text = artist ? artist : i18n("Unknown Artist")
                } 
            } else {
                playIcon.source = "media-playback-start"
            }
        }
        onSourcesChanged: {
            dataChanged()
        }
        onSourceRemoved: {
            audioArtist.visible = false
            audioThumb.visible = false
            audioControls.visible = false
            audioTitle.horizontalAlignment = Qt.AlignHCenter
            audioTitle.text = i18n("No Media Playing")
            dataChanged()
        }
        Component.onCompleted: {
            audioArtist.visible = false
            audioThumb.visible = false
            audioControls.visible = false
            audioTitle.horizontalAlignment = Qt.AlignHCenter
            audioTitle.text = i18n("No Media Playing")
            dataChanged()
        }
    }

    function action(src, op) {
        var service = musicSource.serviceForSource(src);
        var operation = service.operationDescription(op);
        return service.startOperationCall(operation);
    } */


    readonly property int volumePercentStep: config.volumeStep

    // BEGIN model properties
    readonly property string track: mpris2Model.currentPlayer?.track ?? ""
    readonly property string artist: mpris2Model.currentPlayer?.artist ?? ""
    readonly property string album: mpris2Model.currentPlayer?.album ?? ""
    readonly property string albumArt: mpris2Model.currentPlayer?.artUrl ?? ""
    readonly property string identity: mpris2Model.currentPlayer?.identity ?? ""
    readonly property bool canControl: mpris2Model.currentPlayer?.canControl ?? false
    readonly property bool canGoPrevious: mpris2Model.currentPlayer?.canGoPrevious ?? false
    readonly property bool canGoNext: mpris2Model.currentPlayer?.canGoNext ?? false
    readonly property bool canPlay: mpris2Model.currentPlayer?.canPlay ?? false
    readonly property bool canPause: mpris2Model.currentPlayer?.canPause ?? false
    readonly property bool canStop: mpris2Model.currentPlayer?.canStop ?? false
    readonly property int playbackStatus: mpris2Model.currentPlayer?.playbackStatus ?? 0
    readonly property bool isPlaying: mediaPlayer.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool canRaise: mpris2Model.currentPlayer?.canRaise ?? false
    readonly property bool canQuit: mpris2Model.currentPlayer?.canQuit ?? false
    readonly property int shuffle: mpris2Model.currentPlayer?.shuffle ?? 0
    readonly property int loopStatus: mpris2Model.currentPlayer?.loopStatus ?? 0
    // END model properties

    GlobalConfig {
        id: config
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.largeSpacing

        Image {
            id: audioThumb
            fillMode: Image.PreserveAspectCrop
            Layout.fillHeight: true
            Layout.preferredWidth: height
            // visible: isPlaying
            source: {
                return albumArt ? albumArt : "../../assets/music.png"
            }
        }
        ColumnLayout {
            id: mediaNameWrapper
            Layout.margins: root.smallSpacing
            Layout.fillHeight: true
            spacing: 0

            PlasmaComponents.Label {
                id: audioTitle
                Layout.fillWidth: true
                font.capitalization: Font.Capitalize
                font.weight: Font.Bold
                font.pixelSize: root.largeFontSize
                horizontalAlignment: mpris2Model ? Qt.AlignLeft : Text.AlignHCenter
                elide: Text.ElideRight
                text: {
                    return track ? track : i18n("Unknown Media")
                }
            }
            PlasmaComponents.Label {
                id: audioArtist
                Layout.fillWidth: true
                font.pixelSize: root.mediumFontSize
                // visible: isPlaying
                text: {
                     try {
                        return artist.join(", ")
                    } catch(err) {
                        return artist ? artist : i18n("Unknown Artist")
                    } 
                }
            }
        }
        RowLayout {
            id: audioControls
            Layout.alignment: Qt.AlignRight

            Kirigami.Icon {
                Layout.preferredHeight: mediaNameWrapper.implicitHeight
                Layout.preferredWidth: height
                source: "media-skip-backward"
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: previous()
                }
            }

            Kirigami.Icon {
                id: playIcon
                Layout.preferredHeight: mediaNameWrapper.implicitHeight
                Layout.preferredWidth: height
                source: isPlaying ? "media-playback-pause" : "media-playback-start"
                MouseArea {
                    anchors.fill: parent
                    onClicked: togglePlaying()
                }
            }

            Kirigami.Icon {
                Layout.preferredHeight: mediaNameWrapper.implicitHeight
                Layout.preferredWidth: height
                source: "media-skip-forward"
                MouseArea {
                    anchors.fill: parent
                    onClicked: next()
                }
            }
        }
    }
    
    function previous() {
        mpris2Model.currentPlayer.Previous();
    }
    function next() {
        mpris2Model.currentPlayer.Next();
    }
    function play() {
        mpris2Model.currentPlayer.Play();
    }
    function pause() {
        mpris2Model.currentPlayer.Pause();
    }
    function togglePlaying() {
        mpris2Model.currentPlayer.PlayPause();
    }
    function stop() {
        mpris2Model.currentPlayer.Stop();
    }
    function quit() {
        mpris2Model.currentPlayer.Quit();
    }
    function raise() {
        mpris2Model.currentPlayer.Raise();
    }

    Mpris.Mpris2Model {
        id: mpris2Model
    }
    
    Component.onCompleted: {
        Plasmoid.removeInternalAction("configure");
    }
}
