/*
 *    SPDX-FileCopyrightText: zayronxio
 *    SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid 2.0

Item {
    id: root
    property bool globalBool: true
    HelperCard {
        id: background
        isShadow: false
        width: parent.width
        height:  parent.height
        //opacity: enabledCustomColor || enabledColor ? 0.8 : 1.0
        visible: globalBool
    }
    HelperCard {
        id: shadow
        isShadow: true
        width: parent.width
        height:  parent.height
        visible: globalBool
        opacity: 0.7//shadowOpacity/10
    }
}
