/*
 * Copyright 2026  Kevin Donnelly
 * Copyright 2022  Rafal (Raf) Liwoch
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
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import "../code/utils.js" as Utils
import "lib" as Lib

ColumnLayout {
    id: detailsRoot

    property string iconNameStr: Utils.getConditionIcon(root.iconCode, plasmoid.configuration.useSystemThemeIcons)
    property string sunrise: weatherData["sunrise"]
    property string sunset: weatherData["sunset"]
    property bool showTimeSeconds: plasmoid.configuration.showTimeSeconds

    Timer {
        id: sunTimer
        running: appState === showDATA
        repeat: true
        interval: 60 * 1000
        
        onTriggered: {
            dayLength.text = Utils.getDayLength(weatherData["sunrise"],weatherData["sunset"], showTimeSeconds)
            dayLightCaption.text = Utils.remainingUntilSinceDaylight(weatherData["sunrise"],weatherData["sunset"], showTimeSeconds)
            circularSlider.value = Utils.calculateNeedlePosition(weatherData["sunrise"],weatherData["sunset"])
        }
    }

    onSunriseChanged: {
        sunTimer.triggered()
    }

    onSunsetChanged: {
        sunTimer.triggered()
    }

    onShowTimeSecondsChanged: {
        sunTimer.triggered()
    }

    // Top row: three columns
    RowLayout {
        Layout.preferredWidth: parent.width
        uniformCellSizes: true

        // Left: Sunrise and set times with total light time and time remaining
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            PlasmaComponents.Label {
                id: dayLength
                text: "day length"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter

                ColumnLayout {
                    PlasmaComponents.Label {
                        text: "\uF05E"
                        font.family: "weather-icons"
                        font.pixelSize: Kirigami.Units.iconSizes.medium
                    }

                    PlasmaComponents.Label {
                        text: Qt.formatDateTime(weatherData["sunrise"], plasmoid.configuration.sunMoonTimeFormat)
                        font.pointSize: plasmoid.configuration.propPointSize
                        font.bold: true
                    }
                }

                Lib.CircularSlider {
                    id: circularSlider

                    Layout.alignment: Qt.AlignCenter

                    rotation: 270

                    Layout.preferredHeight: Kirigami.Units.iconSizes.large
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large

                    trackWidth: Kirigami.Units.iconSizes.small/8
                    progressWidth: 2
                    handleWidth: Kirigami.Units.iconSizes.small/1.5
                    handleHeight: handleWidth
                    handleRadius: 10
                    handleVerticalOffset: 0

                    startAngle: 0
                    endAngle: 180
                    minValue: 0
                    maxValue: 100
                    snap: false
                    stepSize: 1
                    value: Utils.calculateNeedlePosition(weatherData["sunrise"],weatherData["sunset"]) 

                    handleColor: "#FDBE3B"
                    trackColor: "grey"
                    progressColor: "#FDBE3B"

                    hideTrack: false
                    hideProgress: false

                    interactive: true
                }

                ColumnLayout {
                    PlasmaComponents.Label {
                        text: "\uF05D"
                        font.family: "weather-icons"
                        font.pixelSize: Kirigami.Units.iconSizes.medium
                    }

                    PlasmaComponents.Label {
                        text: Qt.formatDateTime(weatherData["sunset"], plasmoid.configuration.sunMoonTimeFormat)
                        font.pointSize: plasmoid.configuration.propPointSize
                        font.bold: true
                    }
                }
            }

            PlasmaComponents.Label {
                id: dayLightCaption
                text: "day remaining"
                font.pointSize: plasmoid.configuration.propPointSize
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }
        }

        // Center: Condition icon left of current temp, feels like, condition blurb
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            PlasmaComponents.Label {
                visible: !plasmoid.configuration.useSystemThemeIcons
                text: iconNameStr
                font.family: "weather-icons"
                font.pixelSize: Kirigami.Units.iconSizes.huge
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }


            Kirigami.Icon {
                source: detailsRoot.iconNameStr
                visible: plasmoid.configuration.useSystemThemeIcons
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
            }


            ColumnLayout {
                PlasmaComponents.Label {
                    text: Utils.currentTempUnit(Utils.toUserTemp(weatherData["details"]["temp"]), plasmoid.configuration.tempPrecision)
                    font {
                        bold: true
                        pointSize: plasmoid.configuration.tempPointSize
                    }
                    color: plasmoid.configuration.tempAutoColor ? Utils.heatColor(weatherData["details"]["temp"], Kirigami.Theme.backgroundColor) : Kirigami.Theme.textColor
                }
                PlasmaComponents.Label {
                    text: i18n("Feels like %1", Utils.currentTempUnit(Utils.feelsLike(weatherData["details"]["temp"], weatherData["humidity"], weatherData["details"]["windSpeed"]), plasmoid.configuration.feelsPrecision))
                    font {
                        bold: true
                        pointSize: plasmoid.configuration.propPointSize
                    }
                }
                PlasmaComponents.Label {
                    text: conditionNarrative
                    font.pointSize: plasmoid.configuration.propPointSize
                }
            }
        }

        // Right: Moon rise and set times and phase
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter

                ColumnLayout {
                    PlasmaComponents.Label {
                        text: "\uF060"
                        font.family: "weather-icons"
                        font.pixelSize: Kirigami.Units.iconSizes.medium
                    }

                    PlasmaComponents.Label {
                        text: Qt.formatDateTime(weatherData["moonrise"], plasmoid.configuration.sunMoonTimeFormat)
                        font.pointSize: plasmoid.configuration.propPointSize
                        font.bold: true
                    }
                }

                PlasmaComponents.Label {
                    text: Utils.getMoonPhaseIcon(weatherData["moonPhaseCode"])
                    font.family: "weather-icons"
                    font.pixelSize: Kirigami.Units.iconSizes.medium
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignCenter
                }

                ColumnLayout {
                    PlasmaComponents.Label {
                        text: "\uF05F"
                        font.family: "weather-icons"
                        font.pixelSize: Kirigami.Units.iconSizes.medium
                    }

                    PlasmaComponents.Label {
                        text: Qt.formatDateTime(weatherData["moonset"], plasmoid.configuration.sunMoonTimeFormat)
                        font.pointSize: plasmoid.configuration.propPointSize
                        font.bold: true
                    }
                }
            }

            PlasmaComponents.Label {
                text: weatherData["moonPhase"]
                font.pointSize: plasmoid.configuration.propPointSize
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    PlasmaComponents.Label {
        text: weatherData["blurb"]
        visible: plasmoid.configuration.showBlurb
        font.pointSize: plasmoid.configuration.propPointSize
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
    }

    // Below: 2 row by 4 column grid of current conditions
    GridLayout {
        columns: 4
        rows: 2
        Layout.preferredWidth: parent.width
        uniformCellWidths: true
        uniformCellHeights: true

        // Wind
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Kirigami.Icon {
                id: topPanelIcon

                source: Utils.getWindBarbIcon(weatherData["details"]["windSpeed"])

                isMask: true
                color: Kirigami.Theme.textColor

                // wind barb icons are 270 degrees deviated from 0 degrees (north)
                rotation: weatherData["winddir"] - 270

                Layout.minimumWidth: plasmoid.configuration.propIconSize
                Layout.minimumHeight: plasmoid.configuration.propIconSize
                Layout.preferredWidth: Layout.minimumWidth
                Layout.preferredHeight: Layout.minimumHeight
                Layout.alignment: Qt.AlignCenter

                PlasmaCore.ToolTipArea {
                    anchors.fill: parent

                    interactive: true
                    mainText: i18n("Wind Barb")
                    subText: i18n("Wind direction and speed indicator")

                    mainItem: PlasmaComponents.Control {
                        implicitWidth: Math.max(implicitBackgroundWidth + leftPadding + rightPadding,
                                    implicitContentWidth + leftPadding + rightPadding)
                        implicitHeight: Math.max(implicitBackgroundHeight + topPadding + bottomPadding,
                                    implicitContentHeight + topPadding + bottomPadding)
                        
                        padding: Kirigami.Units.smallSpacing
                        
                        contentItem: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing
                            
                            PlasmaComponents.Label {
                                text: i18n("Wind Barb")
                                font.bold: true
                            }
                            
                            PlasmaComponents.Label {
                                text: i18n("Wind direction and speed indicator")
                                wrapMode: Text.WordWrap
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                            
                            PlasmaComponents.Button {
                                text: i18n("Learn more")
                                onClicked: Qt.openUrlExternally("https://en.wikipedia.org/wiki/Station_model#Plotted_winds")
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
            PlasmaComponents.Label {
                text: i18n("Wind from: %1 (%2°)", Utils.windDirToCard(weatherData["winddir"]), weatherData["winddir"])
                font.pointSize: plasmoid.configuration.propHeadPointSize
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: Utils.toUserSpeed(weatherData["details"]["windSpeed"]).toFixed(plasmoid.configuration.windPrecision) + " " + Utils.rawSpeedUnit()
                font {
                    bold: true
                    pointSize: plasmoid.configuration.propPointSize
                }
                Layout.alignment: Qt.AlignCenter
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            PlasmaComponents.Label {
                text: "\uF03F"
                font.family: "weather-icons"
                font.pixelSize: plasmoid.configuration.propIconSize
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: i18n("Wind & Gust")
                font.pointSize: plasmoid.configuration.propHeadPointSize
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: Utils.toUserSpeed(weatherData["details"]["windSpeed"]).toFixed(plasmoid.configuration.windPrecision) + " / " + Utils.currentSpeedUnit(Utils.toUserSpeed(weatherData["details"]["windGust"]), plasmoid.configuration.windPrecision)
                font {
                    bold: true
                    pointSize: plasmoid.configuration.propPointSize
                }
                Layout.alignment: Qt.AlignCenter
            }
        }

        // Dew Point
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            PlasmaComponents.Label {
                text: "\uF05C"
                font.family: "weather-icons"
                font.pixelSize: plasmoid.configuration.propIconSize
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: i18n("Dew Point")
                font.pointSize: plasmoid.configuration.propHeadPointSize
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: Utils.currentTempUnit(Utils.toUserTemp(weatherData["details"]["dewpt"]), plasmoid.configuration.dewPrecision)
                font {
                    bold: true
                    pointSize: plasmoid.configuration.propPointSize
                }
                Layout.alignment: Qt.AlignCenter
            }
        }

        // Precipitation Rate
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            PlasmaComponents.Label {
                text: "\uF04C"
                font.family: "weather-icons"
                font.pixelSize: plasmoid.configuration.propIconSize
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: i18n("Precip Rate")
                font.pointSize: plasmoid.configuration.propHeadPointSize
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: Utils.currentPrecipUnit(Utils.toUserPrecip(weatherData["details"]["precipRate"], isRain), isRain) + "/hr"
                font {
                    bold: true
                    pointSize: plasmoid.configuration.propPointSize
                }
                Layout.alignment: Qt.AlignCenter
            }
        }

        // Pressure
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            PlasmaComponents.Label {
                text: "\uF00A"
                font.family: "weather-icons"
                font.pixelSize: plasmoid.configuration.propIconSize
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: i18n("Pressure")
                font.pointSize: plasmoid.configuration.propHeadPointSize
                Layout.alignment: Qt.AlignCenter
            }
            Row {
                PlasmaComponents.Label {
                    id: pressure
                    text: Utils.currentPresUnit(Utils.toUserPres(weatherData["details"]["pressure"]))
                    font {
                        pointSize: plasmoid.configuration.propPointSize
                        bold: true
                    }
                }
                Kirigami.Icon {
                    source: Utils.getPressureTrendIcon(weatherData["details"]["pressureTrendCode"])

                    visible: plasmoid.configuration.showPresTrend

                    height: Kirigami.Units.iconSizes.small

                    PlasmaCore.ToolTipArea {
                        anchors.fill: parent

                        mainText: weatherData["details"]["pressureTrend"]
                        subText: {
                            var userPres = Utils.toUserPres(weatherData["details"]["pressureDelta"]);
                            var absDelta = Math.abs(userPres);
                            var fullStr = Utils.currentPresUnit(absDelta);
                            var hasIncreased = Utils.hasPresIncreased(weatherData["details"]["pressureTrendCode"]);
                            if (hasIncreased) {
                                return i18n("Pressure has risen %1 in the last three hours.", fullStr);
                            } else {
                                return i18n("Pressure has fallen %1 in the last three hours.", fullStr);
                            }
                        }
                    }
                }
            }
        }

        // Humidity
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            PlasmaComponents.Label {
                text: "\uF008"
                font.family: "weather-icons"
                font.pixelSize: plasmoid.configuration.propIconSize
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: i18n("Humidity")
                font.pointSize: plasmoid.configuration.propHeadPointSize
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: weatherData["humidity"] + "%"
                font {
                    bold: true
                    pointSize: plasmoid.configuration.propPointSize
                }
                Layout.alignment: Qt.AlignCenter
            }
        }

        // Precipitation Accumulation
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            PlasmaComponents.Label {
                text: "\uF062"
                font.family: "weather-icons"
                font.pixelSize: plasmoid.configuration.propIconSize
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: i18n("Precip Accum")
                font.pointSize: plasmoid.configuration.propHeadPointSize
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: Utils.currentPrecipUnit(Utils.toUserPrecip(weatherData["details"]["precipTotal"], isRain), isRain)
                font {
                    bold: true
                    pointSize: plasmoid.configuration.propPointSize
                }
                Layout.alignment: Qt.AlignCenter
            }
        }

        // UV
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            PlasmaComponents.Label {
                text: "\uF061"
                font.family: "weather-icons"
                font.pixelSize: plasmoid.configuration.propIconSize
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: i18n("UV")
                font.pointSize: plasmoid.configuration.propHeadPointSize
                Layout.alignment: Qt.AlignCenter
            }
            PlasmaComponents.Label {
                text: weatherData["uv"]
                font {
                    bold: true
                    pointSize: plasmoid.configuration.propPointSize
                }
                Layout.alignment: Qt.AlignCenter
            }
        }
    }
}
