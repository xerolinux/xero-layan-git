import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents

Item {
    id: labelWrapper
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.minimumWidth: label.contentWidth
    Layout.minimumHeight: label.contentHeight
    property alias text: label.text
    property alias font: label.font
    property alias elide: label.elide
    property alias color: label2.color 
    property alias labelWidth: label.width
    property bool fill: true && root.enableFillAnimation
    
    property int from;
    property int to;
    property int currentVal;
    
    Text {
        id: label
        font.family: root.fontFamily
        font.capitalization: Font.AllUppercase
        font.weight: Font.Thin
        color: labelWrapper.fill ? root.textBackgroundColor : labelWrapper.color
        verticalAlignment: Text.AlignBottom
        renderType: Text.QtRendering
    }
    FontMetrics {
        id: metrics
        font: label.font
    }
    Text {
        id: label2
        visible: labelWrapper.fill
        elide: label.elide
        width: label.width
        // HACK "metrics.ascent-metrics.descent+(root.sizeFactor*0.1)" is approximately the same as cap height of the font but not exactly equal
        height: labelWrapper.fill ? ((metrics.ascent-metrics.descent + (font.pixelSize*0.1))/(((to-from)+1)/currentVal))+metrics.descent : 0
        anchors.bottom: label.bottom
        verticalAlignment: Text.AlignBottom
        renderType: Text.QtRendering
        text: label.text
        font: label.font
        clip: true
        Component.onCompleted: {
            console.log(metrics.descent)
        }
    }
}
