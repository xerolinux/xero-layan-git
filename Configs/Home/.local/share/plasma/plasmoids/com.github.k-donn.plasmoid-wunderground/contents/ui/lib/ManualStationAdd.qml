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
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Window {
    id: manualAdd
    signal stationSelected(var station)
    signal open

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    flags: Qt.Dialog
    modality: Qt.WindowModal

    width: Kirigami.Units.gridUnit * 17
    height: Kirigami.Units.gridUnit * 6

    SystemPalette {
        id: syspal
    }

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {
            console.log("[debug] [ManualStationAdd.qml] " + msg);
        }
    }

    onOpen: {
        manualAdd.visible = true;
    }

    title: i18n("Add Station...")
    color: syspal.window

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        PlasmaComponents.TextField {
            id: stationInput
            Layout.fillWidth: true
            placeholderText: i18n("Enter station ID")
            onAccepted: {
                if (text.trim().length > 0) {
                    manualAdd.stationSelected(text.trim());
                    manualAdd.visible = false;
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Button {
                text: i18n("Confirm")
                enabled: stationInput.text.trim().length > 0
                onClicked: {
                    manualAdd.stationSelected(stationInput.text.trim());
                    manualAdd.visible = false;
                }
            }

            PlasmaComponents.Button {
                text: i18n("Cancel")
                onClicked: {
                    manualAdd.visible = false;
                }
            }
        }
    }
}
