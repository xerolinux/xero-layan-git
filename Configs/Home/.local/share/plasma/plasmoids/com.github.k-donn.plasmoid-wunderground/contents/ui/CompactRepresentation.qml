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

    sourceComponent: (!inTray && plasmoid.configuration.showCompactTemp) ? iconAndTextComponent : iconComponent

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
}
