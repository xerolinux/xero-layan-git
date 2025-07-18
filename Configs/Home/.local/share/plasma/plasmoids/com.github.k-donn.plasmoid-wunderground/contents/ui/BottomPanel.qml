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
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "../code/utils.js" as Utils

RowLayout {
    id: bottomPanelRoot

    RowLayout {
        Layout.preferredWidth: parent.width / 3

        Row {
            Layout.alignment: Qt.AlignLeft

            PlasmaComponents.Label {
                id: bottomPanelTime

                text: weatherData["obsTimeLocal"] + " (" + plasmoid.configuration.refreshPeriod + "s)"
            }
        }

    }

    RowLayout {
        Layout.preferredWidth: parent.width / 3

        Row {
            Layout.alignment: Qt.AlignHCenter
            Kirigami.Icon {
                id: locationIcon

                isMask: plasmoid.configuration.applyColorScheme ? true : false
                color: Kirigami.Theme.textColor

                height: Kirigami.Units.iconSizes.small
                source: Utils.getIcon("pin")
            }

            PlasmaComponents.Label {
                id: locationLabel

                text: plasmoid.configuration.stationName
            }

            Kirigami.Icon {
                id: stationToolBtn

                opacity: 0.25

                isMask: plasmoid.configuration.applyColorScheme ? true : false
                color: Kirigami.Theme.textColor

                height: Kirigami.Units.iconSizes.small
                source: "draw-arrow-forward"

                MouseArea {
                    anchors.fill: parent

                    onClicked: Qt.openUrlExternally("https://www.wunderground.com/dashboard/pws/" + weatherData["stationID"])
                }
            }

        }

    }

    RowLayout {
        Layout.preferredWidth: parent.width / 3

        Row {
            Layout.alignment: Qt.AlignRight
            Kirigami.Icon {
                id: stationIcon

                isMask: plasmoid.configuration.applyColorScheme ? true : false
                color: Kirigami.Theme.textColor

                height: Kirigami.Units.iconSizes.small
                source: Utils.getIcon("weather-station-2")
            }

            PlasmaComponents.Label {
                id: bottomPanelStation

                text: weatherData["stationID"] + "   " + Utils.currentElevUnit(Utils.toUserElev(weatherData["details"]["elev"]))
            }

            Kirigami.Icon {
                source: "documentinfo-symbolic"
                visible: alertsModel.count > 0
                height: Kirigami.Units.iconSizes.smallMedium
                color: "#ff0000"

                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    mainText: i18n("There are weather alerts for your area!")
                }
            }

        }

    }

}
