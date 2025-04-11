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

import QtQml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import "../code/utils.js" as Utils
import "../code/pws-api.js" as StationAPI

PlasmoidItem {
    id: root

    property var weatherData: {
        "stationID": "",
        "uv": 0,
        "obsTimeLocal": "",
        "isNight": false,
        "winddir": 0,
        "lat": 0,
        "lon": 0,
        "sunrise": "2020-08-09T07:00:10-0500",
        "sunset": "2020-08-09T20:00:10-0500",
        "solarRad": 0,
        "humidity": 0,
        "details": {
            "temp": 0,
            "windSpeed": 0,
            "windGust": 0,
            "dewpt": 0,
            "solarRad": 0,
            "precipRate": 0,
            "pressure": 0,
            "pressureTrend": "Steady",
            "pressureTrendCode": 0,
            "pressureDelta": 0,
            "precipTotal": 0,
            "elev": 0
        },
        "aq": {
            "aqi": 0,
            "aqhi": 0,
            "aqDesc": "Good",
            "aqColor": "FFFFFF",
            "aqPrimary": "PM2.5",
            "primaryDetails": {
                "phrase": "Particulate matter <2.5 microns",
                "amount": 0,
                "unit": "ug/m3",
                "desc": "Moderate",
                "index": 0
            }
        }
    }
    property ListModel forecastModel: ListModel {}
    property ListModel hourlyModel: ListModel {}
    property ListModel alertsModel: ListModel {}

    property string errorStr: ""
    property string iconCode: "32" // 32 = sunny
    property string conditionNarrative: ""

    property int showCONFIG: 1
    property int showLOADING: 2
    property int showERROR: 4
    property int showDATA: 8

    property int appState: showCONFIG
    // QML does not let you property bind items part of ListModels.
    // The TopPanel shows the high/low values which are items part of forecastModel
    // These are updated in pws-api.js to overcome that limitation
    property int currDayHigh: 0
    property int currDayLow: 0

    property bool showForecast: false

    property string stationID: plasmoid.configuration.stationID
    property int unitsChoice: plasmoid.configuration.unitsChoice
    property int tempUnitsChoice: plasmoid.configuration.tempUnitsChoice
    property int windUnitsChoice: plasmoid.configuration.windUnitsChoice
    property int rainUnitsChoice: plasmoid.configuration.rainUnitsChoice
    property int snowUnitsChoice: plasmoid.configuration.snowUnitsChoice
    property int presUnitsChoice: plasmoid.configuration.presUnitsChoice
    property bool useLegacyAPI: plasmoid.configuration.useLegacyAPI

    property bool inTray: false
    // Metric units change based on precipitation type
    property bool isRain: true

    property var textSize: ({
        normal: plasmoid.configuration.propPointSize,
        small: plasmoid.configuration.propPointSize - 1,
        tiny: plasmoid.configuration.propPointSize - 2
    })

    property var maxValDict: ({
        temperature: -999,
        humidity: -999,
        cloudCover: -999,
        precipitationChance: -999,
        precipitationRate: -999,
        snowPrecipitationRate: -999,
        wind: -999,
        pressure: -999,
        uvIndex: -999,
    })

    property var rangeValDict: ({
        temperature: 30,
        humidity: 100,
        cloudCover: 100,
        precipitationChance: 100,
        precipitationRate: 5,
        snowPrecipitationRate: 5,
        wind: 10,
        pressure: 5,
        uvIndex: 5,
    })

    property var propInfoDict: ({
        temperature: {
            unit: Utils.rawTempUnit(),
            name: i18n("Temperature")
        },
        humidity: {
            unit: "%",
            name: i18n("Humidity")
        },
        cloudCover: {
            unit: "%",
            name: i18n("Cloud Cover")
        },
        precipitationChance: {
            unit: "%",
            name: i18n("Precipitation Chance")
        },
        precipitationRate: {
            unit: Utils.rawPrecipUnit(true),
            name: i18n("Precipitation Rate")
        },
        snowPrecipitationRate: {
            unit: Utils.rawPrecipUnit(false),
            name: i18n("Snow Precipitation Rate")
        },
        wind: {
            unit: Utils.rawSpeedUnit(),
            name: i18n("Wind & Gust")
        },
        pressure: {
            unit: Utils.rawPresUnit(),
            name: i18n("Pressure")
        },
        uvIndex: {
            unit: "",
            name: i18n("UV")
        },
    })

    property Component fr: FullRepresentation {
        Layout.preferredWidth: 600
        Layout.preferredHeight: 380
    }

    property Component cr: CompactRepresentation {
        // Layout.preferredWidth: 16
        // Layout.preferredHeight: 16
    }

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {
            console.log("[debug] [main.qml] " + msg);
        }
    }

    function printDebugJSON(json) {
        if (plasmoid.configuration.logConsole) {
            console.log("[debug] [main.qml] " + JSON.stringify(json));
        }
    }

    function updateWeatherData() {
        printDebug("Getting new weather data");
        StationAPI.getCurrentData(function() {
            StationAPI.getForecastData(StationAPI.getHourlyData)
        });
    }

    function updateCurrentData() {
        printDebug("Getting new current data");
        StationAPI.getCurrentData();
    }

    function updateForecastData() {
        printDebug("Getting new forecast data");
        StationAPI.getForecastData(StationAPI.getHourlyData);
    }

    onStationIDChanged: {
        printDebug("Station ID changed");

        // Show loading screen after ID change
        appState = showLOADING;
        updateWeatherData();
    }

    onUnitsChoiceChanged: {
        printDebug("Units changed");

        // A user could configure units but not station id. This would trigger improper request.
        if (stationID != "") {
            // Show loading screen after units change
            appState = showLOADING;
            updateWeatherData();
        }
    }

    onTempUnitsChoiceChanged: {
        printDebug("Temp Units changed");

        if (stationID != "") {
            appState = showLOADING;
            updateWeatherData();
        }
    }

    onWindUnitsChoiceChanged: {
        printDebug("Wind Units changed");

        if (stationID != "") {
            appState = showLOADING;
            updateWeatherData();
        }
    }

    onRainUnitsChoiceChanged: {
        printDebug("Rain Units changed");

        if (stationID != "") {
            appState = showLOADING;
            updateWeatherData();
        }
    }

    onSnowUnitsChoiceChanged: {
        printDebug("Snow Units changed");

        if (stationID != "") {
            appState = showLOADING;
            updateWeatherData();
        }
    }

    onPresUnitsChoiceChanged: {
        printDebug("Pres Units changed");

        if (stationID != "") {
            appState = showLOADING;
            updateWeatherData();
        }
    }

    onUseLegacyAPIChanged: {
        printDebug("Forecast API changed");

        if (stationID != "") {
            updateForecastData();
        }
    }

    onWeatherDataChanged: {
        printDebug("Weather data changed");
    }

    onAppStateChanged: {
        printDebug("State is: " + appState);
    }

    Component.onCompleted: {
        // Plasma::Containment::Type::CustomEmbedded = 129
        // Plasma::Types::FormFactor::Horizonal = 2
        inTray = plasmoid.containment.containmentType == 129 && plasmoid.formFactor == 2;
        plasmoid.configurationRequiredReason = i18n("Set the weather station to pull data from.");
        plasmoid.backgroundHints = PlasmaCore.Types.ConfigurableBackground;
    }

    Timer {
        interval: plasmoid.configuration.refreshPeriod * 1000
        running: appState != showCONFIG
        repeat: true
        onTriggered: updateCurrentData()
    }

    Timer {
        interval: 60 * 60 * 1000
        running: appState != showCONFIG
        repeat: true
        onTriggered: updateForecastData()
    }

    toolTipTextFormat: Text.RichText
    toolTipMainText: {
        if (appState == showCONFIG) {
            return i18n("Please Configure");
        } else if (appState == showDATA) {
            return stationID;
        } else if (appState == showLOADING) {
            return i18n("Loading...");
        } else if (appState == showERROR) {
            return i18n("Error...");
        }
    }
    toolTipSubText: {
        var subText = "";
        if (appState == showDATA) {
            subText += i18nc("Do not edit HTML tags. 'Temp' means temperature", "<font size='4'>Temp: %1</font><br />", Utils.currentTempUnit(Utils.toUserTemp(weatherData["details"]["temp"]),plasmoid.configuration.tempPrecision));
            subText += i18nc("Do not edit HTML tags.", "<font size='4'>Feels: %1</font><br />", Utils.currentTempUnit(Utils.feelsLike(weatherData["details"]["temp"], weatherData["humidity"], weatherData["details"]["windSpeed"]), plasmoid.configuration.feelsPrecision));
            subText += i18nc("Do not edit HTML tags. 'Wnd Spd' means Wind Speed", "<font size='4'>Wnd spd: %1</font><br />", Utils.currentSpeedUnit(Utils.toUserSpeed(weatherData["details"]["windSpeed"])));
            subText += "<font size='4'>" + weatherData["obsTimeLocal"] + "</font>";
        } else if (appState == showERROR) {
            subText = errorStr;
        }
        return subText;
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh weather")
            icon.name: "view-refresh-symbolic"
            // icon.color: Kirigami.Theme.textColor
            visible: appState == showDATA
            enabled: appState == showDATA
            onTriggered: updateWeatherData()
        }
    ]

    // preferredRepresentation: compactRepresentation
    fullRepresentation: fr
    compactRepresentation: cr
}
