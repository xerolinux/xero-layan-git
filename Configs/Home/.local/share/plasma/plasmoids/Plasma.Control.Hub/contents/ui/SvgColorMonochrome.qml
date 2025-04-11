import QtQuick
import org.kde.kirigami as Kirigami

Item {
    property bool isMonochrome: false

    Kirigami.Icon {
        id: icon
        height: 22
        width: 22
        source: "audio-volume-high-symbolic"
    }


    Image {
        id: svgImage
        source: icon
        visible: false // We use this to load the image but don't display it directly
        onStatusChanged: {
            if (status === Image.Ready) {
                console.log("se ha cargado correctamnete")
                svgCanvas.requestPaint()
            }
        }
    }

    Canvas {
        id: svgCanvas
        width: svgImage.width
        height: svgImage.height
        visible: true

        onPaint: {
            var ctx = getContext('2d');
            ctx.drawImage(icon, 0, 0);
            var imageData = ctx.getImageData(0, 0, width, height);
                var pixels = imageData.data
                var firstColor = { r: pixels[0], g: pixels[1], b: pixels[2], a: pixels[3] }
                console.log("sweereqer")
                isMonochrome = true

                for (var i = 4; i < pixels.length; i += 4) {
                    var r = pixels[i]
                    var g = pixels[i + 1]
                    var b = pixels[i + 2]
                    var a = pixels[i + 3]

                    if (r !== firstColor.r || g !== firstColor.g || b !== firstColor.b || a !== firstColor.a) {
                        isMonochrome = false
                        break
                    }
                }
                console.log("The SVG is", isMonochrome ? "monochrome" : "not monochrome")
        }
    }

    Component.onCompleted: {
        //console.log(Kirigami.IconUtils.icon("audio-volume-high-symbolic"))
         svgCanvas.requestPaint()
    }
}
