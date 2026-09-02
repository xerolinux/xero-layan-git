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
import QtQuick.Layouts
import QtQuick.Controls as QQC
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../lib" as Lib
import "../../code/pws-api.js" as StationAPI

KCM.SimpleKCM {
    id: stationConfig

    // Configuration properties
    property alias cfg_stationID: stationManager.selectedStation
    property alias cfg_savedStations: stationManager.stationList
    property alias cfg_stationName: stationManager.stationName
    property alias cfg_latitude: stationManager.latitude
    property alias cfg_longitude: stationManager.longitude
    property alias cfg_refreshPeriod: refreshPeriod.value

    property string errorType: ""
    property string errorMessage: ""

        function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {
            console.log("[debug] [ConfigStation.qml] " + msg);
        }
    }

    Lib.StationManager {
        id: stationManager
    }

    PlasmaComponents.ScrollView {
        anchors.fill: stationConfig

        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            // Header
            Kirigami.Heading {
                text: i18n("Saved Weather Stations")
                level: 3
            }

            // Table Header
            RowLayout {
                id: headerRow
                spacing: 0
                Layout.fillWidth: true

                Lib.TableHeaderCell {
                    text: i18n("ID")
                    width: 120
                }

                Lib.TableHeaderCell {
                    text: i18n("Station Name")
                    width: 160
                }

                Lib.TableHeaderCell {
                    text: i18n("Latitude")
                    width: 80
                }

                Lib.TableHeaderCell {
                    text: i18n("Longitude")
                    width: 80
                }

                Lib.TableHeaderCell {
                    text: i18n("Actions")
                    width: 140
                }
            }

            // Station List
            ListView {
                id: stationListView
                Layout.preferredHeight: 216
                Layout.fillWidth: true
                clip: true
                model: stationManager.stationListModel

                delegate: Lib.StationListDelegate {
                    required property var model

                    width: headerRow.width
                    stationID: model.stationID
                    address: model.address
                    latitude: model.latitude
                    longitude: model.longitude
                    selected: model.selected

                    onSelectStation: stationManager.selectStation(index)
                    onDeleteStation: stationManager.deleteStation(index)
                    onEditStation: function(newName) {
                        stationManager.editStationName(index, newName)
                    }
                }
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC.Button {
                    text: i18n("Add Current Location")
                    icon.name: "mark-location"
                    onClicked: function() {
                        StationAPI.getNearest({ language: Qt.locale().name.replace("_", "-")}, function(err, stations) {
                            if (err) {
                                stationConfig.errorMessage = err.message;
                                stationConfig.errorType = err.type;
                                return;
                            }
                            stationConfig.errorType = "";
                            stationConfig.errorMessage = "";
                            if (stations.length > 0) {
                                var station = stations[0];
                                stationManager.addStation(station.stationID, station.address, station.latitude, station.longitude, function(err) {
                                    stationConfig.errorType = err.type;
                                    stationConfig.errorMessage = err.message;
                                });
                            } else {
                                stationConfig.errorMessage = i18n("No nearby stations found.");
                                stationConfig.errorType = "NoStations";
                            }
                        })
                    }
                }

                QQC.Button {
                    text: i18n("Select from Map")
                    icon.name: "earth"
                    onClicked: stationMapSearcher.open()
                }

                QQC.Button {
                    text: i18n("Find Station")
                    icon.name: "find-location"
                    onClicked: stationSearcher.open()
                }

                QQC.Button {
                    text: i18n("Manual Add")
                    icon.name: "list-add"
                    onClicked: manualAdd.open()
                }

                Item { Layout.fillWidth: true }
            }

            // Error Text
            QQC.TextField {
                enabled: false
                Layout.fillWidth: true
                visible: stationConfig.errorMessage.length > 0
                text: i18n("Error (%1): %2", stationConfig.errorType, stationConfig.errorMessage)
                color: "red"
            }

            // Refresh Period Setting
            RowLayout {
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Refresh period (s):")
                }

                QQC.SpinBox {
                    id: refreshPeriod
                    from: 300
                    to: 86400
                    editable: true
                    validator: IntValidator {
                        bottom: refreshPeriod.from
                        top: refreshPeriod.to
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Version
            PlasmaComponents.Label {
                text: "Version 3.8.3"
                font.pointSize: 9
                opacity: 0.7
            }

            Item { Layout.fillHeight: true }
        }
    }

    // Station Search Dialog
    Lib.StationSearcher {
        id: stationSearcher
        onStationSelected: function (station) {
            stationManager.addStation(station.stationID, station.placeName, station.latitude, station.longitude, function(err) {
                stationConfig.errorType = err.type;
                stationConfig.errorMessage = err.message;
            });
            stationSearcher.close()
        }
    }

    // Map Search Dialog
    Lib.StationMapSearcher {
        id: stationMapSearcher
        onStationSelected: function (station) {
            stationManager.addStation(station.stationID, station.address, station.latitude, station.longitude, function(err) {
                stationConfig.errorType = err.type;
                stationConfig.errorMessage = err.message;
            });
        }
    }

    // Manual Add Dialog
    Lib.ManualStationAdd {
        id: manualAdd
        onStationSelected: function (station) {
            stationManager.addStation(station.stationID, station.address, 0, 0, function(err) {
                stationConfig.errorType = err.type;
                stationConfig.errorMessage = err.message;
            });
        }
    }
}
