/*
 * SPDX-FileCopyrightText: 2018 Friedrich W. H. Kossebau <kossebau@kde.org>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */


import QtQuick
import QtQuick.Layouts
import org.kde.ksvg as KSvg
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

GridLayout {
    id: iconAndTextRoot

    property alias iconSource: icon.source
    property alias text: label.text
    property alias paintWidth: sizeHelper.paintedWidth
    property alias paintHeight: sizeHelper.paintedHeight

    property bool vertical: false
    property bool useUserHeight: userHeight > 0

    property int userHeight: plasmoid.configuration.compactPointSize
    property int targetHeight: useUserHeight ? userHeight : verticalFixedHeight

    readonly property bool showTemperature: !inTray

    readonly property int verticalFixedHeight: 21

    readonly property int minimumIconSize: Kirigami.Units.iconSizes.small

    columns: iconAndTextRoot.vertical ? 1 : 2
    rows: iconAndTextRoot.vertical ? 2 : 1

    columnSpacing: 0
    rowSpacing: 0

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {console.log("[debug] [IconText.qml] " + msg)}
    }

    onPaintWidthChanged: {
        // TODO: use property binding or states inside of "text" instead of this?
        text.Layout.minimumWidth = iconAndTextRoot.vertical ? 0 : sizeHelper.paintedWidth
        text.Layout.maximumWidth = iconAndTextRoot.vertical ? Infinity : text.Layout.minimumWidth

        text.Layout.minimumHeight = iconAndTextRoot.vertical ? sizeHelper.paintedHeight : 0
        text.Layout.maximumHeight = iconAndTextRoot.vertical ? text.Layout.minimumHeight : Infinity

        // Loaded within scope of compactRoot; can access compactRoot properties!
        compactRoot.Layout.minimumWidth = (text.Layout.minimumWidth + icon.Layout.minimumWidth)
    }

    Kirigami.Icon {
        id: icon

        readonly property int implicitMinimumIconSize: Math.max((iconAndTextRoot.vertical ? iconAndTextRoot.width : iconAndTextRoot.height), minimumIconSize)
        // reset implicit size, so layout in free dimension does not stop at the default one
        implicitWidth: minimumIconSize
        implicitHeight: minimumIconSize

        Layout.fillWidth: iconAndTextRoot.vertical
        Layout.fillHeight: !iconAndTextRoot.vertical
        Layout.minimumWidth: iconAndTextRoot.vertical ? minimumIconSize : implicitMinimumIconSize
        Layout.minimumHeight: iconAndTextRoot.vertical ? implicitMinimumIconSize : minimumIconSize
    }

    Item {
        id: text

        // Otherwise it takes up too much space while loading
        visible: label.text.length > 0 && showTemperature

        Layout.fillWidth: iconAndTextRoot.vertical
        Layout.fillHeight: !iconAndTextRoot.vertical
        Layout.minimumWidth: iconAndTextRoot.vertical ? 0 : sizeHelper.paintedWidth
        Layout.maximumWidth: iconAndTextRoot.vertical ? Infinity : Layout.minimumWidth

        Layout.minimumHeight: iconAndTextRoot.vertical ? sizeHelper.paintedHeight : 0
        Layout.maximumHeight: iconAndTextRoot.vertical ? Layout.minimumHeight : Infinity

        Text {
            id: sizeHelper

            font {
                family: label.font.family
                weight: label.font.weight
                italic: label.font.italic
                underline: label.font.underline
                pixelSize: targetHeight
            }
            minimumPixelSize: 1
            fontSizeMode: iconAndTextRoot.vertical ? Text.HorizontalFit : Text.FixedSize
            wrapMode: Text.NoWrap

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors {
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
            }

            smooth: true

            height: {
                var textHeightScaleFactor = 0.71;
                return Math.min (targetHeight * textHeightScaleFactor, 3 * targetHeight);
            }

            visible: false

            // pattern to reserve some constant space TODO: improve and take formatting/i18n into account
            text: "888.8 °X"
        }

        PlasmaComponents.Label {
            id: label

            visible: showTemperature

            font {
                family: plasmoid.configuration.compactFamily
                weight: plasmoid.configuration.compactWeight ? Font.Bold : Font.Normal
                italic: plasmoid.configuration.compactItalic
                underline: plasmoid.configuration.compactUnderline
                pixelSize: targetHeight
                pointSize: -1
            }

            minimumPixelSize: 1

            fontSizeMode: iconAndTextRoot.vertical ? Text.HorizontalFit : Text.FixedSize
            wrapMode: Text.NoWrap

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            smooth: true

            anchors {
                fill: parent
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
            }
        }
    }
}
