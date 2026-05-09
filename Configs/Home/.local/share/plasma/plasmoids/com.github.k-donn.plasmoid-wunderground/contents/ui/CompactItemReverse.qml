/*
 * Copyright 2015  Martin Kotelnik <clearmartin@seznam.cz>
 * Copyright 2026 Kevin Donnelly
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
import org.kde.plasma.components as PlasmaComponents
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../code/utils.js" as Utils

GridLayout {
    id: iconAndText

    anchors.fill: parent

    property bool vertical: root.vertical

    property int layoutType: root.layoutType
    property int iconSizeMode: root.iconSizeMode
    property int textSizeMode: plasmoid.configuration.textSizeMode
    property int leftOuterMargin: plasmoid.configuration.leftOuterMargin
    property int rightOuterMargin: plasmoid.configuration.rightOuterMargin
    property int innerMargin: plasmoid.configuration.innerMargin
    property int topOuterMargin: plasmoid.configuration.topOuterMargin
    property int bottomOuterMargin: plasmoid.configuration.bottomOuterMargin

    property bool iconVisible: plasmoid.configuration.iconVisible
    property bool textVisible: plasmoid.configuration.textVisible

    property int widgetFontSize: plasmoid.configuration.widgetFontSize
    property int widgetIconSize: plasmoid.configuration.widgetIconSize
    property string widgetFontName: (plasmoid.configuration.widgetFontName === "") ? Kirigami.Theme.defaultFont.family : plasmoid.configuration.widgetFontName
    property bool textDropShadow: plasmoid.configuration.textDropShadow
    property bool iconDropShadow: plasmoid.configuration.iconDropShadow

    property string iconNameStr: Utils.getConditionIcon(root.iconCode, plasmoid.configuration.useSystemThemeIcons)
    property string temperatureStr: root.appState == showDATA ? Utils.toUserTemp(weatherData["details"]["temp"]).toFixed(plasmoid.configuration.compactTempPrecision) + "°" : "--"

    uniformCellHeights: layoutType === 1 && iconAndText.vertical

    columnSpacing: iconVisible && textVisible ? (iconAndText.vertical && layoutType === 0 ? innerMargin + 2 : layoutType === 0 ? innerMargin + 8 : iconAndText.vertical && layoutType === 1 ? innerMargin - 11 : iconAndText.vertical ? innerMargin - 17 : layoutType === 2 ? innerMargin - 13 : innerMargin) : innerMargin

    rowSpacing: layoutType === 1 ? innerMargin - 2 : 0

    rows: (layoutType === 1) ? 2 : 1
    columns: (layoutType === 1) ? 1 : 2

    function reLayout() {
        temperatureText.anchors.left = [compactWeatherIcon.left, compactItem.left, undefined][layoutType]
        temperatureText.anchors.right = [compactItem.right, compactItem.right, compactItem.right][layoutType]
        temperatureText.anchors.top = [compactItem.top, undefined, temperatureText.top][layoutType]
        temperatureText.anchors.bottom = [compactItem.bottom, compactItem.bottom, compactItem.bottom][layoutType]

        compactWeatherIcon.anchors.left = [compactItem.left, compactItem.left, compactItem.left][layoutType]
        compactWeatherIcon.anchors.right = [undefined, compactItem.right, compactItem.right][layoutType]
        compactWeatherIcon.anchors.top = [compactItem.top, compactItem.top, compactItem.top][layoutType]
        compactWeatherIcon.anchors.bottom = [compactItem.bottom, compactWeatherIcon.bottom, compactItem.bottom][layoutType]

        systemIcon.anchors.left = [compactItem.left, compactItem.left, compactItem.left][layoutType]
        systemIcon.anchors.right = [undefined, compactItem.right, compactItem.right][layoutType]
        systemIcon.anchors.top = [compactItem.top, compactItem.top, compactItem.top][layoutType]
        systemIcon.anchors.bottom = [compactItem.bottom, systemIcon.bottom, compactItem.bottom][layoutType]
    }

    onLayoutTypeChanged: {
        reLayout()
    }

    Item {
        // Otherwise it takes up too much space while loading
        visible: temperatureText.text.length > 0

        Layout.alignment: layoutType === 0 ? Qt.AlignCenter : layoutType === 2 ? (iconAndText.vertical ? Qt.AlignCenter : Qt.AlignTop) : Qt.AlignCenter

        Layout.fillWidth: iconAndText.vertical
        Layout.fillHeight: !iconAndText.vertical
        Layout.minimumWidth: textVisible ? (iconAndText.vertical ? 0 : temperatureText.paintedWidth) : 0
        Layout.maximumWidth: iconAndText.vertical ? Infinity : Layout.minimumWidth

        Layout.minimumHeight: textVisible ? (iconAndText.vertical ? temperatureText.paintedHeight : 0) : 0
        Layout.maximumHeight: iconAndText.vertical ? Layout.minimumHeight : layoutType === 2 ? iconAndText.height * 0.69 : Infinity

        Layout.leftMargin: layoutType === 1 ? (iconAndText.vertical ? Kirigami.Units.smallSpacing + leftOuterMargin - 1 : Kirigami.Units.smallSpacing + leftOuterMargin - 5) : iconAndText.vertical ? (layoutType === 2 ? Kirigami.Units.smallSpacing + leftOuterMargin - 1 : Kirigami.Units.smallSpacing + leftOuterMargin - 2) : layoutType === 2 ? (iconAndText.height > 21 ? leftOuterMargin + 1 : leftOuterMargin + 1) : leftOuterMargin - 1

        Layout.topMargin: iconAndText.vertical ? (layoutType === 1 ? topOuterMargin - 4 : layoutType === 2 ? topOuterMargin : topOuterMargin - 1) : layoutType === 1 ? topOuterMargin - 2 : layoutType === 2 ? topOuterMargin : iconAndText.height < 22 ? topOuterMargin + 1 : topOuterMargin

        Layout.rightMargin: layoutType === 1 ? (iconAndText.vertical ? rightOuterMargin + 3 : rightOuterMargin) :  undefined
        Layout.bottomMargin: iconAndText.vertical ? bottomOuterMargin : iconAndText.height < 22 && layoutType === 0 ? bottomOuterMargin + 1 : layoutType === 0 ? bottomOuterMargin : layoutType === 2 ? bottomOuterMargin : undefined

        PlasmaComponents.Label {
            id: temperatureText
            visible: textVisible
            font {
                weight: Font.Normal
                family: widgetFontName
                pixelSize: widgetFontSize
                pointSize: 0 // we need to unset pointSize otherwise it breaks the Text.Fit size mode
            }
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit / 2)
            fontSizeMode: textSizeMode === 0 ? (iconAndText.vertical ? Text.HorizontalFit : Text.VerticalFit) : Text.FixedSize
            wrapMode: Text.NoWrap
            verticalAlignment: (layoutType === 0) ? Text.AlignVCenter : Text.AlignTop
            horizontalAlignment: Text.AlignHCenter
            text: temperatureStr
            anchors.fill: parent
        }

        DropShadow {
            anchors.fill: temperatureText
            radius: 3
            samples: 16
            spread: 0.8
            fast: true
            color: Kirigami.Theme.backgroundColor
            source: temperatureText
            visible: textVisible ? textDropShadow : false
        }

    }

    Item {
        // Otherwise it takes up too much space while loading
        visible: compactWeatherIcon.text.length > 0

        Layout.alignment: Qt.AlignCenter

        Layout.fillWidth: iconAndText.vertical
        Layout.fillHeight: !iconAndText.vertical
        Layout.minimumWidth: iconVisible ? (iconAndText.vertical ? 0 : compactWeatherIcon.paintedWidth) : 0
        Layout.maximumWidth: iconAndText.vertical ? Infinity : Layout.minimumWidth

        Layout.minimumHeight: iconVisible ? (iconAndText.vertical ? compactWeatherIcon.paintedHeight : 0) : 0
        Layout.maximumHeight: iconAndText.vertical ? Layout.minimumHeight : Infinity

        Layout.rightMargin: iconAndText.vertical ? (layoutType === 1 ? rightOuterMargin + 2 : layoutType === 2 ? rightOuterMargin + 3 : rightOuterMargin + 2) : layoutType === 0 ? rightOuterMargin + 1 : layoutType === 2 ? rightOuterMargin + 1 : rightOuterMargin + 1

        Layout.bottomMargin: layoutType === 1 ? (iconAndText.vertical ? bottomOuterMargin + 1 : bottomOuterMargin - 1) : iconAndText.vertical ? (layoutType === 0 ? bottomOuterMargin : bottomOuterMargin) : layoutType === 0 ? (iconAndText.height < 22 ? bottomOuterMargin + 0 : bottomOuterMargin - 0) :  iconAndText.height < 22 ? bottomOuterMargin + 1 : bottomOuterMargin + 1

        Layout.leftMargin: layoutType === 1 ? (iconAndText.vertical ? leftOuterMargin + 3 : leftOuterMargin) :  undefined
        //Layout.topMargin: !(layoutType === 1) ? topOuterMargin : undefined
        Layout.topMargin: iconAndText.vertical && layoutType === 0 ? topOuterMargin : iconAndText.height < 22 && layoutType === 0 ? topOuterMargin + 1 : layoutType === 0 ? topOuterMargin : layoutType === 2 ? topOuterMargin : undefined

        PlasmaComponents.Label {
            id: compactWeatherIcon
            visible: iconVisible && !plasmoid.configuration.useSystemThemeIcons
            font {
                weight: Font.Normal
                family: "weather-icons"
                pixelSize: widgetIconSize
                pointSize: 0 // we need to unset pointSize otherwise it breaks the Text.Fit size mode
            }
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit / 2)
            fontSizeMode: iconSizeMode === 0 ? (iconAndText.vertical ? Text.HorizontalFit : Text.VerticalFit) : Text.FixedSize
            wrapMode: Text.NoWrap
            verticalAlignment: iconAndText.vertical ? Text.AlignVCenter : layoutType === 2 ? Text.AlignTop : Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: iconNameStr
            anchors.fill: parent
        }

        Kirigami.Icon {
            id: systemIcon
            visible: iconVisible && plasmoid.configuration.useSystemThemeIcons
            source: iconNameStr
            anchors.fill: compactWeatherIcon
        }

        DropShadow {
            anchors.fill: compactWeatherIcon
            radius: 3
            samples: 16
            spread: 0.8
            fast: true
            color: Kirigami.Theme.backgroundColor
            source: plasmoid.configuration.useSystemThemeIcons ? systemIcon : compactWeatherIcon
            visible: iconVisible ? iconDropShadow : false
        }

    }

}