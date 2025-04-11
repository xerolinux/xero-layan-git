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
import org.kde.kcmutils as KCM
import QtQuick.Controls as QQC
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../../code/pws-api.js" as StationAPI
import "../lib" as Lib

KCM.SimpleKCM {
    id: stationConfig

    property alias cfg_stationID: stationPickerEl.selectedStation
    property alias cfg_savedStations: stationPickerEl.stationList
    property alias cfg_refreshPeriod: refreshPeriod.value

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {
            console.log("[debug] [ConfigStation.qml] " + msg);
        }
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Find Station")
            Kirigami.FormData.isSection: true
        }

        Lib.StationPicker {
            id: stationPickerEl

            Kirigami.FormData.label: i18n("Enter Station")

            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Station Info")
            Kirigami.FormData.isSection: true
        }

        Kirigami.Heading {
            text: i18n("Uses WGS84 geocode coordinates")
            level: 5
        }

        PlasmaComponents.Label {
            Kirigami.FormData.label: i18n("Weatherstation ID:")

            color: plasmoid.configuration.stationID !== "" ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor

            text: plasmoid.configuration.stationID !== "" ? plasmoid.configuration.stationID : "KGADACUL1"
        }

        PlasmaComponents.Label {
            Kirigami.FormData.label: i18n("Weatherstation Name:")

            color: plasmoid.configuration.stationName !== "" ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor

            text: plasmoid.configuration.stationName !== "" ? plasmoid.configuration.stationName : "Hog Mountain"
        }

        PlasmaComponents.Label {
            Kirigami.FormData.label: i18n("Longitude:")

            color: plasmoid.configuration.longitude !== "" ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor

            text: plasmoid.configuration.longitude !== "" ? plasmoid.configuration.longitude : "-83.91"
        }

        PlasmaComponents.Label {
            Kirigami.FormData.label: i18n("Latitude:")

            color: plasmoid.configuration.latitude !== "" ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor

            text: plasmoid.configuration.latitude !== "" ? plasmoid.configuration.latitude : "34.06"
        }

        QQC.SpinBox {
            id: refreshPeriod

            from: 1
            to: 86400
            editable: true

            validator: IntValidator {
                bottom: refreshPeriod.from
                top: refreshPeriod.to
            }

            Kirigami.FormData.label: i18n("Refresh period (s):")
        }

        Kirigami.Separator{}

        PlasmaComponents.Label {
            text: "Version 3.4.1"
        }

    }
}
