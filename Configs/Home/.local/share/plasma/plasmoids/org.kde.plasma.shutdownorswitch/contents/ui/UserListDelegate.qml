/*
 *  SPDX-FileCopyrightText: 2022 ivan (@ratijas) tkachenko <me@ratijas.tk>
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQml

import org.kde.config as KConfig
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents

ListDelegate {
    id: item

    property alias source: avatar.source

    iconItem: KirigamiComponents.AvatarButton {
        id: avatar

        anchors.fill: parent

        name: item.text

        // don't block mouse hover from the underlying ListView highlight
        enabled: KConfig.KAuthorized.authorizeControlModule("kcm_users")

        onClicked: KCMUtils.KCMLauncher.openSystemSettings("kcm_users")
    }
}
