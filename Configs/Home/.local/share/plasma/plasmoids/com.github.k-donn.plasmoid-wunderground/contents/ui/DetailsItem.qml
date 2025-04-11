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
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import "../code/utils.js" as Utils

GridLayout {
    id: detailsRoot

    columns: 3
    rows: 4

    PlasmaComponents.Label {
        id: temp
        text: Utils.currentTempUnit(Utils.toUserTemp(weatherData["details"]["temp"]),plasmoid.configuration.tempPrecision)
        font {
            bold: true
            pointSize: plasmoid.configuration.tempPointSize
        }
        // Use theme color if user doesn't want temp colored
        color: plasmoid.configuration.tempAutoColor ? Utils.heatColor(weatherData["details"]["temp"], Kirigami.Theme.backgroundColor) : Kirigami.Theme.textColor
    }
    Kirigami.Icon {
        id: topPanelIcon

        source: Utils.getWindBarbIcon(weatherData["details"]["windSpeed"])

        isMask: plasmoid.configuration.applyColorScheme ? true : false
        color: Kirigami.Theme.textColor

        // wind barb icons are 270 degrees deviated from 0 degrees (north)
        rotation: weatherData["winddir"] - 270


        Layout.minimumWidth: Kirigami.Units.iconSizes.large
        Layout.minimumHeight: Kirigami.Units.iconSizes.large
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight
    }

    PlasmaComponents.Label {
        id: windLabel
        text: i18n("Wind & Gust")
        font {
            bold: true
            pointSize: plasmoid.configuration.propHeadPointSize
        }
    }

    PlasmaComponents.Label {
        id: feelsLike
        text: i18n("Feels like %1", Utils.currentTempUnit(Utils.feelsLike(weatherData["details"]["temp"], weatherData["humidity"], weatherData["details"]["windSpeed"]),plasmoid.configuration.feelsPrecision))
        font.pointSize: plasmoid.configuration.propPointSize
    }
    PlasmaComponents.Label {
        id: windDirCard
        text: i18n("Wind from: %1 (%2°)", Utils.windDirToCard(weatherData["winddir"]), weatherData["winddir"])
        font.pointSize: plasmoid.configuration.propPointSize
    }
    PlasmaComponents.Label {
        id: wind
        text: Utils.toUserSpeed(weatherData["details"]["windSpeed"]).toFixed(plasmoid.configuration.windPrecision) + " / " + Utils.currentSpeedUnit(Utils.toUserSpeed(weatherData["details"]["windGust"]),plasmoid.configuration.windPrecision)
        font.pointSize: plasmoid.configuration.propPointSize
    }

    PlasmaComponents.Label {
        id: dewLabel
        text: i18n("Dew Point")
        font {
            bold: true
            pointSize: plasmoid.configuration.propHeadPointSize
        }
    }
    PlasmaComponents.Label {
        id: precipRateLabel
        text: i18n("Precipitation Rate")
        font {
            bold: true
            pointSize: plasmoid.configuration.propHeadPointSize
        }
    }
    PlasmaComponents.Label {
        id: pressureLabel
        text: i18n("Pressure")
        font {
            bold: true
            pointSize: plasmoid.configuration.propHeadPointSize
        }
    }

    PlasmaComponents.Label {
        id: dew
        text: Utils.currentTempUnit(Utils.toUserTemp(weatherData["details"]["dewpt"]),plasmoid.configuration.dewPrecision)
        font.pointSize: plasmoid.configuration.propPointSize
    }
    PlasmaComponents.Label {
        id: precipRate
        text: Utils.currentPrecipUnit(Utils.toUserPrecip(weatherData["details"]["precipRate"], isRain), isRain) + "/hr"
        font.pointSize: plasmoid.configuration.propPointSize
    }
    Row {
        PlasmaComponents.Label {
            id: pressure
            text: Utils.currentPresUnit(Utils.toUserPres(weatherData["details"]["pressure"]))
            font.pointSize: plasmoid.configuration.propPointSize
        }
        Kirigami.Icon {
            source: Utils.getPressureTrendIcon(weatherData["details"]["pressureTrendCode"])

            visible: plasmoid.configuration.showPresTrend

            height: Kirigami.Units.iconSizes.small

            isMask: plasmoid.configuration.applyColorScheme ? true : false
            color: Kirigami.Theme.textColor

            PlasmaCore.ToolTipArea {
                anchors.fill: parent

                mainText: weatherData["details"]["pressureTrend"]
                subText: Utils.hasPresIncreased(weatherData["details"]["pressureTrendCode"]) ? i18n("Pressure has risen %1 in the last three hours.", Utils.currentPresUnit(Math.abs(Utils.toUserPres(weatherData["details"]["pressureDelta"])))) : i18n("Pressure has fallen %1 in the last three hours.", Utils.currentPresUnit(Math.abs(Utils.toUserPres(weatherData["details"]["pressureDelta"]))))
            }
        }
    }

    PlasmaComponents.Label {
        id: humidityLabel
        text: i18n("Humidity")
        font {
            bold: true
            pointSize: plasmoid.configuration.propHeadPointSize
        }
    }
    PlasmaComponents.Label {
        id: precipAccLabel
        text: i18nc("Short for: 'Precipitation Accumulation'", "Precipitation Accum.")
        font {
            bold: true
            pointSize: plasmoid.configuration.propHeadPointSize
        }
    }
    PlasmaComponents.Label {
        id: uvLabel
        text: i18n("UV")
        font {
            bold: true
            pointSize: plasmoid.configuration.propHeadPointSize
        }
    }

    PlasmaComponents.Label {
        id: humidity
        text: weatherData["humidity"] + "%"
        font.pointSize: plasmoid.configuration.propPointSize
    }
    PlasmaComponents.Label {
        id: precipAcc
        text: Utils.currentPrecipUnit(Utils.toUserPrecip(weatherData["details"]["precipTotal"], isRain), isRain)
        font.pointSize: plasmoid.configuration.propPointSize
    }
    PlasmaComponents.Label {
        id: uv
        text: weatherData["uv"]
        font.pointSize: plasmoid.configuration.propPointSize
    }
}
