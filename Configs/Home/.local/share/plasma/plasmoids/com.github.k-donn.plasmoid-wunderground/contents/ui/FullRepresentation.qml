/*
 * Copyright 2025  Kevin Donnelly
 * Copyright 2013  Marco Martin <mart@kde.org>
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
import org.kde.plasma.core as PlasmaCore
import "../code/utils.js" as Utils
import "lib"

ColumnLayout {
    id: fullRoot

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

    ColumnLayout {
        id: errorDisplay
        visible: appState == showERROR
        spacing: Kirigami.Units.smallSpacing

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "dialog-error"
                width: Kirigami.Units.iconSizes.medium
                height: width
            }

            PlasmaComponents.Label {
                text: i18n("Sorry! The widget ran into a network error: ") + errorType
                font.bold: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        ConfigBtn {
            Layout.alignment: Qt.AlignHCenter
        }

        PlasmaComponents.Button {
            id: copyButton

            text: i18nd("plasma_shell_org.kde.plasma.desktop", "Copy to Clipboard")
            icon.name: "edit-copy"
            onClicked: {
                textArea.selectAll();
                textArea.copy();
                textArea.deselect();
            }

            PlasmaCore.ToolTipArea {
                anchors.fill: parent
                mainText: parent.text
                textFormat: Text.PlainText
            }
        }

        PlasmaComponents.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            PlasmaComponents.TextArea {
                id: textArea
                text: errorStr
                wrapMode: Text.WordWrap
                readOnly: true
                selectByMouse: true
                font.family: "monospace"
            }
        }
    }

    Item {
        id: loadingDisplay
        visible: appState == showLOADING

        Layout.fillWidth: true
        Layout.fillHeight: true

        PlasmaComponents.BusyIndicator {
            anchors.centerIn: parent
            running: visible
        }
    }

    TopPanel {
        id: topPanel

        visible: appState == showDATA

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
    }

    SwitchPanel {
        id: switchRoot

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
