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

        columns: 4
        rows: 3

        Layout.preferredWidth: 1
        Layout.fillWidth: true

        uniformCellWidths: true

        PlasmaComponents.Label {
            id: aqLabel

            Layout.columnSpan: 4
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
            Layout.columnSpan: 4

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

                text: i18n("AQI")
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

                text: i18n("AQHI")
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

                    mainItem: ColumnLayout {
                        PlasmaComponents.Label {
                            text: weatherData["aq"]["messages"]["general"]["title"]
                            font.bold: true
                        }

                        PlasmaComponents.Label {
                            text: weatherData["aq"]["messages"]["general"]["phrase"]
                            wrapMode: Text.WordWrap
                        }

                        PlasmaComponents.Label {
                            text: weatherData["aq"]["messages"]["sensitive"]["title"]
                            font.bold: true
                        }

                        PlasmaComponents.Label {
                            text: weatherData["aq"]["messages"]["sensitive"]["phrase"]
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }

    GridLayout {
        id: solGrid

        columns: 3
        rows: 3

        uniformCellWidths: true

        Layout.preferredWidth: 1
        Layout.fillWidth: true

        PlasmaComponents.Label {
            id: solLabel

            Layout.columnSpan: 3
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
            Layout.columnSpan: 3

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

                text: i18n("Kp-index")
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

        // ColumnLayout {
        //     Layout.fillWidth: true
        //     spacing: 0

        //     Kirigami.Icon {
        //         source: "documentinfo-symbolic"
        //         width: Kirigami.Units.iconSizes.medium
        //         height: Kirigami.Units.iconSizes.medium
        //         Layout.alignment: Qt.AlignHCenter
        //     }

        //     PlasmaComponents.Label {
        //         Layout.fillWidth: true
        //         horizontalAlignment: Text.AlignHCenter
        //         font.pointSize: plasmoid.configuration.propPointSize

        //         text: i18n("Status")
        //     }

        //     PlasmaComponents.Label {
        //         Layout.fillWidth: true
        //         horizontalAlignment: Text.AlignHCenter
        //         font.pointSize: plasmoid.configuration.propPointSize
        //         font.bold: true

                // text: {
                //     var val = Math.round(weatherData["kp-health"]);
                //     if (val < 4) {
                //         return i18n("Comfortable");
                //     } else if (val < 7) {
                //         return i18n("Moderate");
                //     } else {
                //         return i18n("Unfavorable");
                //     }
                // }
        //     }
        // }
    }
}
