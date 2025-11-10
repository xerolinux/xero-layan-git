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
import QtQuick.Dialogs
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../lib" as Lib

KCM.SimpleKCM {
    id: stationConfig

    property alias cfg_stationID: stationPickerEl.selectedStation
    property alias cfg_savedStations: stationPickerEl.stationList
    property alias cfg_stationName: stationPickerEl.stationName
    property alias cfg_latitude: stationPickerEl.latitude
    property alias cfg_longitude: stationPickerEl.longitude
    property alias cfg_refreshPeriod: refreshPeriod.value

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {
            console.log("[debug] [ConfigStation.qml] " + msg);
        }
    }

    function listModelToStr(listModel) {
        var kvs = [];
        for (var i = 0; i < listModel.count; i++) {
            kvs.push(listModel.get(i));
        }
        return JSON.stringify(kvs);
    }

    Item {
        anchors.fill: parent
        id: stationPickerEl
        property string selectedStation: ""
        property string stationList: ""
        property string stationName: ""
        property real latitude: 0
        property real longitude: 0

        function syncSavedStations(force) {
            var stationsTxt = listModelToStr(stationListModel);
            if (force) {
                plasmoid.configuration.savedStations = stationsTxt;
            }
            printDebug("Wrote to savedStations: " + stationsTxt);
            stationList = stationsTxt;
            if (stationListModel.count === 0) {
                selectedStation = "";
                stationName = "";
                latitude = 0;
                longitude = 0;
            } else {
                for (var i = 0; i < stationListModel.count; i++) {
                    var station = stationListModel.get(i);
                    if (station.selected) {
                        selectedStation = station.stationID;
                        stationName = station.address;
                        latitude = station.latitude;
                        longitude = station.longitude;
                    }
                }
            }
        }

        PlasmaComponents.ScrollView {
            anchors.fill: parent

            ColumnLayout {
                width: parent.width

                Kirigami.Heading {
                    text: i18n("Saved Weather Stations")
                    level: 3
                }

                RowLayout {
                    id: headerRow
                    spacing: 0
                    Rectangle {
                        color: Kirigami.Theme.backgroundColor
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        border.width: 1
                        height: 36
                        width: 120
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: i18n("ID:")
                            font.bold: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width - 8
                            clip: true
                        }
                    }
                    Rectangle {
                        color: Kirigami.Theme.backgroundColor
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        border.width: 1
                        height: 36
                        width: 160
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: i18n("Weatherstation Name:")
                            font.bold: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width - 8
                            clip: true
                        }
                    }
                    Rectangle {
                        color: Kirigami.Theme.backgroundColor
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        border.width: 1
                        height: 36
                        width: 80
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: i18n("Lat/Lon").split("/")[0] + ":"
                            font.bold: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width - 8
                            clip: true
                        }
                    }
                    Rectangle {
                        color: Kirigami.Theme.backgroundColor
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        border.width: 1
                        height: 36
                        width: 80
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: i18n("Lat/Lon").split("/")[1] + ":"
                            font.bold: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width - 8
                            clip: true
                        }
                    }
                    Rectangle {
                        color: Kirigami.Theme.backgroundColor
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        border.width: 1
                        height: 36
                        width: 120
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: i18n("Action")
                            font.bold: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width - 8
                            clip: true
                        }
                    }
                }

                ListView {
                    id: stationListView
                    model: ListModel {
                        id: stationListModel
                        Component.onCompleted: {
                            stationListModel.clear();
                            printDebug("Loading from savedStations: " + stationPickerEl.stationList + "");
                            var stationsArr = [];
                            try {
                                stationsArr = JSON.parse(stationPickerEl.stationList);

                                if (stationsArr.length === 0 && plasmoid.configuration.stationID !== "") {
                                    printDebug("Station not saved to savedStations. Attempting to add.");
                                    stationListModel.append({
                                        "stationID": plasmoid.configuration.stationID,
                                        "address": plasmoid.configuration.stationName,
                                        "latitude": plasmoid.configuration.latitude,
                                        "longitude": plasmoid.configuration.longitude,
                                        "selected": true
                                    });
                                    stationPickerEl.syncSavedStations(true);
                                }

                                for (var i = 0; i < stationsArr.length; i++) {
                                    // FIXME: If the station has been manually added, the lat/long/address are not set
                                    // The individual properties are set in the xml file by the widget, but the widget
                                    // does not set the JSON.
                                    stationListModel.append({
                                        "stationID": stationsArr[i].stationID,
                                        "address": plasmoid.configuration.stationName,
                                        "latitude": plasmoid.configuration.latitude,
                                        "longitude": plasmoid.configuration.longitude,
                                        "selected": stationsArr[i].selected === true
                                    });
                                    stationPickerEl.syncSavedStations(true);
                                }
                            } catch (e) {
                                printDebug("Invalid saved stations: " + e);
                                printDebug("Station ID: " + plasmoid.configuration.stationID + " long: " + plasmoid.configuration.longitude + " lat: " + plasmoid.configuration.latitude + " name: " + plasmoid.configuration.stationName + " list: " + plasmoid.configuration.stationList);
                                if (plasmoid.configuration.stationID !== "") {
                                    printDebug("Attempting to fill in savedStations");
                                    stationListModel.append({
                                        "stationID": plasmoid.configuration.stationID,
                                        "address": plasmoid.configuration.stationName,
                                        "latitude": plasmoid.configuration.latitude,
                                        "longitude": plasmoid.configuration.longitude,
                                        "selected": true
                                    });
                                    stationPickerEl.syncSavedStations(true);
                                }
                            }
                        }
                    }
                    delegate: Item {
                        width: headerRow.width
                        height: 36
                        Rectangle {
                            anchors.fill: parent
                            color: selected ? Kirigami.Theme.highlightColor : (index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor)
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                            border.width: 1
                        }
                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            PlasmaComponents.Label {
                                text: stationID
                                Layout.preferredWidth: 120
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                clip: true
                            }
                            Rectangle {
                                width: 1
                                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                                height: parent.height
                            }
                            PlasmaComponents.Label {
                                text: address
                                Layout.preferredWidth: 160
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                clip: true
                            }
                            Rectangle {
                                width: 1
                                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                                height: parent.height
                            }
                            PlasmaComponents.Label {
                                text: latitude
                                Layout.preferredWidth: 80
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                clip: true
                            }
                            Rectangle {
                                width: 1
                                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                                height: parent.height
                            }
                            PlasmaComponents.Label {
                                text: longitude
                                Layout.preferredWidth: 80
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                clip: true
                            }
                            Rectangle {
                                width: 1
                                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                                height: parent.height
                            }
                            RowLayout {
                                Layout.preferredWidth: 120
                                spacing: 4
                                PlasmaComponents.Button {
                                    icon.name: "dialog-ok-apply"
                                    enabled: !selected
                                    PlasmaComponents.ToolTip.text: i18n("Select")
                                    PlasmaComponents.ToolTip.visible: hovered
                                    onClicked: {
                                        for (var i = 0; i < stationListModel.count; i++) {
                                            stationListModel.setProperty(i, "selected", i === index);
                                        }
                                        stationPickerEl.syncSavedStations();
                                    }
                                }
                                PlasmaComponents.Button {
                                    icon.name: "dialog-cancel"
                                    PlasmaComponents.ToolTip.text: i18n("Remove")
                                    PlasmaComponents.ToolTip.visible: hovered
                                    onClicked: {
                                        var wasSelected = selected;
                                        var oldIndex = index;
                                        stationListModel.remove(index);
                                        if (wasSelected && stationListModel.count === 1) {
                                            stationListModel.setProperty(0, "selected", true);
                                        } else if (wasSelected && stationListModel.count > 1) {
                                            if (stationListModel.count > oldIndex) {
                                                stationListModel.setProperty(oldIndex, "selected", true);
                                            } else if (stationListModel.count === oldIndex) {
                                                stationListModel.setProperty(oldIndex - 1, "selected", true);
                                            } else {
                                                stationListModel.setProperty(stationListModel.count - 1, "selected", true);
                                            }
                                        }
                                        stationPickerEl.syncSavedStations();
                                    }
                                }
                            }
                        }
                    }
                    Layout.preferredHeight: 216
                    Layout.fillWidth: true
                    clip: true
                }

                PlasmaComponents.Button {
                    text: i18n("Select from Map")
                    icon.name: "earth"
                    onClicked: stationMapSearcher.open()
                }

                PlasmaComponents.Button {
                    text: i18n("Manual Add")
                    icon.name: "list-add"
                    onClicked: manualAdd.open()
                }

                PlasmaComponents.Button {
                    text: i18n("Find Station")
                    icon.name: "find-location"
                    onClicked: stationSearcher.open()
                }

                Lib.ManualStationAdd {
                    id: manualAdd
                    onStationSelected: function (station) {
                        printDebug("Received manual station: " + station);
                        stationListModel.append({
                            "stationID": station,
                            "address": "MANUALADD",
                            "longitude": 0,
                            "latitude": 0,
                            "selected": true
                        });
                        for (var i = 0; i < stationListModel.count; i++) {
                            stationListModel.setProperty(i, "selected", i === stationListModel.count - 1);
                        }
                        stationPickerEl.syncSavedStations();
                    }
                }

                Lib.StationSearcher {
                    id: stationSearcher
                    onStationSelected: function (station) {
                        printDebug("Received station: " + JSON.stringify(station));
                        stationListModel.append({
                            "stationID": station.stationID,
                            "address": station.address,
                            "latitude": station.latitude,
                            "longitude": station.longitude,
                            "selected": true
                        });
                        for (var i = 0; i < stationListModel.count; i++) {
                            stationListModel.setProperty(i, "selected", i === stationListModel.count - 1);
                        }
                        stationSearcher.close();
                        stationPickerEl.syncSavedStations();
                    }
                }

                Lib.StationMapSearcher {
                    id: stationMapSearcher
                    onStationSelected: function (station) {
                        printDebug("Received station from map: " + JSON.stringify(station));
                        stationListModel.append({
                            "stationID": station.stationID,
                            "address": station.address,
                            "latitude": station.latitude,
                            "longitude": station.longitude,
                            "selected": true
                        });
                        for (var i = 0; i < stationListModel.count; i++) {
                            stationListModel.setProperty(i, "selected", i === stationListModel.count - 1);
                        }
                        stationPickerEl.syncSavedStations();
                    }
                }

                RowLayout {
                    PlasmaComponents.Label {
                        id: refreshLabel
                        text: i18n("Refresh period (s):")
                    }

                    PlasmaComponents.SpinBox {
                        id: refreshPeriod
                        from: 300
                        to: 86400
                        editable: true
                        validator: IntValidator {
                            bottom: refreshPeriod.from
                            top: refreshPeriod.to
                        }
                    }
                }

                PlasmaComponents.Label {
                    text: "Version 3.6.2"
                }
            }
        }
    }
}
