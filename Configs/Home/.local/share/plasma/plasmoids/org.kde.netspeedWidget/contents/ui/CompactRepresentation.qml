/*
 * Copyright 2016  Daniel Faust <hessijames@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

Item {
    anchors.fill: parent

    property double marginFactor: 0.2

    property double downSpeed: {
        var speed = 0
        for (var key in speedData) {
            if (interfacesWhitelistEnabled && interfacesWhitelist.indexOf(key) === -1) {
                continue
            }
            speed += speedData[key].down
        }
        return speed
    }

    property double upSpeed: {
        var speed = 0
        for (var key in speedData) {
            if (interfacesWhitelistEnabled && interfacesWhitelist.indexOf(key) === -1) {
                continue
            }
            speed += speedData[key].up
        }
        return speed
    }

    property bool singleLine: {
        if (!showSeparately) {
            return true
        }
        switch (speedLayout) {
            case 'rows': return false
            case 'columns': return true
            default: return height / 2 * fontSizeScale < Kirigami.Theme.smallFont.pixelSize && plasmoid.formFactor != PlasmaCore.Types.Vertical
        }
    }

    property double marginWidth: speedTextMetrics.font.pixelSize * marginFactor
    property double iconWidth: showIcons ? iconTextMetrics.width + marginWidth : 0
    property double doubleIconWidth: showIcons ? (doubleIconTextMetrics.width + marginWidth) : 0
    property double speedWidth: speedTextMetrics.width + 2*marginWidth
    property double unitWidth: showUnits ? unitTextMetrics.width + marginWidth : 0

    property double aspectRatio: {
        if (showSeparately) {
            if (singleLine) {
                return (2*iconWidth + 2*speedWidth + 2*unitWidth + marginWidth) * fontSizeScale / speedTextMetrics.height
            } else {
                return (iconWidth + speedWidth + unitWidth) * fontSizeScale / (2*speedTextMetrics.height)
            }
        } else {
            return (doubleIconWidth + speedWidth + unitWidth) * fontSizeScale / speedTextMetrics.height
        }
    }

    property double fontHeightRatio: speedTextMetrics.font.pixelSize / speedTextMetrics.height

    property double offset: {
        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            return (width - height * aspectRatio) / 2
        } else {
            return 0
        }
    }

    Layout.minimumWidth: {
        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            return 0
        } else if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            return Math.ceil(height * aspectRatio)
        } else {
            return Math.ceil(height * aspectRatio)
        }
    }
    Layout.minimumHeight: {
        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            return Math.ceil(width / aspectRatio * fontSizeScale * fontSizeScale)
        } else if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            return 0
        } else {
            return Math.ceil(Kirigami.Theme.smallFont.pixelSize / fontSizeScale)
        }
    }

    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        icon: 'network-connect'
        mainText: i18n('Network usage')
        subText: {
            var details = ''
            for (var key in speedData) {
                if (interfacesWhitelistEnabled && interfacesWhitelist.indexOf(key) === -1) {
                    continue
                }

                if (details != '') {
                    details += '<br><br>'
                }

                details += '<b>' + key + '</b><br>'
                details += 'Downloaded: <b>' + totalText(speedData[key].downTotal) + '</b>, Uploaded: <b>' + totalText(speedData[key].upTotal) + '</b>'
            }
            return details
        }
    }

    TextMetrics {
        id: iconTextMetrics
        text: '↓'
        font.pixelSize: 64
    }

    TextMetrics {
        id: doubleIconTextMetrics
        text: '↓↑'
        font.pixelSize: 64
    }

    TextMetrics {
        id: speedTextMetrics
        text: '1000.0'
        font.pixelSize: 64
    }

    TextMetrics {
        id: unitTextMetrics
        text: {
            if (speedUnits === 'bits') {
                return shortUnits ? 'm' : 'Mb/s'
            } else {
                return shortUnits ? 'M' : 'MiB/s'
            }
        }
        font.pixelSize: 64
    }

    Plasma5Support.DataSource {
        id: appsSource
        engine: 'apps'
        connectedSources: launchApplication
    }

    Loader {
        id: 'launcher'
        source: 'Launcher.qml'
    }

    Item {
        id: offsetItem
        width: offset
        height: parent.height
        x: 0
        y: 0
    }

    Text {
        id: topIcon

        height: singleLine ? parent.height : parent.height / 2
        width: (showSeparately ? 1 : 2) * iconTextMetrics.width / iconTextMetrics.height * height * fontSizeScale

        verticalAlignment: Text.AlignVCenter
        anchors.left: offsetItem.right
        anchors.leftMargin: font.pixelSize * marginFactor
        y: 0
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: showSeparately ? (swapDownUp ? '↑' : '↓') : '↓↑'
        color: Kirigami.Theme.textColor
        visible: showIcons
    }

    Text {
        id: topText

        height: singleLine ? parent.height : parent.height / 2
        width: speedTextMetrics.width / speedTextMetrics.height * height * fontSizeScale

        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        anchors.left: showIcons ? topIcon.right : offsetItem.right
        anchors.leftMargin: font.pixelSize * marginFactor
        y: 0
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: speedText(showSeparately ? (swapDownUp ? upSpeed : downSpeed) : downSpeed + upSpeed, showLowSpeeds)
        color: speedColor(showSeparately ? (swapDownUp ? upSpeed : downSpeed) : downSpeed + upSpeed)
    }

    Text {
        id: topUnitText

        height: singleLine ? parent.height : parent.height / 2
        width: unitTextMetrics.width / unitTextMetrics.height * height * fontSizeScale

        verticalAlignment: Text.AlignVCenter
        anchors.left: topText.right
        anchors.leftMargin: font.pixelSize * marginFactor
        y: 0
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: speedUnit(showSeparately ? (swapDownUp ? upSpeed : downSpeed) : downSpeed + upSpeed)
        color: Kirigami.Theme.textColor
        visible: showUnits
    }

    Text {
        id: bottomIcon

        height: singleLine ? parent.height : parent.height / 2
        width: iconTextMetrics.width / iconTextMetrics.height * height * fontSizeScale

        verticalAlignment: Text.AlignVCenter
        anchors.left: (singleLine && showUnits) ? topUnitText.right : (singleLine ? topText.right : offsetItem.right)
        anchors.leftMargin: (singleLine ? 2 : 1) * font.pixelSize * marginFactor
        y: singleLine ? 0 : parent.height / 2
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: swapDownUp ? '↓' : '↑'
        color: Kirigami.Theme.textColor
        visible: showSeparately && showIcons
    }

    Text {
        id: bottomText

        height: singleLine ? parent.height : parent.height / 2
        width: speedTextMetrics.width / speedTextMetrics.height * height * fontSizeScale

        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        anchors.left: showIcons ? bottomIcon.right : ((singleLine && showUnits) ? topUnitText.right : (singleLine ? topText.right : offsetItem.right))
        anchors.leftMargin: font.pixelSize * marginFactor
        y: singleLine ? 0 : parent.height / 2
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: speedText(swapDownUp ? downSpeed : upSpeed, showLowSpeeds)
        color: speedColor(swapDownUp ? downSpeed : upSpeed)
        visible: showSeparately
    }

    Text {
        id: bottomUnitText

        height: singleLine ? parent.height : parent.height / 2
        width: unitTextMetrics.width / unitTextMetrics.height * height * fontSizeScale

        verticalAlignment: Text.AlignVCenter
        anchors.left: bottomText.right
        anchors.leftMargin: font.pixelSize * marginFactor
        y: singleLine ? 0 : parent.height / 2
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: speedUnit(swapDownUp ? downSpeed : upSpeed)
        color: Kirigami.Theme.textColor
        visible: showSeparately && showUnits
    }

    MouseArea {
        anchors.fill: parent
        enabled: launchApplicationEnabled

        onClicked: {
            if (launcher.item && appsSource.data[launchApplication]) {
                launcher.item.launch("file:" + appsSource.data[launchApplication].entryPath)
            }
        }
    }

    function speedText(value, showLowSpeeds) {
        if (speedUnits === 'bits') {
            value *= 8 * 1.024
            if (value >= 1000 * 1000 * 1000) {
                value /= 1000 * 1000 * 1000
            }
            else if (value >= 1000 * 1000) {
                value /= 1000 * 1000
            }
            else if (value >= 1000) {
                value /= 1000
            }
            else if (!showLowSpeeds) {
                value = 0
            }
        } else {
            if (value >= 1000 * 1024 * 1024) {
                value /= 1024 * 1024 * 1024
            }
            else if (value >= 1000 * 1024) {
                value /= 1024 * 1024
            }
            else if (value >= 1000) {
                value /= 1024
            }
            else if (!showLowSpeeds) {
                value = 0
            }
        }
        return (Math.round(value * 10) / 10).toFixed(1)
    }

    function speedColor(value) {
        if (!customColors) {
            return Kirigami.Theme.textColor
        }

        if (speedUnits === 'bits') {
            value *= 8 * 1.024
            if (value >= 1000 * 1000 * 1000) {
                return gigabyteColor
            }
            else if (value >= 1000 * 1000) {
                return megabyteColor
            }
            else if (value >= 1000) {
                return kilobyteColor
            }
            else {
                return byteColor
            }
        } else {
            if (value >= 1000 * 1024 * 1024) {
                return gigabyteColor
            }
            else if (value >= 1000 * 1024) {
                return megabyteColor
            }
            else if (value >= 1000) {
                return kilobyteColor
            }
            else {
                return byteColor
            }
        }
    }

    function speedUnit(value) {
        if (speedUnits === 'bits') {
            value *= 8 * 1.024
            if (value >= 1000 * 1000 * 1000) {
                return shortUnits ? 'g' : 'Gb/s'
            }
            else if (value >= 1000 * 1000) {
                return shortUnits ? 'm' : 'Mb/s'
            }
            else if (value >= 1000) {
                return shortUnits ? 'k' : 'Kb/s'
            }
            else {
                return shortUnits ? 'b' : 'b/s'
            }
        } else {
            if (value >= 1000 * 1024 * 1024) {
                return shortUnits ? 'G' : 'GiB/s'
            }
            else if (value >= 1000 * 1024) {
                return shortUnits ? 'M' : 'MiB/s'
            }
            else if (value >= 1000) {
                return shortUnits ? 'K' : 'KiB/s'
            }
            else {
                return shortUnits ? 'B' : 'B/s'
            }
        }
    }

    function totalText(value) {
        var unit
        if (value >= 1024 * 1024 * 1024) {
            value /= 1024 * 1024 * 1024
            unit = 'GiB'
        }
        else if (value >= 1024 * 1024) {
            value /= 1024 * 1024
            unit = 'MiB'
        }
        else if (value >= 1024) {
            value /= 1024
            unit = 'KiB'
        }
        else {
            unit = 'B'
        }
        return (Math.round(value * 10) / 10).toFixed(1) + ' ' + unit
    }
}
