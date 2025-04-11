/*
 * Copyright 2025  Kevin Donnelly
 * Copyright 2022  Chris Holland
 * Copyright 2016, 2018 Friedrich W. H. Kossebau
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
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

RowLayout {
    // Aliased by ConfigStation
    property var stationList: []

    // Aliased by ConfigStation
    property string selectedStation: ""

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {
            console.log("[debug] [StationPicker.qml] " + msg);
        }
    }

    property var stationPicker: StationPickerDialog {
        id: stationPickerDialog

        onAccepted: {
            printDebug("Recieved source: " + source);
            selectedStation = source;
            
            stationList = [];
            for (let i = 0; i < stationListModel.count; i++) {
                stationList.push(stationListModel.get(i).name);
            }
            printDebug("Received list: " + stationList);
        }

        onCancel: {
            if (fixedErrorState) {
                printDebug("Fixing config");

                // An error state was fixed so do not cancel changes
                printDebug("Recieved source: " + source);
                selectedStation = source;
                
                stationList = [];
                for (let i = 0; i < stationListModel.count; i++) {
                    stationList.push(stationListModel.get(i).name);
                }
                printDebug("Received list: " + stationList);

                // Reset error
                fixedErrorState = false;
            }

            if (stationListModel.count === 0) {
                // selectedStation may have picked up a value; if user removes all stations,
                // clear that value.
                selectedStation = "";
            }
        }
    }

    PlasmaComponents.Label {
        id: stationDisplay

        Layout.fillWidth: true

        text: selectedStation
    }

    Button {
        id: selectBtn
        Layout.fillWidth: true
        icon.name: "find-location"
        text: i18n("Choose…")
        onClicked: stationPicker.open()
    }
}