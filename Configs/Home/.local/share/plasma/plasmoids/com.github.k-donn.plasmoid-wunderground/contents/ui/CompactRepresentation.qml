/*
 * SPDX-FileCopyrightText: 2018 Friedrich W. H. Kossebau <kossebau@kde.org>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../code/utils.js" as Utils

ColumnLayout {
    id: compactRoot

    readonly property bool vertical: (plasmoid.formFactor == PlasmaCore.Types.Vertical)

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {console.log("[debug] [CompactRep.qml] " + msg)}
    }


    IconAndTextItem {
        vertical: compactRoot.vertical
        iconSource: iconCode
        text: appState == showDATA ? Utils.currentTempUnit(weatherData["details"]["temp"].toFixed(1)) : "---.-° X"

        Layout.fillWidth: compactRoot.vertical
        Layout.fillHeight: !compactRoot.vertical

        MouseArea {
            id: compactMouseArea
            anchors.fill: parent

            hoverEnabled: true

            onClicked: root.expanded = !root.expanded
        }
    }


    // Component {
    //     id: iconComponent

    //     PlasmaCore.SvgItem {
    //         readonly property int minIconSize: Math.max((compactRoot.vertical ? compactRoot.width : compactRoot.height), Kirigami.Units.iconSizes.small)

    //         svg: PlasmaCore.Svg {
    //             id: svg
    //             imagePath: plasmoid.file("", "icons/" + iconCode + ".svg")
    //         }

    //         // reset implicit size, so layout in free dimension does not stop at the default one
    //         implicitWidth: Kirigami.Units.iconSizes.small
    //         implicitHeight: Kirigami.Units.iconSizes.small
    //         Layout.minimumWidth: compactRoot.vertical ? Kirigami.Units.iconSizes.small : minIconSize
    //         Layout.minimumHeight: compactRoot.vertical ? minIconSize : Kirigami.Units.iconSizes.small
    //     }
    // }


    // Component {
    //     id: iconAndTextComponent

    //     IconAndTextItem {
    //         vertical: compactRoot.vertical
    //         iconSource: plasmoid.file("", "icons/" + iconCode + ".svg")
    //         text: appState == showDATA ? Utils.currentTempUnit(weatherData["details"]["temp"]) : "---.-° X"
    //     }
    // }

}
