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
import QtQuick.Controls as QQC
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import "../../code/pws-api.js" as StationAPI

Window {
    id: stationSearcher

    signal stationSelected(var station)
    signal open

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    flags: Qt.Dialog
    modality: Qt.WindowModal

    width: Kirigami.Units.gridUnit * 35
    height: Kirigami.Units.gridUnit * 20

    SystemPalette {
        id: syspal
    }

    title: i18n("Find Station")
    color: syspal.window

    property string searchMode: "stationID"
    property string searchText: ""
    property var selectedStation
    property real searchLat: 0
    property real searchLon: 0

    property ListModel searchResults: ListModel {}
    property ListModel availableCitiesModel: ListModel {}

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {
            console.log("[debug] [StationSearcher.qml] " + msg);
        }
    }

    function clearError() {
        errText.visible = false;
        errText.text = "";
    }

    function setError(errorObj) {
        errText.visible = true;
        errText.text = i18n("Error: %1 message: %2", errorObj.type, errorObj.message);
    }

    function testStation(stationID) {
        StationAPI.isStationActive(stationID, {
            unitsChoice: plasmoid.configuration.unitsChoice
        }, function (err, res) {
            if (err) {
                setError(err);
                return;
            }

            var isActive = res.isActive;
            var healthCount = res.healthCount;

            if (isActive) {
                if (healthCount > 18) {
                    errText.text = stationID + ":" + i18n("Station active!") + " " + i18n("Reporting %1\% of properties.", Math.floor((healthCount / 21) * 100));
                } else if (healthCount > 15) {
                    errText.text = stationID + ":" + i18n("Station active.") + " " + i18n("Reporting %1\% of properties.", Math.floor((healthCount / 21) * 100));
                } else if (healthCount > 10) {
                    errText.text = stationID + ":" + i18n("Station unhealthy.") + " " + i18n("Reporting %1\% of properties.", Math.floor((healthCount / 21) * 100));
                } else {
                    errText.text = stationID + ":" + i18n("Error: Bad station.") + " " + i18n("Reporting %1\% of properties.", Math.floor((healthCount / 21) * 100));
                }
            } else {
                errText.text = stationID + ":" + i18n("Error: Station not active!");
            }
            errText.visible = true;
        });
    }

    onOpen: {
        stationSearcher.visible = true;
        clearError();

        searchResults.clear();
        availableCitiesModel.clear();
    }

    ColumnLayout {
        id: mainColumn
        anchors {
            fill: parent
            margins: mainColumn.spacing * Screen.devicePixelRatio //margins are hardcoded in QStyle we should match that here
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            RowLayout {
                QQC.Label {
                    text: i18n("Search by:")
                }
                QQC.ComboBox {
                    id: modeCombo
                    model: [i18n("City Name"), i18n("Weatherstation ID:"), i18n("Lat/Lon")]
                    onCurrentIndexChanged: {
                        if (currentIndex === 0)
                            stationSearcher.searchMode = "placeName";
                        else if (currentIndex === 1)
                            stationSearcher.searchMode = "stationID";
                        else
                            stationSearcher.searchMode = "latlon";
                    }
                }
            }

            Loader {
                id: searchFieldLoader
                Layout.fillWidth: true
                sourceComponent: stationSearcher.searchMode === "latlon" ? latlonFields : textField
            }

            QQC.Button {
                text: "Search"
                enabled: (stationSearcher.searchMode === "stationID" || stationSearcher.searchMode === "placeName") ? stationSearcher.searchText.length > 0 : true
                onClicked: {
                    clearError();
                    searchResults.clear();
                    availableCitiesModel.clear();
                    if (stationSearcher.searchMode === "stationID") {
                        StationAPI.searchStationID(stationSearcher.searchText, {
                            language: Qt.locale().name.replace("_", "-")
                        }, function (err, stations) {
                            if (err) {
                                setError(err);
                            } else {
                                clearError();
                                for (var i = 0; i < stations.length; i++) {
                                    stationSearcher.searchResults.append({
                                        "stationID": stations[i].stationID,
                                        "placeName": stations[i].placeName,
                                        "latitude": stations[i].latitude,
                                        "longitude": stations[i].longitude,
                                        "selected": false
                                    });
                                }
                            }
                        });
                    } else if (stationSearcher.searchMode === "placeName") {
                        StationAPI.getLocations(stationSearcher.searchText, {
                            language: Qt.locale().name.replace("_", "-")
                        }, function (err, places) {
                            if (err) {
                                setError(err);
                            } else {
                                clearError();
                                for (var i = 0; i < places.length; i++) {
                                    availableCitiesModel.append({
                                        "placeName": places[i].city + "," + places[i].state + " (" + places[i].country + ")",
                                        "latitude": places[i].latitude,
                                        "longitude": places[i].longitude
                                    });
                                }
                            }
                        });
                    } else {
                        StationAPI.searchGeocode({
                            latitude: stationSearcher.searchLat,
                            longitude: stationSearcher.searchLon
                        }, {
                            language: Qt.locale().name.replace("_", "-")
                        }, function (err, stations) {
                            if (err) {
                                setError(err);
                            } else {
                                clearError();
                                for (var i = 0; i < stations.length; i++) {
                                    stationSearcher.searchResults.append({
                                        "stationID": stations[i].stationID,
                                        "placeName": stations[i].placeName,
                                        "latitude": stations[i].latitude,
                                        "longitude": stations[i].longitude,
                                        "selected": false
                                    });
                                }
                            }
                        });
                    }
                }
            }
        }

        Loader {
            id: searchHelpLoader
            Layout.fillWidth: true
            sourceComponent: stationSearcher.searchMode === "placeName" ? placeNameHelp : (stationSearcher.searchMode === "latlon" ? latLonHelp : stationIDHelp)
        }

        PlasmaComponents.Label {
            id: errText
            visible: false
            Layout.fillWidth: true
            clip: true
            elide: Text.ElideRight
        }

        Component {
            id: placeNameHelp
            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    text: i18n("Searching place:")
                }

                QQC.ComboBox {
                    id: cityChoice
                    Layout.fillWidth: true
                    textRole: "placeName"
                    model: availableCitiesModel
                    enabled: availableCitiesModel.count > 0
                }

                QQC.Button {
                    text: i18n("Choose")
                    enabled: cityChoice.currentIndex !== -1
                    onClicked: {
                        searchResults.clear();
                        StationAPI.searchGeocode({
                            latitude: availableCitiesModel.get(cityChoice.currentIndex).latitude,
                            longitude: availableCitiesModel.get(cityChoice.currentIndex).longitude
                        }, {
                            language: Qt.locale().name.replace("_", "-")
                        }, function (err, stations) {
                            if (err) {
                                setError(err);
                                return;
                            }
                            for (var i = 0; i < stations.length; i++) {
                                stationSearcher.searchResults.append({
                                    "stationID": stations[i].stationID,
                                    "placeName": stations[i].placeName,
                                    "latitude": stations[i].latitude,
                                    "longitude": stations[i].longitude,
                                    "selected": false
                                });
                            }
                        });
                    }
                }
            }
        }

        Component {
            id: latLonHelp

            PlasmaComponents.Label {
                text: i18n("Uses WGS84 geocode coordinates")
            }
        }

        Component {
            id: stationIDHelp

            PlasmaComponents.Label {
                text: i18n("Use Station ID, not city name. Select 'Search by: City Name' to search by city.")
            }
        }

        Component {
            id: textField
            QQC.TextField {
                Layout.fillWidth: true
                placeholderText: stationSearcher.searchMode === "stationID" ? i18n("Enter Station") : i18n("Enter City Name")
                onTextChanged: stationSearcher.searchText = text.trim()
            }
        }
        Component {
            id: latlonFields
            RowLayout {
                Layout.fillWidth: true
                QQC.TextField {
                    Layout.fillWidth: true
                    placeholderText: i18n("Latitude:")
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    onTextChanged: stationSearcher.searchLat = parseFloat(text.trim())
                }
                QQC.TextField {
                    Layout.fillWidth: true
                    placeholderText: i18n("Longitude:")
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    onTextChanged: stationSearcher.searchLon = parseFloat(text.trim())
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            PlasmaComponents.Label {
                text: i18n("Weatherstation ID:")
                Layout.fillWidth: true
                Layout.preferredWidth: 2
            }
            PlasmaComponents.Label {
                text: i18n("Weatherstation Name:")
                Layout.fillWidth: true
                Layout.preferredWidth: 2
            }
            PlasmaComponents.Label {
                text: i18n("Lat/Lon")
                Layout.fillWidth: true
                Layout.preferredWidth: 1
            }
            PlasmaComponents.Label {
                text: ""
                Layout.fillWidth: true
                Layout.preferredWidth: 1
            }
            PlasmaComponents.Label {
                text: ""
                Layout.fillWidth: true
                Layout.preferredWidth: 1
            }
        }

        ListView {
            id: resultsView
            model: stationSearcher.searchResults
            delegate: RowLayout {
                spacing: 8
                width: ListView.view.width

                PlasmaComponents.Label {
                    text: stationID
                    Layout.fillWidth: true
                    Layout.preferredWidth: 2
                    elide: Text.ElideRight
                    clip: true
                }
                PlasmaComponents.Label {
                    text: placeName
                    Layout.fillWidth: true
                    Layout.preferredWidth: 2
                    elide: Text.ElideRight
                    clip: true
                }
                PlasmaComponents.Label {
                    text: latitude + "," + longitude
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    elide: Text.ElideRight
                    clip: true
                }
                QQC.Button {
                    text: i18n("Test")
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    onClicked: {
                        var testingStation = stationSearcher.searchResults.get(index);
                        testStation(testingStation.stationID);
                    }
                }
                QQC.Button {
                    text: i18n("Select")
                    enabled: !selected
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    onClicked: {
                        selectedStation = stationSearcher.searchResults.get(index);
                        for (var i = 0; i < stationSearcher.searchResults.count; i++) {
                            stationSearcher.searchResults.setProperty(i, "selected", i === index);
                        }
                        printDebug("selected: " + JSON.stringify(stationSearcher.searchResults.get(index)));
                    }
                }
            }
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
        }

        RowLayout {
            id: buttonsRow

            Layout.alignment: Qt.AlignRight

            QQC.Button {
                icon.name: "dialog-ok"
                text: i18n("Confirm")
                enabled: selectedStation !== undefined
                onClicked: {
                    stationSelected(selectedStation);
                    stationSearcher.close();
                }
            }

            QQC.Button {
                icon.name: "dialog-cancel"
                text: i18n("Cancel")
                onClicked: {
                    stationSearcher.close();
                }
            }
        }
    }
}
