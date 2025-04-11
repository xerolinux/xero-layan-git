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
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/utils.js" as Utils
import "lib"

ColumnLayout {
    id: fullRoot

    height: parent.height
    width: parent.width

    spacing: Kirigami.Units.smallSpacing

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {
            console.log("[debug] [FullRep.qml] " + msg);
        }
    }

    ConfigBtn {
        id: configBtn

        visible: appState == showCONFIG

        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    }

    PlasmaComponents.Label {
        id: errorMsg

        visible: appState == showERROR

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        text: "Error: " + errorStr
        wrapMode: Text.WordWrap

        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    PlasmaComponents.Label {
        id: loadingMsg

        visible: appState == showLOADING

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        text: i18n("Loading data...")

        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    TopPanel {
        id: topPanel

        visible: appState == showDATA

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
    }

    SwitchPanel {
        visible: appState == showDATA

        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    BottomPanel {
        id: bottomPanel

        visible: appState == showDATA

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignBottom
    }
}
