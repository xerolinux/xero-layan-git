import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.kcmutils // KCMLauncher
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.private.volume

Item {

    property var sink: PreferredDevice.sink
    readonly property bool sinkAvailable: sink && !(sink && sink.name == "auto_null")



    Slider {
        id: sli
        width: (parent.width - 37) *.9
        height: 24
        anchors.left: parent.left
        anchors.leftMargin: (parent.width - width - buttonsettingPulseAudio.width)/2
        //anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: buttonsettingPulseAudio.verticalCenter
        from: 0
        value: (sink.volume / PulseAudio.NormalVolume * 100)
        to: 100
        snapMode: Slider.SnapAlways
        //stepSize: 5
        onMoved: {
            sink.volume = value * PulseAudio.NormalVolume / 100
        }
    }

    Item {
        id: buttonsettingPulseAudio
        width: 32
        height: 32
        anchors.left: sli.right
        anchors.leftMargin: 5
        anchors.verticalCenter: anchors.verticalCenter

        Kirigami.Icon {
            width: 24
            height: width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            source: "configure"
        }

        Rectangle {
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            height: width
            color: Kirigami.Theme.textColor
            radius: height/2
            opacity: 0.3
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    KCMLauncher.openSystemSettings("kcm_pulseaudio")
                }
            }
        }
    }
}

