import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

Item {
    implicitWidth:  374
    implicitHeight: 262

    property var    data_:    ({ percent: 0, remaining: "", updated: "", days_left: null, expiry_time: null, error: "" })
    property bool   loading:  false
    property color  pctColor: "#2ecc71"
    property string label:    ""

    onLoadingChanged:  gauge.requestPaint()
    onPctColorChanged: gauge.requestPaint()

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        PC3.Label {
            text: label
            font.pixelSize: 15
            font.bold: true
            opacity: 0.5
            Layout.alignment: Qt.AlignHCenter
            font.letterSpacing: 2
        }

        RowLayout {
            spacing: 16
            Layout.alignment: Qt.AlignHCenter

            Canvas {
                id: gauge
                width:  218
                height: 218

                property real pct: data_.error ? 0 : (data_.percent || 0)

                Behavior on pct { NumberAnimation { duration: 800; easing.type: Easing.InOutCubic } }

                onPctChanged:          requestPaint()
                Component.onCompleted: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var cx         = width  / 2
                    var cy         = height / 2
                    var r          = Math.min(cx, cy) - 15
                    var startAngle = Math.PI * 0.75
                    var fullSweep  = Math.PI * 1.5
                    var endAngle   = startAngle + fullSweep * (pct / 100)

                    for (var i = 0; i <= 10; i++) {
                        var ta      = startAngle + fullSweep * (i / 10)
                        var isMajor = (i % 5 === 0)
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(ta) * (r - (isMajor ? 12 : 6)),
                                   cy + Math.sin(ta) * (r - (isMajor ? 12 : 6)))
                        ctx.lineTo(cx + Math.cos(ta) * (r + 2),
                                   cy + Math.sin(ta) * (r + 2))
                        ctx.lineWidth   = isMajor ? 2 : 1
                        ctx.strokeStyle = Qt.rgba(Kirigami.Theme.textColor.r,
                                                 Kirigami.Theme.textColor.g,
                                                 Kirigami.Theme.textColor.b,
                                                 isMajor ? 0.35 : 0.18)
                        ctx.stroke()
                    }

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, startAngle, startAngle + fullSweep)
                    ctx.lineWidth   = 10
                    ctx.strokeStyle = Qt.rgba(Kirigami.Theme.textColor.r,
                                             Kirigami.Theme.textColor.g,
                                             Kirigami.Theme.textColor.b, 0.10)
                    ctx.lineCap = "round"
                    ctx.stroke()

                    if (pct > 0) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, startAngle, endAngle)
                        ctx.lineWidth   = 10
                        ctx.strokeStyle = pctColor
                        ctx.lineCap     = "round"
                        ctx.stroke()
                    }

                    var needleAngle = startAngle + fullSweep * (pct / 100)
                    var needleLen   = r - 18
                    var needleBase  = 11

                    var glowGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, needleLen)
                    glowGrad.addColorStop(0, Qt.rgba(Qt.color(pctColor).r, Qt.color(pctColor).g, Qt.color(pctColor).b, 0.25))
                    glowGrad.addColorStop(1, Qt.rgba(Qt.color(pctColor).r, Qt.color(pctColor).g, Qt.color(pctColor).b, 0))
                    ctx.beginPath()
                    ctx.moveTo(cx - Math.cos(needleAngle) * needleBase, cy - Math.sin(needleAngle) * needleBase)
                    ctx.lineTo(cx + Math.cos(needleAngle) * needleLen,  cy + Math.sin(needleAngle) * needleLen)
                    ctx.lineWidth = 8; ctx.strokeStyle = glowGrad; ctx.lineCap = "round"; ctx.stroke()

                    ctx.beginPath()
                    ctx.moveTo(cx - Math.cos(needleAngle) * needleBase, cy - Math.sin(needleAngle) * needleBase)
                    ctx.lineTo(cx + Math.cos(needleAngle) * needleLen,  cy + Math.sin(needleAngle) * needleLen)
                    ctx.lineWidth   = 2.5
                    ctx.strokeStyle = loading ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4) : pctColor
                    ctx.lineCap = "round"; ctx.stroke()

                    ctx.beginPath()
                    ctx.arc(cx, cy, 6, 0, Math.PI * 2)
                    ctx.fillStyle = loading ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4) : pctColor
                    ctx.fill()

                    ctx.fillStyle    = loading ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
                                     : data_.error ? "#e74c3c" : pctColor
                    ctx.font         = "bold 22px sans-serif"
                    ctx.textAlign    = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillText(loading ? "…" : data_.error ? "ERR" : pct.toFixed(1) + "%",
                                 cx, cy + r * 0.72)
                }

                Connections {
                    target: Kirigami.Theme
                    function onTextColorChanged() { gauge.requestPaint() }
                }
            }

            ColumnLayout {
                spacing: 3
                Layout.alignment: Qt.AlignVCenter

                PC3.Label { text: "Remaining"; font.pixelSize: 13; opacity: 0.5 }
                PC3.Label {
                    text: loading ? "…" : data_.error ? data_.error : (data_.remaining || "—")
                    font.pixelSize: 16; font.bold: true
                    color: data_.error ? "#e74c3c" : Kirigami.Theme.textColor
                    wrapMode: Text.WordWrap
                    Layout.maximumWidth: 132
                }

                Item { height: 6 }

                PC3.Label { text: "Updated"; font.pixelSize: 13; opacity: 0.5 }
                PC3.Label { text: data_.updated || "—"; font.pixelSize: 16; opacity: 0.85 }

                Item { height: 6 }

                PC3.Label { text: "Expires In"; font.pixelSize: 13; opacity: 0.5 }
                PC3.Label {
                    text: data_.days_left === null || data_.days_left === undefined ? "—"
                        : data_.days_left < 0  ? "Expired"
                        : data_.days_left === 0 ? (data_.expiry_time ? "Today " + data_.expiry_time : "Today")
                        : data_.days_left + " days"
                    font.pixelSize: 16; font.bold: true
                    color: data_.days_left !== null && data_.days_left < 0  ? "#e74c3c"
                         : data_.days_left !== null && data_.days_left <= 5 ? "#f39c12"
                         : Kirigami.Theme.textColor
                }
            }
        }
    }
}
