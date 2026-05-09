/*
 * Copyright 2015  Martin Kotelnik <clearmartin@seznam.cz>
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
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import QtQuick.Layouts
import org.kde.plasma.plasmoid

Loader {
    id: compactRepresentation

    anchors.fill: parent

    readonly property bool vertical: (Plasmoid.formFactor == PlasmaCore.Types.Vertical)

    property int defaultWidgetSize: -1
    property int widgetOrder: root.widgetOrder
    property int layoutType: root.layoutType

    sourceComponent: layoutType === 2 ? compactItem : widgetOrder === 1 ? compactItemReverse : compactItem

    Layout.fillWidth: compactRepresentation.vertical
    Layout.fillHeight: !compactRepresentation.vertical
    Layout.minimumWidth: item.Layout.minimumWidth
    Layout.minimumHeight: item.Layout.minimumHeight

    Component {
        id: compactItem
        CompactItem {
            vertical: compactRepresentation.vertical
        }
    }

    Component {
        id: compactItemReverse
        CompactItemReverse {
            vertical: compactRepresentation.vertical
        }
    }

    PlasmaComponents.BusyIndicator {
        id: busyIndicator
        anchors.fill: parent
        visible: false
        running: false

        states: [
            State {
                name: 'loading'
                when: root.appState === showLOADING

                PropertyChanges {
                    target: busyIndicator
                    visible: true
                    running: true
                }

                PropertyChanges {
                    target: compactItem
                }
            }
        ]
    }

    MouseArea {
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        hoverEnabled: true

        onClicked: {
            root.expanded = !root.expanded;
        }

        PlasmaCore.ToolTipArea {
            id: toolTipArea
            anchors.fill: parent
            active: !root.expanded
            interactive: true
            mainText: weatherData["stationID"]
            subText: root.toolTipSubText
            textFormat: Text.RichText
        }
    }

    Component.onCompleted: {
        if ((defaultWidgetSize === -1) && (compactRepresentation.width > 0 ||  compactRepresentation.height)) {
            defaultWidgetSize = Math.min(compactRepresentation.width, compactRepresentation.height)
        }
    }
}