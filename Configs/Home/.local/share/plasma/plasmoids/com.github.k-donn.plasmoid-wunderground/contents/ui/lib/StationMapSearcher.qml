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
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtLocation
import QtPositioning
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import "../../code/utils.js" as Utils
import "../../code/pws-api.js" as StationAPI

Window {
    id: stationMapSearcher

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    flags: Qt.Dialog
    modality: Qt.WindowModal

    width: Kirigami.Units.gridUnit * 45
    height: Kirigami.Units.gridUnit * 30

    SystemPalette {
        id: syspal
    }

    title: i18n("Find Station")
    color: syspal.window

    signal stationSelected(var station)
    signal open

    property string searchMode: "address"
    property string searchText: ""
    property real areaLat: 0
    property real areaLon: 0
    property real searchLat: 0
    property real searchLon: 0
    property real searchRadius: -1

    property string errorType: ""
    property string errorMessage: ""

    property var selectedStation
    property real stationHealth: -1

    property ListModel searchResults: ListModel {}
    property ListModel availableCitiesModel: ListModel {}

    onOpen: {
        stationMapSearcher.visible = true;
        errorMessage = "";
        errorType = "";
        searchResults.clear();
        availableCitiesModel.clear();
        selectedStation = undefined;
        stationMapSearcher.stationHealth = -1;
    }

    onSelectedStationChanged: {
        stationMapSearcher.stationHealth = -1;
    }

    Plugin {
        id: osmPlugin
        name: "osm"
        PluginParameter {
            name: "osm.useragent"
            value: "WundergroundPlasmoid/3.6.4 (https://github.com/k-donn/plasmoid-wunderground; contact:mitchell@mitchelldonnelly.com)"
        }
        PluginParameter {
            name: "osm.mapping.custom.host"
            value: "https://tile.openstreetmap.org/"
        }
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

            PlasmaComponents.Label {
                text: i18n("Search by:")
            }

            PlasmaComponents.ComboBox {
                id: modeCombo
                model: [i18n("Area Name"), i18n("Weatherstation ID:"), i18n("Lat/Lon")]
                onCurrentIndexChanged: {
                    stationMapSearcher.searchResults.clear();
                    stationMapSearcher.availableCitiesModel.clear();
                    stationMapSearcher.errorType = "";
                    stationMapSearcher.errorMessage = "";
                    if (currentIndex === 0) {
                        stationMapSearcher.searchMode = "address";
                    } else if (currentIndex === 1) {
                        stationMapSearcher.searchMode = "stationID";
                    } else {
                        stationMapSearcher.searchRadius = 10000;
                        stationMapSearcher.searchMode = "latlon";
                    }
                }
            }

            Loader {
                id: searchLoader
                Layout.fillWidth: true
                sourceComponent: stationMapSearcher.searchMode === "latlon" ? latLonSearchComponent : textSearchComponent
            }

            PlasmaComponents.Button {
                id: searchBtn
                text: i18n("Search")
                enabled: stationMapSearcher.searchText.length > 0 || stationMapSearcher.searchMode === "latlon"
                onPressed: {
                    if (stationMapSearcher.searchMode === "address") {
                        StationAPI.getLocations(stationMapSearcher.searchText, {
                            language: Qt.locale().name.replace("_", "-")
                        }, function (err, places) {
                            if (err) {
                                errorType = err.type;
                                errorMessage = err.message;
                                availableCitiesModel.clear();
                                return;
                            }
                            errorType = "";
                            errorMessage = "";
                            availableCitiesModel.clear();
                            for (var i = 0; i < places.length; i++) {
                                availableCitiesModel.append({
                                    "address": places[i].address,
                                    "latitude": places[i].latitude,
                                    "longitude": places[i].longitude
                                });
                            }
                        });
                    } else if (stationMapSearcher.searchMode === "stationID") {
                        StationAPI.searchStationID(stationMapSearcher.searchText, {
                            language: Qt.locale().name.replace("_", "-")
                        }, function (err, stations) {
                            if (err) {
                                errorType = err.type;
                                errorMessage = err.message;
                                return;
                            }
                            errorType = "";
                            errorMessage = "";
                            var latMin, latMax, latSum, latCount, lonMin, lonMax, lonSum, lonCount;
                            latSum = latCount = lonSum = lonCount = 0;
                            latMin = lonMin = Infinity;
                            latMax = lonMax = -Infinity;
                            searchResults.clear();
                            for (var i = 0; i < stations.length; i++) {
                                if (stations[i].latitude < latMin)
                                    latMin = stations[i].latitude;
                                if (stations[i].latitude > latMax)
                                    latMax = stations[i].latitude;
                                if (stations[i].longitude < lonMin)
                                    lonMin = stations[i].longitude;
                                if (stations[i].longitude > lonMax)
                                    lonMax = stations[i].longitude;
                                latSum += stations[i].latitude;
                                lonSum += stations[i].longitude;
                                latCount += 1;
                                lonCount += 1;
                                searchResults.append({
                                    "stationID": stations[i].stationID,
                                    "address": stations[i].address,
                                    "latitude": stations[i].latitude,
                                    "longitude": stations[i].longitude,
                                    "qcStatus": stations[i].qcStatus
                                });
                            }
                            var latAvg = latSum / latCount;
                            var lonAvg = lonSum / lonCount;
                            var minCoord = QtPositioning.coordinate(latMin, lonMin);
                            var maxCoord = QtPositioning.coordinate(latMax, lonMax);
                            var avgCoord = QtPositioning.coordinate(latAvg, lonAvg);
                            stationMapSearcher.searchRadius = stations.length > 1 ? Math.max(avgCoord.distanceTo(minCoord), avgCoord.distanceTo(maxCoord)) : 5000;
                            stationMapSearcher.areaLat = latAvg;
                            stationMapSearcher.areaLon = lonAvg;
                            stationMap.center = avgCoord;
                            stationMap.zoomLevel = Utils.zoomForCircle(stationMap.center, stationMapSearcher.searchRadius, stationMap, 5);
                        });
                    } else if (stationMapSearcher.searchMode === "latlon") {
                        StationAPI.searchGeocode({
                            latitude: stationMapSearcher.searchLat,
                            longitude: stationMapSearcher.searchLon
                        }, {
                            language: Qt.locale().name.replace("_", "-")
                        }, function (err, stations) {
                            if (err) {
                                errorType = err.type;
                                errorMessage = err.message;
                                return;
                            }
                            errorType = "";
                            errorMessage = "";
                            var latSum, latCount, lonSum, lonCount;
                            latSum = latCount = lonSum = lonCount = 0;
                            searchResults.clear();
                            for (var i = 0; i < stations.length; i++) {
                                latSum += stations[i].latitude;
                                lonSum += stations[i].longitude;
                                latCount += 1;
                                lonCount += 1;
                                searchResults.append({
                                    "stationID": stations[i].stationID,
                                    "address": stations[i].address,
                                    "latitude": stations[i].latitude,
                                    "longitude": stations[i].longitude,
                                    "qcStatus": stations[i].qcStatus
                                });
                            }
                            var latAvg = latSum / latCount;
                            var lonAvg = lonSum / lonCount;
                            stationMapSearcher.areaLat = latAvg;
                            stationMapSearcher.areaLon = lonAvg;
                            stationMap.center = QtPositioning.coordinate(latAvg, lonAvg);
                            stationMap.zoomLevel = Utils.zoomForCircle(stationMap.center, stationMapSearcher.searchRadius, stationMap, 5);
                        });
                    }
                }
            }
        }

        Loader {
            id: helperLoader
            Layout.fillWidth: true
            sourceComponent: stationMapSearcher.searchMode === "address" ? addressHelperComponent : stationMapSearcher.searchMode === "stationID" ? stationIDHelperComponent : latLonHelperComponent
        }

        Component {
            id: textSearchComponent
            PlasmaComponents.TextField {
                id: searchField
                Layout.fillWidth: true
                clearButtonShown: true
                placeholderText: stationMapSearcher.searchMode === "stationID" ? i18n("Enter Station") : i18n("Enter city, state, locality, or address")
                onTextChanged: {
                    stationMapSearcher.searchText = text.trim();
                }
                onAccepted: {
                    searchBtn.click();
                }
            }
        }

        Component {
            id: latLonSearchComponent

            PlasmaComponents.Label {
                text: i18n("Click or drag the marker on the map below.")
            }
        }

        Component {
            id: addressHelperComponent

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    text: i18n("Searching place:")
                }

                PlasmaComponents.ComboBox {
                    id: cityChoice
                    Layout.fillWidth: true
                    textRole: "address"
                    model: stationMapSearcher.availableCitiesModel
                    enabled: stationMapSearcher.availableCitiesModel.count > 0
                }

                PlasmaComponents.Button {
                    text: i18n("Choose")
                    enabled: cityChoice.currentIndex !== -1
                    onClicked: {
                        stationMapSearcher.searchResults.clear();
                        stationMapSearcher.areaLat = stationMapSearcher.availableCitiesModel.get(cityChoice.currentIndex).latitude;
                        stationMapSearcher.areaLon = stationMapSearcher.availableCitiesModel.get(cityChoice.currentIndex).longitude;
                        stationMap.center = QtPositioning.coordinate(stationMapSearcher.availableCitiesModel.get(cityChoice.currentIndex).latitude, stationMapSearcher.availableCitiesModel.get(cityChoice.currentIndex).longitude);
                        StationAPI.searchGeocode({
                            latitude: stationMapSearcher.availableCitiesModel.get(cityChoice.currentIndex).latitude,
                            longitude: stationMapSearcher.availableCitiesModel.get(cityChoice.currentIndex).longitude
                        }, {
                            language: Qt.locale().name.replace("_", "-")
                        }, function (err, stations) {
                            if (err) {
                                errorType = err.type;
                                errorMessage = err.message;
                                return;
                            }
                            var latMin, latMax, lonMin, lonMax;
                            latMin = lonMin = Infinity;
                            latMax = lonMax = -Infinity;
                            for (var i = 0; i < stations.length; i++) {
                                if (stations[i].latitude < latMin)
                                    latMin = stations[i].latitude;
                                if (stations[i].latitude > latMax)
                                    latMax = stations[i].latitude;
                                if (stations[i].longitude < lonMin)
                                    lonMin = stations[i].longitude;
                                if (stations[i].longitude > lonMax)
                                    lonMax = stations[i].longitude;
                                stationMapSearcher.searchResults.append({
                                    "stationID": stations[i].stationID,
                                    "address": stations[i].address,
                                    "latitude": stations[i].latitude,
                                    "longitude": stations[i].longitude,
                                    "qcStatus": stations[i].qcStatus
                                });
                            }
                            var minCoord = QtPositioning.coordinate(latMin, lonMin);
                            var maxCoord = QtPositioning.coordinate(latMax, lonMax);
                            var avgCoord = stationMap.center;

                            stationMapSearcher.searchRadius = Math.max(avgCoord.distanceTo(minCoord), avgCoord.distanceTo(maxCoord));
                            stationMap.zoomLevel = Utils.zoomForCircle(stationMap.center, stationMapSearcher.searchRadius, stationMap, 5);
                        });
                    }
                }
            }
        }

        Component {
            id: stationIDHelperComponent
            PlasmaComponents.Label {
                text: i18n("Searching by Weatherstation ID. Example: KGADACUL1")
            }
        }

        Component {
            id: latLonHelperComponent
            PlasmaComponents.Label {
                text: i18n("Selected latitude: %1, longitude: %2", stationMapSearcher.searchLat.toFixed(4), stationMapSearcher.searchLon.toFixed(4))
            }
        }

        PlasmaComponents.TextField {
            enabled: false
            Layout.fillWidth: true
            visible: stationMapSearcher.errorMessage.length > 0
            text: i18n("Error (%1): %2", stationMapSearcher.errorType, stationMapSearcher.errorMessage)
            color: "red"
        }

        Map {
            id: stationMap
            Layout.fillWidth: true
            Layout.fillHeight: true

            plugin: osmPlugin

            activeMapType: supportedMapTypes[supportedMapTypes.length - 1]

            center: QtPositioning.coordinate(20, 0)
            zoomLevel: 2

            WheelHandler {
                id: wheel
                // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
                // Magic Mouse pretends to be a trackpad but doesn't work with PinchHandler
                // and we don't yet distinguish mice and trackpads on Wayland either
                acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland" ? PointerDevice.Mouse | PointerDevice.TouchPad : PointerDevice.Mouse
                rotationScale: 1 / 120
                onWheel: function (event) {
                    // determine wheel steps (one step = 120)
                    var steps = 0;
                    if (event.angleDelta && event.angleDelta.y !== 0)
                        steps = event.angleDelta.y / 120;
                    else if (event.pixelDelta && event.pixelDelta.y !== 0)
                        steps = event.pixelDelta.y / 120;
                    if (steps === 0)
                        return;

                    // coordinate under the cursor before zoom
                    var mousePoint = Qt.point(event.x, event.y);
                    var coordBefore = stationMap.toCoordinate(mousePoint);

                    // adjust zoom
                    var newZoom = stationMap.zoomLevel + steps;
                    newZoom = Math.max(stationMap.minimumZoomLevel, Math.min(stationMap.maximumZoomLevel, newZoom));
                    stationMap.zoomLevel = newZoom;

                    // coordinate under the cursor after zoom
                    var coordAfter = stationMap.toCoordinate(mousePoint);

                    // shift center so the point under the cursor stays fixed
                    var newCenterLat = stationMap.center.latitude + (coordBefore.latitude - coordAfter.latitude);
                    var newCenterLon = stationMap.center.longitude + (coordBefore.longitude - coordAfter.longitude);
                    stationMap.center = QtPositioning.coordinate(newCenterLat, newCenterLon);

                    event.accepted = true;
                }
            }
            DragHandler {
                id: drag
                target: null
                onTranslationChanged: function (delta) {
                    stationMap.pan(-delta.x, -delta.y);
                }
            }
            Shortcut {
                enabled: stationMap.zoomLevel < stationMap.maximumZoomLevel
                sequence: StandardKey.ZoomIn
                onActivated: stationMap.zoomLevel = Math.round(stationMap.zoomLevel + 1)
            }
            Shortcut {
                enabled: stationMap.zoomLevel > stationMap.minimumZoomLevel
                sequence: StandardKey.ZoomOut
                onActivated: stationMap.zoomLevel = Math.round(stationMap.zoomLevel - 1)
            }

            MapCircle {
                id: searchCenterIndicator
                visible: stationMapSearcher.searchResults.count > 0 || stationMapSearcher.searchMode === "latlon"
                center: QtPositioning.coordinate(stationMapSearcher.searchMode === "latlon" ? stationMapSearcher.searchLat : stationMapSearcher.areaLat, stationMapSearcher.searchMode === "latlon" ? stationMapSearcher.searchLon : stationMapSearcher.areaLon)
                radius: stationMapSearcher.searchRadius
                color: "red"
                opacity: 0.2
                border.color: "red"
                border.width: 1
            }

            MapCircle {
                id: searchCenterBorderIndicator
                visible: stationMapSearcher.searchResults.count > 0 || stationMapSearcher.searchMode === "latlon"
                center: QtPositioning.coordinate(stationMapSearcher.searchMode === "latlon" ? stationMapSearcher.searchLat : stationMapSearcher.areaLat, stationMapSearcher.searchMode === "latlon" ? stationMapSearcher.searchLon : stationMapSearcher.areaLon)
                radius: stationMapSearcher.searchRadius
                color: "transparent"
                border.color: "red"
                border.width: 3
            }

            MapQuickItem {
                id: searchPointMarker
                coordinate: QtPositioning.coordinate(stationMapSearcher.searchLat, stationMapSearcher.searchLon)
                visible: stationMapSearcher.searchMode === "latlon"
                anchorPoint.x: searchIconImage.height / 2
                anchorPoint.y: searchIconImage.height / 2
                sourceItem: Image {
                    id: searchIconImage
                    source: Utils.getIcon("compass")
                    width: 24
                    height: 24
                }

                DragHandler {
                    id: searchPointDragHandler
                    target: null
                    onTranslationChanged: function (delta) {
                        var point = stationMap.fromCoordinate(searchPointMarker.coordinate);
                        point.x += delta.x;
                        point.y += delta.y;
                        var coord = stationMap.toCoordinate(point);
                        stationMapSearcher.searchLat = coord.latitude;
                        stationMapSearcher.searchLon = coord.longitude;
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: stationMapSearcher.searchMode === "latlon"
                onClicked: function (mouse) {
                    var coord = stationMap.toCoordinate(Qt.point(mouse.x, mouse.y));
                    stationMapSearcher.searchLat = coord.latitude;
                    stationMapSearcher.searchLon = coord.longitude;
                }
            }

            MapItemView {
                model: stationMapSearcher.searchResults
                delegate: MapQuickItem {
                    id: stationMarker
                    required property string stationID
                    required property string address
                    required property real latitude
                    required property real longitude
                    required property int qcStatus

                    coordinate: QtPositioning.coordinate(latitude, longitude)
                    anchorPoint.x: 2.5
                    anchorPoint.y: iconImage.height
                    sourceItem: Column {
                        Kirigami.Icon {
                            id: iconImage
                            source: Utils.getIcon("weather-station-2")
                            width: 32
                            height: 32
                            isMask: true
                            color: stationMapSearcher.selectedStation !== undefined && stationMapSearcher.selectedStation.stationID === stationMarker.stationID ? "red" : "black"
                        }
                        PlasmaComponents.Label {
                            text: stationMarker.stationID
                            font.pixelSize: 12
                            color: "black"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            padding: 2
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            selectedStation = {
                                "stationID": parent.stationID,
                                "address": parent.address,
                                "latitude": parent.latitude,
                                "longitude": parent.longitude,
                                "qcStatus": parent.qcStatus
                            };
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Kirigami.Icon {
                visible: stationMapSearcher.selectedStation !== undefined && stationMapSearcher.selectedStation.qcStatus === -1
                source: "documentinfo-symbolic"
                height: Kirigami.Units.iconSizes.smallMedium
                color: "orange"

                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    interactive: true
                    mainText: i18n("Warning")
                    subText: i18n("Station has failed quality checks and may provide unreliable data.")
                }
            }

            PlasmaComponents.TextField {
                visible: stationMapSearcher.stationHealth >= 0
                text: stationMapSearcher.stationHealth >= 0 ? i18n("Station Health: %1%", stationMapSearcher.stationHealth) : ""
                enabled: false
                color: stationMapSearcher.stationHealth >= 75 ? "green" : stationMapSearcher.stationHealth >= 40 ? "orange" : "red"
            }

            PlasmaComponents.Button {
                text: i18n("Test Station")
                enabled: stationMapSearcher.selectedStation !== undefined
                onClicked: {
                    StationAPI.isStationActive(stationMapSearcher.selectedStation.stationID, {}, function (err, healthObject) {
                        if (err) {
                            if (err.type === "no-data-found") {
                                stationMapSearcher.stationHealth = 0;
                                errorType = "";
                                errorMessage = "";
                                return;
                            }
                            // API backwards compatibility
                            try {
                                var parsedMsg = JSON.parse(err.message);
                                if (parsedMsg.hasOwnProperty("message") && parsedMsg.message === "no-data-found") {
                                    stationMapSearcher.stationHealth = 0;
                                    errorType = "";
                                    errorMessage = "";
                                    return;
                                }
                            } catch (e) {}
                            errorType = err.type;
                            errorMessage = err.message;
                            return;
                        }
                        errorType = "";
                        errorMessage = "";
                        if (healthObject.isActive) {
                            stationMapSearcher.stationHealth = Math.floor((healthObject.healthCount / 21) * 100);
                        } else {
                            stationMapSearcher.stationHealth = 0;
                        }
                    });
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: stationMapSearcher.selectedStation !== undefined ? i18n("Selected Station: %1 (%2)", stationMapSearcher.selectedStation.address, stationMapSearcher.selectedStation.stationID) : ""
            }
        }

        RowLayout {
            id: buttonsRow

            Layout.alignment: Qt.AlignRight

            PlasmaComponents.Button {
                icon.name: "dialog-ok"
                text: i18n("Confirm")
                enabled: stationMapSearcher.selectedStation !== undefined
                onClicked: {
                    stationMapSearcher.stationSelected(stationMapSearcher.selectedStation);
                    stationMapSearcher.close();
                }
            }

            PlasmaComponents.Button {
                icon.name: "dialog-cancel"
                text: i18n("Cancel")
                onClicked: {
                    stationMapSearcher.close();
                }
            }
        }
    }
}
