/*
    SPDX-FileCopyrightText: 2012 Gregor Taetzner <gregor@freenet.de>
    SPDX-FileCopyrightText: 2020 Ivan Čukić <ivan.cukic at kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.draganddrop as DND
import org.kde.kirigami as Kirigami
import org.kde.activities as Activities

import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    width: Kirigami.Units.iconSizes.large
    height: Kirigami.Units.iconSizes.large

    Layout.maximumWidth: Infinity
    Layout.maximumHeight: Infinity

    Layout.preferredWidth : icon.width + Kirigami.Units.smallSpacing + (root.showActivityName ? name.implicitWidth + Kirigami.Units.smallSpacing : 0)

    Layout.minimumWidth: 0
    Layout.minimumHeight: 0

    readonly property bool inVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property string defaultIconName: "dialog-layers"

    Plasmoid.icon: Plasmoid.configuration.icon

    preferredRepresentation: fullRepresentation

    DND.DropArea {
        id: dropArea
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: executable.exec(plasmoid.configuration.command)
            onPressed: executable.exec(plasmoid.configuration.command)
        }

        PlasmaCore.ToolTipArea {
            id: tooltip
            anchors.fill: parent
            mainText: i18n("Toggle Overview")
        }

        Kirigami.Icon {
            id: icon
            height: Math.min(parent.height, parent.width)
            width: valid ? height : 0
            visible: plasmoid.configuration.menuLabel === "" || plasmoid.configuration.icon !== ""
            source: plasmoid.configuration.icon
        }

        PlasmaComponents3.Label {
            id: name

            anchors {
                left: icon.right
                leftMargin: Kirigami.Units.smallSpacing
            }
            height: parent.height
            width: implicitWidth
            visible: !(plasmoid.configuration.menuLabel === "") && !root.inVertical

            verticalAlignment: Text.AlignVCenter

            text: plasmoid.configuration.menuLabel
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
        }

        function exec(cmd) {
            executable.connectSource(cmd)
        }
    }

}
