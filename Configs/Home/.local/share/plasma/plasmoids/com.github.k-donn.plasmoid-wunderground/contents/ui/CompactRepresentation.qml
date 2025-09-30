/*
 * SPDX-FileCopyrightText: 2018 Friedrich W. H. Kossebau <kossebau@kde.org>
 * Copyright               2025 Kevin Donnelly
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import "../code/utils.js" as Utils

Loader {
    id: compactRoot

    sourceComponent: inTray ? (plasmoid.configuration.showSystemTrayTemp ? iconAndTextTrayComponent : iconComponent) : (plasmoid.configuration.showCompactTemp ? iconAndTextComponent : iconComponent)

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {
            console.log("[debug] [CompactRep.qml] " + msg);
        }
    }

    Layout.minimumWidth: item.Layout.minimumWidth
    Layout.minimumHeight: item.Layout.minimumHeight

    states: [
        State {
            name: "horizontalPanel"
            when: plasmoid.formFactor === PlasmaCore.Types.Horizontal

            PropertyChanges {
                target: compactRoot

                Layout.fillWidth: false
                Layout.fillHeight: true
            }

            PropertyChanges {
                target: soleIcon

                minIconSize: Math.max(compactRoot.height, Kirigami.Units.iconSizes.small)

                Layout.minimumWidth: minIconSize
                Layout.minimumHeight: Kirigami.Units.iconSizes.small
            }
        },
        State {
            name: "verticalPanel"
            when: plasmoid.formFactor === PlasmaCore.Types.Vertical

            PropertyChanges {
                target: compactRoot

                Layout.fillWidth: false
                Layout.fillHeight: true
            }

            PropertyChanges {
                target: soleIcon

                minIconSize: Math.max(compactRoot.width, Kirigami.Units.iconSizes.small)

                Layout.minimumWidth: Kirigami.Units.iconSizes.small
                Layout.minimumHeight: minIconSize
            }
        }
    ]

    MouseArea {
        id: compactMouseArea
        anchors.fill: parent

        hoverEnabled: true

        onClicked: {
            root.expanded = !root.expanded;
        }
    }

    Component {
        id: iconAndTextComponent

        IconAndTextItem {
            id: iconAndTextItem

            iconSource: Utils.getConditionIcon(iconCode)
            text: appState == showDATA ? Utils.currentTempUnit(Utils.toUserTemp(weatherData["details"]["temp"]), plasmoid.configuration.tempPrecision) : "--- °X"
        }
    }

    Component {
        id: iconComponent

        Kirigami.Icon {
            id: soleIcon

            isMask: plasmoid.configuration.applyColorScheme ? true : false
            color: Kirigami.Theme.textColor

            source: Utils.getConditionIcon(iconCode)
            active: compactMouseArea.containsMouse
            // reset implicit size, so layout in free dimension does not stop at the default one
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
        }
    }

    Component {
        id: iconAndTextTrayComponent

        Item {
            id: iconWithOverlayItem
            width: Kirigami.Units.iconSizes.medium
            height: Kirigami.Units.iconSizes.medium

            Kirigami.Icon {
                id: weatherIcon
                anchors.fill: parent
                isMask: plasmoid.configuration.applyColorScheme ? true : false
                color: Kirigami.Theme.textColor
                source: Utils.getConditionIcon(iconCode)
                active: compactMouseArea.containsMouse
            }

            Rectangle {
                id: tempOverlay
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: parent.width * 0.6
                height: parent.height * 0.4
                color: Kirigami.Theme.backgroundColor
                opacity: 1
                radius: 4

                Text {
                    id: tempText
                    anchors.centerIn: parent
                    text: appState == showDATA ? Utils.toUserTemp(weatherData["details"]["temp"]).toFixed(0) + "°" : "---°"
                    color: Kirigami.Theme.textColor
                    font.pixelSize: parent.height
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
