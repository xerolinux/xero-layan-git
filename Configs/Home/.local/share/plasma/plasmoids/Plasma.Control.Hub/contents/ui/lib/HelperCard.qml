import QtQuick
import org.kde.ksvg as KSvg

Item {
    property bool isShadow: false
    property bool isMask: false
    property bool colorizer: false
    property int excessWidth: isShadow ? shadowHintLeftMargin.width *2 : 0
    property int excessHeight: isShadow ? shadowHintTopMargin.height *2 : 0
    property int plasmaHintInset: isShadow ? hintInset.width : 0
    property int marginX: excessWidth + plasmaHintInset - shadowHintLeftMargin.width
    property int marginY: excessHeight + plasmaHintInset - shadowHintTopMargin.height
    property var placeHolderCurrent: isMask ? placeHolderMask : isShadow ? placeHolderShadow : placeHolderNormal
    property string prefix: isMask ? "mask-" : isShadow ? "shadow-": ""
    property string pathSvg: "dialogs/background"
    property var namesItemsSvg: ["topleft", "top", "topright",
    "left", "center", "right",
    "bottomleft", "bottom", "bottomright"]

    KSvg.SvgItem {
        id: shadowHintLeftMargin
        imagePath: pathSvg
        elementId: "shadow-hint-left-margin"
        visible: false
    }
    KSvg.SvgItem {
        id: shadowHintTopMargin
        imagePath: pathSvg
        elementId: "shadow-hint-top-margin"
        visible: false
    }
    KSvg.SvgItem {
        id: hintInset
        imagePath: pathSvg
        elementId: "hint-left-inset"
        visible: false
    }
    KSvg.SvgItem {
        id: placeHolderNormal
        imagePath: pathSvg
        elementId: "topleft"
        visible: false
    }
    KSvg.SvgItem {
        id: placeHolderMask
        imagePath: pathSvg
        elementId: "mask-topleft"
        visible: false
    }
    KSvg.SvgItem {
        id: placeHolderShadow
        imagePath: pathSvg
        elementId: "shadow-topleft"
        visible: false
    }

    Flow {
        width: parent.width + excessWidth
        height: parent.height + excessHeight
        anchors.left: parent.left
        anchors.leftMargin: isShadow ? - marginX : 0
        anchors.top: parent.top
        anchors.topMargin: - isShadow ? - marginY : 0
        visible: true

        Repeater {
            model: namesItemsSvg
            delegate: KSvg.SvgItem {
                imagePath: pathSvg
                elementId: prefix + modelData
                width: (modelData === "top" || modelData === "center" || modelData === "bottom")
                ? parent.width - placeHolderCurrent.width*2 : placeHolderCurrent.width
                height: (modelData === "left" || modelData === "center" || modelData === "right")
                ? parent.height - placeHolderCurrent.height*2 : placeHolderCurrent.height

            }
        }
    }
}
