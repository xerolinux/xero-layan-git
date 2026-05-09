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
import org.kde.plasma.core as PlasmaCore
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../code/utils.js" as Utils


GridLayout {
    id: iconAndText

    anchors.fill: parent

    property bool vertical: root.vertical

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
    property string temperatureStr: root.appState == showDATA ? Utils.toUserTemp(weatherData["details"]["temp"]).toFixed(0) + "°" : "--"

    columnSpacing: iconVisible && textVisible ? (iconAndText.vertical ? innerMargin - 17 : innerMargin - 18) : innerMargin
    rowSpacing: 0

    rows: 1
    columns: 2

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

        // very large "scale with panel width" system tray icons (>54px) will need manually reduced margins equally on each side to maintain similar scaling with the rest of the icons, because coding that here would interfere with the "small" system tray icons
        Layout.leftMargin: iconAndText.vertical ? (parent.width < 34 ? leftOuterMargin + 3 : parent.width > 44 ? leftOuterMargin + 11 : parent.width > 40 ? leftOuterMargin + 9 : parent.width > 38 ? leftOuterMargin + 7 : leftOuterMargin + 5) : leftOuterMargin - 1

        Layout.topMargin: iconAndText.vertical ? topOuterMargin - 7 : topOuterMargin

        Layout.rightMargin: iconAndText.vertical ? rightOuterMargin :  undefined
        Layout.bottomMargin: iconAndText.vertical ? bottomOuterMargin : bottomOuterMargin + 2

        PlasmaComponents.Label {
            id: compactWeatherIcon
            visible: iconVisible && !plasmoid.configuration.useSystemThemeIcons
            font {
                weight: Font.Normal
                family: "weather-icons"
                pixelSize: iconAndText.vertical ? widgetIconSize : widgetIconSize * 0.69
                pointSize: 0 // we need to unset pointSize otherwise it breaks the Text.Fit size mode
            }
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit / 2)
            fontSizeMode: iconSizeMode === 0 ? (iconAndText.vertical ? Text.HorizontalFit : Text.VerticalFit) : Text.FixedSize
            wrapMode: Text.NoWrap

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: visible ? iconNameStr : "\uF037"
            anchors {
                fill: parent
                left: compactItemInTray.left
                right: compactItemInTray.right
                top: compactItemInTray.top
                bottom: compactItemInTray.bottom
            }
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

    Item {
        // Otherwise it takes up too much space while loading
        visible: temperatureText.text.length > 0

        Layout.alignment: Qt.AlignCenter

        Layout.fillWidth: iconAndText.vertical
        Layout.fillHeight: !iconAndText.vertical
        Layout.minimumWidth: textVisible ? (iconAndText.vertical ? 0 : iconAndText.width * 0.84) : 0
        Layout.maximumWidth: iconAndText.vertical ? Infinity : iconAndText.width * 0.84

        Layout.minimumHeight: textVisible ? (iconAndText.vertical ? iconAndText.height * 0.84 : 0) : 0
        Layout.maximumHeight: iconAndText.vertical ? iconAndText.height * 0.84 : Infinity

        // very large "scale with panel width" system tray icons (>54px) will need manually reduced margins equally on each side to maintain similar scaling with the rest of the icons, because coding that here would interfere with the "small" system tray icons
        Layout.rightMargin: iconAndText.vertical ? (parent.width < 34 ? rightOuterMargin + 3 : parent.width > 44 ? rightOuterMargin + 11 : parent.width > 40 ? rightOuterMargin + 9 : parent.width > 38 ? rightOuterMargin + 7 : rightOuterMargin + 5) : rightOuterMargin - 4

        Layout.bottomMargin: iconAndText.vertical ? bottomOuterMargin - 13 : bottomOuterMargin - 5
        // bottomOuterMargin - 16

        Layout.leftMargin: iconAndText.vertical ? leftOuterMargin :  undefined
        Layout.topMargin: iconAndText.vertical ? topOuterMargin : topOuterMargin + 3

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
            fontSizeMode: textSizeMode === 0 ? Text.Fit : Text.FixedSize
            wrapMode: Text.NoWrap

            height: 0
            width: 0
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: temperatureStr
            anchors {
                        fill: parent
                        left: compactItemInTray.left
                        right: compactItemInTray.right
                        top: compactItemInTray.top
                        bottom: compactItemInTray.bottom
            }
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

}
