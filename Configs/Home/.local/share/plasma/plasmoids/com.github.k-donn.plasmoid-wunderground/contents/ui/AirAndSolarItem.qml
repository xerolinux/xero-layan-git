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

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

RowLayout {

    TextMetrics {
        id: aqIndexTxt

        text: weatherData["aq"]["aqDesc"]
    }

    TextMetrics {
        id: solStatusTxt

        text: {
            var val = Math.round(weatherData["kp-health"]);
            if (val < 4) {
                return i18n("Comfortable");
            } else if (val < 7) {
                return i18n("Moderate");
            } else {
                return i18n("Unfavorable");
            }
        }
    }

    GridLayout {
        id: aqGrid

        columns: 2
        rows: 4

        Layout.preferredWidth: 1
        Layout.fillWidth: true

        uniformCellWidths: true

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

        Rectangle {
            id: aqIndexColor

            Layout.preferredWidth: aqIndexTxt.width + 5
            Layout.preferredHeight: aqIndexTxt.height + 5
            Layout.alignment: Qt.AlignCenter
            Layout.columnSpan: 2

            color: "#" + weatherData["aq"]["aqColor"]

            radius: 5

            PlasmaComponents.Label {
                id: aqIndexLabel

                anchors.centerIn: parent

                color: "#000000"

                text: weatherData["aq"]["aqDesc"]
            }
        }


        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                text: "\uF06B"
                font.family: "weather-icons"
                font.pixelSize: Kirigami.Units.iconSizes.medium
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize

                text: i18nc("Air Quality Index","AQI")
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize
                font.bold: true

                text: weatherData["aq"]["aqi"]
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                text: "\uF06E"
                font.family: "weather-icons"
                font.pixelSize: Kirigami.Units.iconSizes.medium
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize

                text: i18nc("Air Quality Health Index", "AQHI")
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize
                font.bold: true

                text: weatherData["aq"]["aqhi"]
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                text: "\uF06F"
                font.family: "weather-icons"
                font.pixelSize: Kirigami.Units.iconSizes.medium
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize

                text: weatherData["aq"]["aqPrimary"]
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize
                font.bold: true

                text: weatherData["aq"]["primaryDetails"]["amount"] + " " + weatherData["aq"]["primaryDetails"]["unit"]
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Kirigami.Icon {
                source: "documentinfo-symbolic"
                width: Kirigami.Units.iconSizes.medium
                height: Kirigami.Units.iconSizes.medium
                Layout.alignment: Qt.AlignHCenter
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize

                text: i18n("Alerts")
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize
                font.bold: true
                font.underline: true

                text: i18n("Info")

                PlasmaCore.ToolTipArea {
                    anchors.fill: parent

                    interactive: true

                    mainItem: Item {
                        implicitWidth: Kirigami.Units.gridUnit * 15
                        implicitHeight: aqInfoLayout.implicitHeight + Kirigami.Units.gridUnit * 2
                        
                        ColumnLayout {
                            id: aqInfoLayout

                            anchors.fill: parent

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: weatherData["aq"]["messages"]["general"]["title"]
                                font.bold: true
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: weatherData["aq"]["messages"]["general"]["phrase"]
                                wrapMode: Text.WordWrap
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: weatherData["aq"]["messages"]["sensitive"]["title"]
                                font.bold: true
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: weatherData["aq"]["messages"]["sensitive"]["phrase"]
                                wrapMode: Text.WordWrap
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18nc("Air Quality Index","AQI")
                                font.bold: true
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18n("The AQI is a measure of air quality that takes into account the levels of various pollutants in the air. It ranges from 0 to 500, with higher values indicating worse air quality. An AQI of 0-50 is considered good, 51-100 is moderate, 101-150 is unhealthy for sensitive groups, 151-200 is unhealthy, 201-300 is very unhealthy, and 301-500 is hazardous.")
                                wrapMode: Text.WordWrap
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18nc("Air Quality Health Index", "AQHI")
                                font.bold: true
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18n("The AQHI is a measure of how the air quality may affect human health. It ranges from 1 to 10+, with higher values indicating more unfavorable conditions for health. An AQHI of 1-3 is considered low risk, 4-6 is moderate risk, 7-10 is high risk, and 10+ is very high risk.")
                                wrapMode: Text.WordWrap
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18nc("Particulate Matter", "PM2.5")
                                font.bold: true
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18n("Particulate matter (PM2.5) is a measure of the amount of solid particles and liquid droplets suspended in the air. It can have serious health effects, especially on the respiratory and cardiovascular systems.")
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    GridLayout {
        id: solGrid

        columns: 2
        rows: 4

        uniformCellWidths: true

        Layout.preferredWidth: 1
        Layout.fillWidth: true

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

        Rectangle {
            Layout.preferredWidth: solStatusTxt.width + 5
            Layout.preferredHeight: solStatusTxt.height + 5
            Layout.alignment: Qt.AlignCenter
            Layout.columnSpan: 2

            color: weatherData["kp-color"] || "#FFFFFF"

            radius: 5

            PlasmaComponents.Label {
                anchors.centerIn: parent

                color: "#000000"

                text: {
                    var val = Math.round(weatherData["kp-health"]);
                    if (val < 4) {
                        return i18n("Comfortable");
                    } else if (val < 7) {
                        return i18n("Moderate");
                    } else {
                        return i18n("Unfavorable");
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                text: "\uF06D"
                font.family: "weather-icons"
                font.pixelSize: Kirigami.Units.iconSizes.medium
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize

                text: i18nc("See: https://www.swpc.noaa.gov/products/planetary-k-index","Kp-index")
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize
                font.bold: true

                text: weatherData["kp-index"] || "N/A"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                text: "\uF072"
                font.family: "weather-icons"
                font.pixelSize: Kirigami.Units.iconSizes.medium
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize

                text: i18n("Power")
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize
                font.bold: true

                text: weatherData["solarRad"] + " W/m²"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                text: "\uF00E"
                font.family: "weather-icons"
                font.pixelSize: Kirigami.Units.iconSizes.medium
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize

                text: i18n("Health index")
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize
                font.bold: true

                text: {
                    return Math.round(weatherData["kp-health"])
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Kirigami.Icon {
                source: "documentinfo-symbolic"
                width: Kirigami.Units.iconSizes.medium
                height: Kirigami.Units.iconSizes.medium
                Layout.alignment: Qt.AlignHCenter
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize

                text: i18n("Info")
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: plasmoid.configuration.propPointSize
                font.bold: true
                font.underline: true

                text: i18n("Details")

                PlasmaCore.ToolTipArea {
                    anchors.fill: parent

                    interactive: true

                    mainItem: Item {
                        implicitWidth: Kirigami.Units.gridUnit * 15
                        implicitHeight: solInfoLayout.implicitHeight + Kirigami.Units.gridUnit * 2
                        
                        ColumnLayout {
                            id: solInfoLayout

                            anchors.fill: parent

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18nc("See: https://www.swpc.noaa.gov/products/planetary-k-index","Kp-index")
                                font.bold: true
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18n("The Kp-index is a measure of geomagnetic activity. It ranges from 0 to 9, with higher values indicating more intense geomagnetic storms. A Kp-index of 0-3 is considered quiet, 4-5 is unsettled, 6-7 is active, and 8-9 is storm-level activity.")
                                wrapMode: Text.WordWrap
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18n("Health index")
                                font.bold: true
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18n("The health index is a measure of how the solar conditions combined with pressure changes may affect human health. It ranges from 0 to 10+, with higher values indicating more unfavorable conditions for health. A health index of 0-2 is considered comfortable, 3-5 is moderate, and 6+ is unfavorable.")
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
