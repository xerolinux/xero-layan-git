/*
 * Copyright 2025  Kevin Donnelly
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
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import "../code/utils.js" as Utils

RowLayout {

    TextMetrics {
        id: aqIndexTxt

        text: i18n("Status Color")
    }

    GridLayout {
        id: aqGrid

        columns: 2
        rows: 4

        Layout.preferredWidth: parent.width / 2

        PlasmaComponents.Label {
            id: aqLabel

            Layout.columnSpan: 2
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            font {
                bold: true
                pointSize: 15
            }

            text: i18n("Air quality")
        }
        PlasmaComponents.Label {
            id: aqDesc

            Layout.columnSpan: 2
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            text: weatherData["aq"]["aqDesc"]
        }
        PlasmaComponents.Label {
            id: aqIndex

            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            text: i18n("AQI: %1", weatherData["aq"]["aqi"])
        }
        PlasmaComponents.Label {
            id: aqhi
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            text: i18n("AQHI: %1", weatherData["aq"]["aqhi"])
        }
        Rectangle {
            id: aqIndexColor

            Layout.preferredWidth: aqIndexTxt.width + 5
            Layout.preferredHeight: aqIndexTxt.height + 5
            Layout.alignment: Qt.AlignCenter

            color: "#" + weatherData["aq"]["aqColor"]

            radius: 5

            PlasmaComponents.Label {
                id: aqIndexLabel

                anchors.centerIn: parent

                color: "#000000"

                text: aqIndexTxt.text
            }
        }

        Row {
            Layout.alignment: Qt.AlignCenter

            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignCenter
                text: i18n("Primary pollutant: ")
            }

            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignCenter

                font.underline: true

                text: weatherData["aq"]["aqPrimary"]

                PlasmaCore.ToolTipArea {
                    anchors.fill: parent

                    interactive: true

                    mainText: weatherData["aq"]["primaryDetails"]["phrase"]
                    subText: i18n("Amount: %1 %2<br/>Description: %3<br/>Index: %4", weatherData["aq"]["primaryDetails"]["amount"], weatherData["aq"]["primaryDetails"]["unit"], weatherData["aq"]["primaryDetails"]["desc"], weatherData["aq"]["primaryDetails"]["index"])
                }
            }
        }
    }

    GridLayout {
        id: solGrid

        columns: 2
        rows: 4

        Layout.preferredWidth: parent.width / 2

        PlasmaComponents.Label {
            id: solLabel

            Layout.columnSpan: 2
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            font {
                bold: true
                pointSize: 15
            }

            text: i18n("Solar info")
        }
        PlasmaComponents.Label {
            id: solRad

            Layout.columnSpan: 2
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            textFormat: Text.RichText

            text: weatherData["solarRad"] + " W/m<sup>2</sup>"
        }
        PlasmaComponents.Label {
            id: sunriseLabel

            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            text: i18n("Sunrise")
        }
        PlasmaComponents.Label {
            id: sunsetLabel
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            text: i18n("Sunset")
        }
        PlasmaComponents.Label {
            id: sunrise
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            text: new Date(weatherData["sunrise"]).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
        }
        PlasmaComponents.Label {
            id: sunset
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            text: new Date(weatherData["sunset"]).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
        }
    }
}
