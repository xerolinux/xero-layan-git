/*
 * Copyright 2026  Kevin Donnelly
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
import org.kde.plasma.core as PlasmaCore
import "../code/utils.js" as Utils
import "../code/pws-api.js" as StationAPI

PlasmoidItem {
    id: root

    FontLoader {
        source: "../fonts/weather-icons.ttf"
    }

    property var weatherData: ({
            "stationID": "KSTAT100",
            "neighborhood": "Place name",
            "uv": 0,
            "obsTimeLocal": "2020-08-09T10:11:10-0500",
            "isNight": false,
            "winddir": 0,
            "latitude": 0,
            "longitude": 0,
            "sunrise": "2020-08-09T07:00:10-0500",
            "sunset": "2020-08-09T20:00:10-0500",
            "solarRad": 0,
            "humidity": 0,
            "moonrise": "2020-08-09T20:00:10-0500",
            "moonset": "2020-08-10T04:00:10-0500",
            "moonPhase": "Full Moon",
            "moonPhaseCode": "F",
            "blurb": "AAAAAAAAAAAAAAAAAAAAAA",
            "kp-index": 0,
            "kp-health": 0,
            "kp-color": "#00FF00",
            "cloudCover": 0,
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
                },
                "messages": {
                    "general": {
                        "title": "major",
                        "phrase": "major details"
                    },
                    "sensitive": {
                        "title": "minor",
                        "phrase": "minor details"
                    }
                }
            }
        })
    property ListModel forecastModel: ListModel {}
    property ListModel hourlyModel: ListModel {}
    property ListModel alertsModel: ListModel {}
    property ListModel kpPredictionsModel: ListModel {}
    property int currDayHigh: 0
    property int currDayLow: 0
    property int iconCode: 32 // 32 = sunny
    property string conditionNarrative: ""

    property string errorStr: ""
    property string errorType: ""

    property int showCONFIG: 1
    property int showLOADING: 2
    property int showERROR: 4
    property int showDATA: 8

    property int appState: showCONFIG

    property bool showForecast: false

    property string stationID: plasmoid.configuration.stationID
    property int unitsChoice: plasmoid.configuration.unitsChoice
    property int tempUnitsChoice: plasmoid.configuration.tempUnitsChoice
    property int windUnitsChoice: plasmoid.configuration.windUnitsChoice
    property int rainUnitsChoice: plasmoid.configuration.rainUnitsChoice
    property int snowUnitsChoice: plasmoid.configuration.snowUnitsChoice
    property int presUnitsChoice: plasmoid.configuration.presUnitsChoice
    property bool useLegacyAPI: plasmoid.configuration.useLegacyAPI

    property int layoutType: plasmoid.configuration.layoutType
    property int widgetOrder: plasmoid.configuration.widgetOrder
    property int planarLayoutType: plasmoid.configuration.planarLayoutType
    property int iconSizeMode: plasmoid.configuration.iconSizeMode
    property int textSizeMode: plasmoid.configuration.textSizeMode

    property bool inTray: false
    // Metric units change based on precipitation type
    property bool isRain: true

    property bool hasLoaded: false

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
            uvIndex: -999
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
            uvIndex: 5
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
            }
        })

    property Component fr: FullRepresentation {
        Layout.preferredWidth: 650
        Layout.preferredHeight: 480
    }
    property Component cr: CompactRepresentation {}
    property Component crInTray: CompactRepresentationInTray {}

    property bool vertical: plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool onDesktop: (plasmoid.location === PlasmaCore.Types.Desktop || plasmoid.location === PlasmaCore.Types.Floating)

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

    function delay(delayTime, cb) {
        function Timer() {
            return Qt.createQmlObject("import QtQuick; Timer {}", root);
        }
        var timer = new Timer();
        timer.interval = delayTime;
        timer.repeat = false;
        timer.triggered.connect(cb);
        timer.triggered.connect(function release() {
            timer.triggered.disconnect(cb);
            timer.triggered.disconnect(release);
        });
        timer.start();
    }

    function updateWeatherData() {
        printDebug("Getting new weather data");
        var delayPeriod = hasLoaded ? 0 : plasmoid.configuration.startupDelay * 1000;
        delay(delayPeriod, function () {
            printDebug("Delayed startup " + (plasmoid.configuration.startupDelay) + " s.");

            StationAPI.getCurrentData({
                stationID: stationID,
                unitsChoice: unitsChoice,
                oldWeatherData: weatherData
            }, function (err, curRes) {
                if (err) {
                    errorStr = err.message || JSON.stringify(err);
                    errorType = err.type || JSON.stringify(err);
                    printDebug(errorStr);
                    appState = showERROR;
                    return;
                }

                // Apply current data
                weatherData = curRes.weatherData;
                plasmoid.configuration.latitude = curRes.configUpdates.latitude;
                plasmoid.configuration.longitude = curRes.configUpdates.longitude;
                printDebug("Got new current data");

                // Fetch extended conditions for the same location
                StationAPI.getExtendedConditions({
                    latitude: plasmoid.configuration.latitude,
                    longitude: plasmoid.configuration.longitude,
                    unitsChoice: unitsChoice,
                    oldWeatherData: weatherData,
                    language: Qt.locale().name.replace("_", "-")
                }, function (err2, extRes) {
                    if (err2) {
                        printDebug("Extended conditions failed: " + (err2.message || JSON.stringify(err2)));
                        // Do not proceed to forecast if extended conditions fail (preserves previous behaviour)
                        return;
                    }

                    // Apply extended conditions
                    iconCode = extRes.iconCode || iconCode;
                    conditionNarrative = extRes.conditionNarrative || conditionNarrative;
                    isRain = extRes.isRain;

                    alertsModel.clear();
                    if (extRes.alerts && extRes.alerts.length) {
                        for (var ai = 0; ai < extRes.alerts.length; ai++)
                            alertsModel.append(extRes.alerts[ai]);
                    }

                    // Merge extended info into weatherData
                    var merged = JSON.parse(JSON.stringify(weatherData));
                    merged.isNight = extRes.isNight;
                    merged.sunrise = extRes.sunriseTimeLocal;
                    merged.sunset = extRes.sunsetTimeLocal;
                    merged.cloudCover = extRes.cloudCover;
                    merged.details = merged.details || {};
                    merged.details.pressureTrend = extRes.pressureTendencyTrend;
                    merged.details.pressureTrendCode = extRes.pressureTendencyCode;
                    merged.details.pressureDelta = extRes.pressureDelta;
                    merged.aq = extRes.airQuality || merged.aq;
                    weatherData = merged;

                    // Fetch forecast now that extended conditions are available
                    StationAPI.getForecastData({
                        latitude: plasmoid.configuration.latitude,
                        longitude: plasmoid.configuration.longitude,
                        unitsChoice: unitsChoice,
                        useLegacyAPI: useLegacyAPI,
                        language: Qt.locale().name.replace("_", "-")
                    }, function (err3, fcRes) {
                        if (err3) {
                            errorStr = err3.message || JSON.stringify(err3);
                            errorType = err3.type || JSON.stringify(err3);
                            printDebug(errorStr);
                            appState = showERROR;
                            return;
                        }

                        forecastModel.clear();
                        for (var i = 0; i < fcRes.forecast.length; i++) {
                            forecastModel.append(fcRes.forecast[i]);
                        }
                        currDayHigh = fcRes.currDayHigh;
                        currDayLow = fcRes.currDayLow;
                        var updated = JSON.parse(JSON.stringify(weatherData));
                        updated.moonrise = fcRes.moonrise || updated.moonrise;
                        updated.moonset = fcRes.moonset || updated.moonset;
                        updated.moonPhase = fcRes.moonPhase || updated.moonPhase;
                        updated.moonPhaseCode = fcRes.moonPhaseCode || updated.moonPhaseCode;
                        updated.blurb = fcRes.blurb || updated.blurb;
                        weatherData = updated;

                        printDebug("Got new forecast data");
                        showForecast = true;

                        // Fetch hourly data after forecast is populated
                        StationAPI.getHourlyData({
                            latitude: plasmoid.configuration.latitude,
                            longitude: plasmoid.configuration.longitude,
                            unitsChoice: unitsChoice,
                            language: Qt.locale().name.replace("_", "-")
                        }, function (err4, hrRes) {
                            if (err4) {
                                errorStr = err4.message || JSON.stringify(err4);
                                errorType = err4.type || JSON.stringify(err4);
                                printDebug(errorStr);
                                appState = showERROR;
                                return;
                            }

                            hourlyModel.clear();
                            for (var h = 0; h < hrRes.hourly.length; h++)
                                hourlyModel.append(hrRes.hourly[h]);
                            // update the chart metadata
                            maxValDict = hrRes.maxValDict;
                            rangeValDict = hrRes.rangeValDict;

                            printDebug("Got hourly data");

                            // Fetch KP index data
                            StationAPI.getKpIndexData(function (err, kpRes) {
                                if (err) {
                                    printDebug("KP index fetch failed: " + err.message);
                                } else {
                                    var updated = JSON.parse(JSON.stringify(weatherData));
                                    updated["kp-index"] = kpRes.current;
                                    var tempC = Math.abs(Utils.apiTempToC(weatherData["details"]["temp"] - 20));
                                    var deltaPHpa = Utils.apiPresToHpa(weatherData["details"]["pressureDelta"]);
                                    var kpComp = Math.min(1, Math.max(0, (updated["kp-index"] - 2) / 6));
                                    var presComp = Math.min(1, Math.abs(deltaPHpa) / 10);
                                    var tempComp = Math.min(1, Math.abs(tempC - 20) / 20);
                                    updated["kp-health"] = 10 * (0.35 * updated["kp-index"] + 0.4 * presComp + 0.25 * tempComp);
                                    updated["kp-color"] = updated["kp-health"] <= 4 ? "#00FF00" : updated["kp-health"] <= 7 ? "#FFFF00" : "#FF0000";

                                    kpPredictionsModel.clear();
                                    for (var p = 0; p < kpRes.predictions.length; p++) {
                                        kpPredictionsModel.append(kpRes.predictions[p]);
                                    }

                                    weatherData = updated;
                                    printDebug("Got KP index data");
                                }
                            });
                        });
                    });
                });

                appState = showDATA;
            });

            hasLoaded = true;
        });
    }

    function updateCurrentData() {
        printDebug("Getting new current data");
        StationAPI.getCurrentData({
            stationID: stationID,
            unitsChoice: unitsChoice,
            oldWeatherData: weatherData
        }, function (err, curRes) {
            if (err) {
                errorStr = err.message || JSON.stringify(err);
                errorType = err.type || JSON.stringify(err);
                appState = showERROR;
                printDebug(errorStr);
                return;
            }
            weatherData = curRes.weatherData;
            printDebug("Got new current data");

            // Fetch KP index data
            StationAPI.getKpIndexData(function (err, kpRes) {
                if (err) {
                    printDebug("KP index fetch failed: " + err.message);
                } else {
                    var updated = JSON.parse(JSON.stringify(weatherData));
                    updated["kp-index"] = kpRes.current;
                    var tempC = Math.abs(Utils.apiTempToC(weatherData["details"]["temp"] - 20));
                    var deltaPHpa = Utils.apiPresToHpa(weatherData["details"]["pressureDelta"]);
                    var kpComp = Math.min(1, Math.max(0, (updated["kp-index"] - 2) / 6));
                    var presComp = Math.min(1, Math.abs(deltaPHpa) / 10);
                    var tempComp = Math.min(1, Math.abs(tempC - 20) / 20);
                    updated["kp-health"] = 10 * (0.35 * updated["kp-index"] + 0.4 * presComp + 0.25 * tempComp);
                    updated["kp-color"] = updated["kp-health"] <= 4 ? "#00FF00" : updated["kp-health"] <= 7 ? "#FFFF00" : "#FF0000";

                    kpPredictionsModel.clear();
                    for (var p = 0; p < kpRes.predictions.length; p++) {
                        kpPredictionsModel.append(kpRes.predictions[p]);
                    }

                    weatherData = updated;
                    printDebug("Got KP index data");
                }
            });
            appState = showDATA;
        });
    }

    function updateForecastData() {
        printDebug("Getting new forecast data");
        StationAPI.getExtendedConditions({
            latitude: plasmoid.configuration.latitude,
            longitude: plasmoid.configuration.longitude,
            unitsChoice: unitsChoice,
            oldWeatherData: weatherData,
            language: Qt.locale().name.replace("_", "-")
        }, function (err, extRes) {
            if (err) {
                printDebug("Extended conditions fetch failed: " + (err.message || JSON.stringify(err)));
                return;
            }

            // Apply extended conditions similar to updateWeatherData
            iconCode = extRes.iconCode || iconCode;
            conditionNarrative = extRes.conditionNarrative || conditionNarrative;
            isRain = extRes.isRain;
            alertsModel.clear();
            if (extRes.alerts && extRes.alerts.length) {
                for (var ai = 0; ai < extRes.alerts.length; ai++)
                    alertsModel.append(extRes.alerts[ai]);
            }
            var merged = JSON.parse(JSON.stringify(weatherData));
            merged.isNight = extRes.isNight;
            merged.sunrise = extRes.sunriseTimeLocal || merged.sunrise;
            merged.sunset = extRes.sunsetTimeLocal || merged.sunset;
            merged.cloudCover = extRes.cloudCover || merged.cloudCover;
            merged.details = merged.details || {};
            merged.details.pressureTrend = extRes.pressureTendencyTrend || merged.details.pressureTrend;
            merged.details.pressureTrendCode = extRes.pressureTendencyCode || merged.details.pressureTrendCode;
            merged.details.pressureDelta = extRes.pressureDelta || merged.details.pressureDelta;
            merged.aq = extRes.airQuality || merged.aq;
            weatherData = merged;

            StationAPI.getForecastData({
                latitude: plasmoid.configuration.latitude,
                longitude: plasmoid.configuration.longitude,
                unitsChoice: unitsChoice,
                useLegacyAPI: useLegacyAPI,
                language: Qt.locale().name.replace("_", "-")
            }, function (err2, fcRes) {
                if (err2) {
                    errorStr = err2.message || JSON.stringify(err2);
                    errorType = err2.type || JSON.stringify(err2);
                    printDebug(errorStr);
                    appState = showERROR;
                    return;
                }

                forecastModel.clear();
                for (var k = 0; k < fcRes.forecast.length; k++)
                    forecastModel.append(fcRes.forecast[k]);
                currDayHigh = fcRes.currDayHigh;
                currDayLow = fcRes.currDayLow;
                var updated = JSON.parse(JSON.stringify(weatherData));
                updated.moonrise = fcRes.moonrise || updated.moonrise;
                updated.moonset = fcRes.moonset || updated.moonset;
                updated.moonPhase = fcRes.moonPhase || updated.moonPhase;
                updated.moonPhaseCode = fcRes.moonPhaseCode || updated.moonPhaseCode;
                updated.blurb = fcRes.blurb || updated.blurb;
                weatherData = updated;
                printDebug("Got new forecast data");
                showForecast = true;

                StationAPI.getHourlyData({
                    latitude: plasmoid.configuration.latitude,
                    longitude: plasmoid.configuration.longitude,
                    unitsChoice: unitsChoice,
                    language: Qt.locale().name.replace("_", "-")
                }, function (err3, hrRes) {
                    if (err3) {
                        errorStr = err3.message || JSON.stringify(err3);
                        errorType = err3.type || JSON.stringify(err3);
                        printDebug(errorStr);
                        appState = showERROR;
                        return;
                    }
                    hourlyModel.clear();
                    for (var hh = 0; hh < hrRes.hourly.length; hh++)
                        hourlyModel.append(hrRes.hourly[hh]);
                    maxValDict = hrRes.maxValDict;
                    rangeValDict = hrRes.rangeValDict;

                    printDebug("Got hourly data");

                    // Fetch KP index data
                    StationAPI.getKpIndexData(function (err, kpRes) {
                        if (err) {
                            printDebug("KP index fetch failed: " + err.message);
                        } else {
                            var updated = JSON.parse(JSON.stringify(weatherData));
                            updated["kp-index"] = kpRes.current;
                            var calcTemp = Utils.apiTempToC(weatherData["details"]["temp"]);
                            var calcDeltaP = Utils.apiPresToHpa(weatherData["details"]["pressureDelta"]);
                            updated["kp-health"] = 10 - (0.35 * updated["kp-index"] + 0.4 * calcDeltaP + 0.25 * calcTemp);
                            updated["kp-color"] = updated["kp-health"] >= 7 ? "#00FF00" : updated["kp-health"] >= 4 ? "#FFFF00" : "#FF0000";

                            kpPredictionsModel.clear();
                            for (var p = 0; p < kpRes.predictions.length; p++) {
                                kpPredictionsModel.append(kpRes.predictions[p]);
                            }
                            
                            weatherData = updated;
                            printDebug("Got KP index data");
                        }
                    });
                });
            });
        });
    }

    onStationIDChanged: {
        printDebug("Station ID changed");

        if (stationID != "") {
            // Show loading screen after ID change
            appState = showLOADING;
            updateWeatherData();
        } else if (stationID == "") {
            appState = showCONFIG;
        }
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
        plasmoid.backgroundHints = PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground;

        if (plasmoid.configuration.refreshPeriod < 300) {
            plasmoid.configuration.refreshPeriod = 300;
        }
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
            return plasmoid.configuration.shownInTooltip == 0 ? weatherData["stationID"] :
                   plasmoid.configuration.shownInTooltip == 1 ? plasmoid.configuration.stationName :
                   plasmoid.configuration.stationName + "\n" + weatherData["stationID"];
        } else if (appState == showLOADING) {
            return i18n("Loading...");
        } else if (appState == showERROR) {
            return i18n("Error...");
        }
    }
    toolTipSubText: {
        var subText = "";
        if (appState == showDATA) {
            var windDir = weatherData["winddir"];
            var windSpd = Utils.currentSpeedUnit(Utils.toUserSpeed(weatherData["details"]["windSpeed"]), plasmoid.configuration.windPrecision);
            var temp = Utils.currentTempUnit(Utils.toUserTemp(weatherData["details"]["temp"]), plasmoid.configuration.tempPrecision);
            var pres = Utils.currentPresUnit(Utils.toUserPres(weatherData["details"]["pressure"]), 2);
            subText += weatherData["obsTimeLocal"];
            subText += "<br /><br />";
            subText += "<font size=\"8\" style=\"font-family: weather-icons;\">" + Utils.getConditionIcon(iconCode) + "</font>&nbsp;&nbsp;<font size=\"8\"><b>" + temp + "</b></font>";
            subText += "<br /><br />";
            subText += "<font size=\"4\" style=\"font-family: weather-icons;\">" + Utils.getConditionIcon("wind@2") + "</font><font size=\"4\">" + windDir + "°&nbsp;&nbsp;@&nbsp;" + windSpd + "</font>";
            subText += "<br />";
            subText += "<font size=\"4\" style=\"font-family: weather-icons;\">" + Utils.getConditionIcon("humidity@2") + "</font><font size=\"4\">" + weatherData["humidity"] + "%</font>";
            subText += "&nbsp;&nbsp;";
            subText += "<font size=\"4\" style=\"font-family: weather-icons;\">" + Utils.getConditionIcon("cloudCover@2") + "</font><font size=\"4\">" + weatherData["cloudCover"] + "%</font>";
            subText += "<br />";
            subText += "<font size=\"4\" style=\"font-family: weather-icons;\">" + Utils.getConditionIcon("pressure@2") + "</font>&nbsp;<font size=\"4\">" + pres + "</font>";
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

    fullRepresentation: planarLayoutType === 0 ? fr : cr
    compactRepresentation: inTray ? crInTray : cr
}
