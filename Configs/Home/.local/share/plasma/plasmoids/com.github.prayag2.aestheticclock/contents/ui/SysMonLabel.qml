import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents

RowLayout {
    id: labelWrapper
    property alias text: displayText.text
    property alias from: displayText.from
    property alias to: displayText.to
    property string color;
    property string usage;
    property string unit; 

    FontLabel {
        id: displayText
        font.family: root.fontFamily
        font.pixelSize: root.sysMonTextFontSize
        color: labelWrapper.color
        currentVal: usage
    }
    FontLabel {
        id: usageText 
        font.family: root.fontFamily
        font.pixelSize: root.sysMonUsageFontSize
        color: labelWrapper.color
        fill: false
        text: unit ? usage + unit : usage
    }
}
