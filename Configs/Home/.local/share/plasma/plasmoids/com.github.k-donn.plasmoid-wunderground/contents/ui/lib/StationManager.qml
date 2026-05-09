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

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.plasmoid

/**
 * Manages station list data and operations
 */
QtObject {
    id: stationManager

    property var stationListModel: ListModel { id: listModel }
    property string selectedStation: ""
    property string stationList: ""
    property string stationName: ""
    property real latitude: 0
    property real longitude: 0

    Component.onCompleted: {
        loadStations();
    }

    function printDebug(msg) {
        if (typeof plasmoid !== 'undefined' && plasmoid.configuration.logConsole) {
            console.log("[debug] [StationManager.qml] " + msg);
        }
    }

    function loadStations() {
        listModel.clear();
        printDebug("Loading from savedStations: " + stationList);
        var stationsArr = [];

        try {
            if (stationList && stationList.length > 0) {
                stationsArr = JSON.parse(stationList);
            }

            // Fallback if no saved stations but configuration has a station
            if (stationsArr.length === 0 && typeof plasmoid !== 'undefined' && plasmoid.configuration.stationID !== "") {
                printDebug("Station not saved to savedStations. Attempting to add.");
                listModel.append({
                    "stationID": plasmoid.configuration.stationID,
                    "address": plasmoid.configuration.stationName || "",
                    "latitude": plasmoid.configuration.latitude || 0,
                    "longitude": plasmoid.configuration.longitude || 0,
                    "selected": true
                });
                syncSelectedStation();
            }

            // Load all stations
            for (var i = 0; i < stationsArr.length; i++) {
                listModel.append({
                    "stationID": stationsArr[i].stationID,
                    "address": stationsArr[i].address || "",
                    "latitude": stationsArr[i].latitude || 0,
                    "longitude": stationsArr[i].longitude || 0,
                    "selected": stationsArr[i].selected === true
                });
            }

            if (listModel.count > 0) {
                syncSelectedStation();
            }
        } catch (e) {
            printDebug("Invalid saved stations: " + e);
            if (typeof plasmoid !== 'undefined' && plasmoid.configuration.stationID !== "") {
                printDebug("Attempting to fill in savedStations from config");
                listModel.append({
                    "stationID": plasmoid.configuration.stationID,
                    "address": plasmoid.configuration.stationName || "",
                    "latitude": plasmoid.configuration.latitude || 0,
                    "longitude": plasmoid.configuration.longitude || 0,
                    "selected": true
                });
                syncSelectedStation();
            }
        }
    }

    function syncStations() {
        var kvs = [];
        for (var i = 0; i < listModel.count; i++) {
            kvs.push(listModel.get(i));
        }
        stationList = JSON.stringify(kvs);
        printDebug("Wrote to savedStations: " + stationList);
        
        if (typeof plasmoid !== 'undefined') {
            plasmoid.configuration.savedStations = stationList;
        }
        syncSelectedStation();
    }

    function syncSelectedStation() {
        if (listModel.count === 0) {
            selectedStation = "";
            stationName = "";
            latitude = 0;
            longitude = 0;
        } else {
            for (var i = 0; i < listModel.count; i++) {
                var station = listModel.get(i);
                if (station.selected) {
                    selectedStation = station.stationID;
                    stationName = station.address;
                    latitude = station.latitude;
                    longitude = station.longitude;
                    return;
                }
            }
        }
    }

    function addStation(stationID, address, lat, lon) {
        printDebug("Adding station: " + stationID);
        
        // Deselect all stations
        for (var i = 0; i < listModel.count; i++) {
            listModel.setProperty(i, "selected", false);
        }

        // Add new station
        listModel.append({
            "stationID": stationID,
            "address": address,
            "latitude": lat,
            "longitude": lon,
            "selected": true
        });

        syncStations();
    }

    function selectStation(index) {
        if (index < 0 || index >= listModel.count) {
            return;
        }

        printDebug("Selecting station at index: " + index);

        // Deselect all
        for (var i = 0; i < listModel.count; i++) {
            listModel.setProperty(i, "selected", false);
        }

        // Select this one
        listModel.setProperty(index, "selected", true);
        syncStations();
    }

    function deleteStation(index) {
        if (index < 0 || index >= listModel.count) {
            return;
        }

        printDebug("Deleting station at index: " + index);

        var wasSelected = listModel.get(index).selected;
        listModel.remove(index);

        // If we deleted the selected station, select another
        if (wasSelected) {
            if (listModel.count > 0) {
                if (index < listModel.count) {
                    listModel.setProperty(index, "selected", true);
                } else {
                    listModel.setProperty(listModel.count - 1, "selected", true);
                }
            }
        }

        syncStations();
    }

    function editStationName(index, newName) {
        if (index < 0 || index >= listModel.count) {
            return;
        }

        var oldName = listModel.get(index).address;
        if (newName !== oldName) {
            printDebug("Editing station name at index " + index + ": " + oldName + " -> " + newName);
            listModel.setProperty(index, "address", newName);
            syncStations();
        }
    }
}
