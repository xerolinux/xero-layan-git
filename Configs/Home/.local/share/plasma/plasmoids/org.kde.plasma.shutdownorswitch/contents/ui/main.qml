/*
 *  SPDX-FileCopyrightText: 2024 Davide Sandonà <sandona.davide@gmail.com>
 *  SPDX-FileCopyrightText: 2015 Kai Uwe Broulik <kde@privat.broulik.de>
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.config as KConfig  // KAuthorized.authorizeControlModule
import org.kde.coreaddons as KCoreAddons // kuser
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import org.kde.plasma.private.sessions as Sessions

PlasmoidItem {
    id: root

    // from configuration
    readonly property bool showIcon: Plasmoid.configuration.showIcon
    readonly property bool showName: Plasmoid.configuration.showName
    readonly property bool showFullName: Plasmoid.configuration.showFullName
    readonly property bool showLockScreen: Plasmoid.configuration.showLockScreen
    readonly property bool showLogOut: Plasmoid.configuration.showLogOut
    readonly property bool showRestart: Plasmoid.configuration.showRestart
    readonly property bool showShutdown: Plasmoid.configuration.showShutdown
    readonly property bool showSuspend: Plasmoid.configuration.showSuspend
    readonly property bool showHybernate: Plasmoid.configuration.showHybernate
    readonly property bool showNewSession: Plasmoid.configuration.showNewSession
    readonly property bool showUsers: Plasmoid.configuration.showUsers
    readonly property bool showText: Plasmoid.configuration.showText

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge)
    
    readonly property string avatarIcon: kuser.faceIconUrl.toString()
    readonly property string displayedName: showFullName ? kuser.fullName : kuser.loginName

    // switchWidth: Kirigami.Units.gridUnit * 10
    // switchHeight: Kirigami.Units.gridUnit * 12

    toolTipTextFormat: Text.StyledText
    toolTipSubText: i18n("You are logged in as <b>%1</b>", displayedName)

    // revert to the Plasmoid icon if no face given
    Plasmoid.icon: kuser.faceIconUrl.toString() || (inPanel ? "system-switch-user-symbolic" : "preferences-system-users" )

    KCoreAddons.KUser {
        id: kuser
    }

    compactRepresentation: MouseArea {
        id: compactRoot

        // Taken from DigitalClock to ensure uniform sizing when next to each other
        readonly property bool tooSmall: Plasmoid.formFactor === PlasmaCore.Types.Horizontal && Math.round(2 * (compactRoot.height / 5)) <= Kirigami.Theme.smallFont.pixelSize

        Layout.minimumWidth: isVertical ? 0 : compactRow.implicitWidth
        Layout.maximumWidth: isVertical ? Infinity : Layout.minimumWidth
        Layout.preferredWidth: isVertical ? -1 : Layout.minimumWidth

        Layout.minimumHeight: isVertical ? label.height : Kirigami.Theme.smallFont.pixelSize
        Layout.maximumHeight: isVertical ? Layout.minimumHeight : Infinity
        Layout.preferredHeight: isVertical ? Layout.minimumHeight : Kirigami.Units.iconSizes.sizeForLabels * 2

        property bool wasExpanded
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded

        Row {
            id: compactRow

            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                id: shutdownIcon
                source: "system-shutdown"
                anchors.verticalCenter: parent.verticalCenter
                height: compactRoot.height - Math.round(Kirigami.Units.smallSpacing / 2)
                width: height
                visible: root.showIcon
            }

            PlasmaComponents.Label {
                id: label
                width: root.isVertical ? compactRoot.width : contentWidth
                height: root.isVertical ? contentHeight : compactRoot.height
                text: root.displayedName
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.NoWrap
                fontSizeMode: root.isVertical ? Text.HorizontalFit : Text.VerticalFit
                font.pixelSize: tooSmall ? Kirigami.Theme.defaultFont.pixelSize : Kirigami.Units.iconSizes.roundedIconSize(Kirigami.Units.gridUnit * 2)
                minimumPointSize: Kirigami.Theme.smallFont.pointSize
                visible: root.showName
            }
        }
    }

    fullRepresentation: Item {
        id: fullRoot

        implicitHeight: column.implicitHeight
        implicitWidth: column.implicitWidth

        Layout.preferredWidth: showText ? Kirigami.Units.gridUnit * 12 : Kirigami.Units.iconSizes.smallMedium * 1.6
        Layout.preferredHeight: implicitHeight
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight
        Layout.maximumWidth: Layout.preferredWidth
        Layout.maximumHeight: Screen.height / 2

        Sessions.SessionManagement {
            id: sm
        }

        Sessions.SessionsModel {
            id: sessionsModel
        }

        ColumnLayout {
            id: column

            anchors.fill: parent
            spacing: 0

            UserListDelegate {
                id: currentUserItem
                text: root.displayedName
                subText: i18n("Current user")
                source: root.avatarIcon
                hoverEnabled: false
                visible: showUsers
            }

            PlasmaComponents.ScrollView {
                id: scroll

                Layout.fillWidth: true
                Layout.fillHeight: true

                // HACK: workaround for https://bugreports.qt.io/browse/QTBUG-83890
                PlasmaComponents.ScrollBar.horizontal.policy: PlasmaComponents.ScrollBar.AlwaysOff

                ListView {
                    id: userList
                    model: sessionsModel

                    focus: true
                    interactive: true
                    keyNavigationWraps: true

                    delegate: UserListDelegate {
                        width: ListView.view.width

                        activeFocusOnTab: true

                        text: {
                            if (!model.session) {
                                return i18nc("Nobody logged in on that session", "Unused")
                            }

                            if (model.realName && root.showFullName) {
                                return model.realName
                            }

                            return model.name
                        }
                        source: model.icon

                        KeyNavigation.up: index === 0 ? currentUserItem.nextItemInFocusChain() : userList.itemAtIndex(index - 1)
                        KeyNavigation.down: index === userList.count - 1 ? newSessionButton : userList.itemAtIndex(index + 1)

                        Accessible.description: i18nc("@action:button", "Switch to User %1", text)

                        onClicked: sessionsModel.switchUser(model.vtNumber, sessionsModel.shouldLock)
                    }
                }
            }

            ActionListDelegate {
                id: newSessionButton
                text: showText ? i18nc("@action", "New Session") : ""
                icon.name: "system-switch-user"
                visible: sessionsModel.canStartNewSession && showNewSession
                KeyNavigation.up: userList.count > 0 ? userList.itemAtIndex(userList.count - 1) : currentUserItem.nextItemInFocusChain()
                KeyNavigation.down: lockScreenButton
                onClicked: sessionsModel.startNewSession(sessionsModel.shouldLock)
            }

            ActionListDelegate {
                id: lockScreenButton
                text: showText ? i18nc("@action", "Lock Screen") : ""
                icon.name: "system-lock-screen"
                visible: sm.canLock && showLockScreen
                KeyNavigation.up: newSessionButton
                KeyNavigation.down: leaveButton
                onClicked: sm.lock()
            }

            ActionListDelegate {
                id: leaveButton
                text: showText ? i18nc("@action", "Log Out") : ""
                icon.name: "system-log-out"
                visible: sm.canLogout && showLogOut
                KeyNavigation.up: lockScreenButton
                onClicked: sm.requestLogout(0) // do not show the Leave screen
            }

            ActionListDelegate {
                id: rebootButton
                text: showText ? i18nc("@action", "Reboot...") : ""
                icon.name: "system-reboot"
                visible: sm.canReboot && showRestart
                onClicked: sm.requestReboot(0) // do not show the Leave screen
            }

            ActionListDelegate {
                id: shutdownButton
                text: showText ? i18nc("@action", "Shutdown") : ""
                icon.name: "system-shutdown"
                visible: sm.canShutdown && showShutdown
                onClicked: sm.requestShutdown(0) // do not show the Leave screen
            }

            ActionListDelegate {
                id: suspendButton
                text: showText ? i18nc("@action", "Suspend") : ""
                icon.name: "system-suspend"
                visible: sm.canSuspend && showSuspend
                onClicked: sm.suspend()
            }

            ActionListDelegate {
                id: hybernateButton
                text: showText ? i18nc("@action", "Hybernate") : ""
                icon.name: "system-suspend-hibernate"
                visible: sm.canSuspendThenHibernate && showHybernate
                onClicked: sm.suspendThenHibernate()
            }
        }

        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded) {
                    sessionsModel.reload();
                }
            }
        }
    }
}
