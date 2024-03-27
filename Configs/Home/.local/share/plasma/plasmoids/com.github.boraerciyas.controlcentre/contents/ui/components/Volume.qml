import QtQml 2.0
import QtQuick
import QtQuick.Layouts 1.15

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

import org.kde.kcmutils // KCMLauncher
import org.kde.config // KAuthorized

import org.kde.plasma.private.volume 0.1

import "../lib" as Lib
import "../js/funcs.js" as Funcs

Lib.Slider {
    Layout.fillWidth: true
    Layout.preferredHeight: root.sectionHeight/2
    visible: sinkAvailable && root.showVolume
    useIconButton: true
    title: i18n("Volume")
    
    // Volume Feedback
    VolumeFeedback {
        id: feedback
    }

    GlobalConfig {
        id: config
    }
    
    // Audio source
    property var sink: paSinkModel.preferredSink
    readonly property bool sinkAvailable: sink && !(sink && sink.name == "auto_null")
    property bool volumeFeedback: config.audioFeedback
    property bool globalMute: config.globalMute
    property int currentMaxVolumePercent: config.raiseMaximumVolume ? 150 : 100
    property int currentMaxVolumeValue: currentMaxVolumePercent * PulseAudio.NormalVolume / 100.00
    property int volumePercentStep: config.volumeStep
    readonly property SinkModel paSinkModel: SinkModel {
        id: paSinkModel
    }
    
    value: Math.round(sink.volume / PulseAudio.NormalVolume * 100)
    secondaryTitle: Math.round(sink.volume / PulseAudio.NormalVolume * 100) + "%"
    
    // Changes icon based on the current volume percentage
    source: Funcs.volIconName(sink.volume, sink.muted)
    
    onValueChanged: {
        if(root.playVolumeFeedback) {
            feedback.play(sink.index)
        }
    }
    // Update volume
    onMoved: {
        sink.volume = value * PulseAudio.NormalVolume / 100
    }
    
    property var oldVol: 100 * PulseAudio.NormalVolume / 100
    onClicked: {
        if(value!=0){
            oldVol = sink.volume
            sink.volume=0
        } else {
            sink.volume=oldVol
        }
    }
}