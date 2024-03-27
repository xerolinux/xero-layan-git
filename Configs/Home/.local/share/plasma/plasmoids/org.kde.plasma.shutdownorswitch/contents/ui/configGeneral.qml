/*
 * SPDX-FileCopyrightText: 2024 Davide Sandonà <sandona.davide@gmail.com>
 * SPDX-FileCopyrightText: 2015 Kai Uwe Broulik <kde@privat.broulik.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15 as QtControls
import QtQuick.Layouts
import QtQuick.Dialogs

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property bool cfg_showIcon
    property bool cfg_showName
    property bool cfg_showFullName
    property alias cfg_showNewSession: showNewSession.checked
    property alias cfg_showLockScreen: showLockScreen.checked
    property alias cfg_showLogOut: showLogOut.checked
    property alias cfg_showRestart: showRestart.checked
    property alias cfg_showShutdown: showShutdown.checked
    property alias cfg_showSuspend: showSuspend.checked
    property alias cfg_showHybernate: showHybernate.checked
    property alias cfg_showUsers: showUsers.checked
    property alias cfg_showText: showText.checked
    property alias cfg_icon: icon.text

    Kirigami.FormLayout {
        QtControls.ButtonGroup {
            id: nameGroup
        }

        QtControls.RadioButton {
            id: showFullNameRadio

            Kirigami.FormData.label: i18nc("@title:label", "Username style:")

            QtControls.ButtonGroup.group: nameGroup
            text: i18nc("@option:radio", "Full name (if available)")
            checked: cfg_showFullName
            onClicked: if (checked) cfg_showFullName = true;
        }

        QtControls.RadioButton {
            QtControls.ButtonGroup.group: nameGroup
            text: i18nc("@option:radio", "Login username")
            checked: !cfg_showFullName
            onClicked: if (checked) cfg_showFullName = false;
        }


        Item {
            Kirigami.FormData.isSection: true
        }


        QtControls.ButtonGroup {
            id: layoutGroup
        }

        QtControls.RadioButton {
            id: showOnlyNameRadio

            Kirigami.FormData.label: i18nc("@title:label", "Show:")

            QtControls.ButtonGroup.group: layoutGroup
            text: i18nc("@option:radio", "Name")
            checked: cfg_showName && !cfg_showIcon
            onClicked: {
                if (checked) {
                    cfg_showName = true;
                    cfg_showIcon = false;
                }
            }
        }

        QtControls.RadioButton {
            id: showOnlyFaceRadio

            QtControls.ButtonGroup.group: layoutGroup
            text: i18nc("@option:radio", "Icon")
            checked: !cfg_showName && cfg_showIcon
            onClicked: {
                if (checked) {
                    cfg_showName = false;
                    cfg_showIcon = true;
                }
            }
        }

        QtControls.RadioButton {
            id: showBothRadio

            QtControls.ButtonGroup.group: layoutGroup
            text: i18nc("@option:radio", "Icon and Name")
            checked: cfg_showName && cfg_showIcon
            onClicked: {
                if (checked) {
                    cfg_showName = true;
                    cfg_showIcon = true;
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@title:label", "Icon:")

            QtControls.TextField {
                id: icon
                implicitWidth: 300
            }

            QtControls.Button {
                icon.name: "folder"
                onClicked: {
                    iconDialog.open()
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }


        QtControls.CheckBox {
            Kirigami.FormData.label: i18nc("@title:label", "Menu Entries:")
            id: showUsers
            text: i18nc("@option:check", "Users")
        }

        QtControls.CheckBox {
            id: showNewSession
            text: i18nc("@option:check", "New Session")
        }

        QtControls.CheckBox {
            id: showLockScreen
            text: i18nc("@option:check", "Lock Screen")
        }

        QtControls.CheckBox {
            id: showLogOut
            text: i18nc("@option:check", "Log Out")
        }

        QtControls.CheckBox {
            id: showRestart
            text: i18nc("@option:check", "Restart")
        }

        QtControls.CheckBox {
            id: showShutdown
            text: i18nc("@option:check", "Shutdown")
        }

        QtControls.CheckBox {
            id: showSuspend
            text: i18nc("@option:check", "Suspend")
        }

        QtControls.CheckBox {
            id: showHybernate
            text: i18nc("@option:check", "Hybernate")
        }

        QtControls.CheckBox {
            Kirigami.FormData.label: i18nc("@title:label", "Show text on Menu Entries:")
            id: showText
            text: ""
        }

    }
}
