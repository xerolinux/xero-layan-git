/*
 * SPDX-FileCopyrightText: 2018 Friedrich W. H. Kossebau <kossebau@kde.org>
 * Copyright               2025 Kevin Donnelly
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick

import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

GridLayout {
    id: iconAndTextRoot

    property alias iconSource: icon.source
    property alias text: label.text
    property alias active: icon.active

    readonly property int iconSize: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? height : width
    readonly property int minimumIconSize: Kirigami.Units.iconSizes.small

    columnSpacing: 0
    rowSpacing: 0

    function pointToPixel(pointSize: int): int {
        const pixelsPerInch = Screen.pixelDensity * 25.4
        return Math.round(pointSize / 72 * pixelsPerInch)
    }

    states: [
        State {
            name: "horizontalPanel"
            when: plasmoid.formFactor === PlasmaCore.Types.Horizontal

            PropertyChanges {
                target: iconAndTextRoot

                columns: 2
                rows: 1
            }

            PropertyChanges {
                target: icon

                Layout.fillWidth: false
                Layout.fillHeight: true

                Layout.minimumWidth: implicitMinimumIconSize
                Layout.minimumHeight: minimumIconSize
            }

            PropertyChanges {
                target: text

                Layout.fillWidth: false
                Layout.fillHeight: true

                Layout.minimumWidth: sizeHelper.paintedWidth
                Layout.maximumWidth: Layout.minimumWidth

                Layout.minimumHeight: 0
                Layout.maximumHeight: Infinity
            }

            PropertyChanges {
                target: sizeHelper

                font {
                    pixelSize: 1024
                }
                fontSizeMode: Text.VerticalFit
                // These magic values are taken from the digital clock, so that the
                // text sizes here are identical with various clock text sizes
                height: {
                    const textHeightScaleFactor = (parent.height > 26) ? 0.7: 0.9;
                    return Math.min (parent.height * textHeightScaleFactor, 3 * Kirigami.Theme.defaultFont.pixelSize);
                }
            }
        },
        State {
            name: "verticalPanel"
            when: plasmoid.formFactor === PlasmaCore.Types.Vertical

            PropertyChanges {
                target: iconAndTextRoot

                columns: 1
                rows: 2
            }

            PropertyChanges {
                target: icon

                Layout.fillWidth: true
                Layout.fillHeight: false

                Layout.minimumWidth: minimumIconSize
                Layout.minimumHeight: implicitMinimumIconSize
            }

            PropertyChanges {
                target: text

                Layout.fillWidth: true
                Layout.fillHeight: false

                Layout.minimumWidth: 0
                Layout.maximumWidth: Infinity

                Layout.minimumHeight: sizeHelper.paintedHeight
                Layout.maximumHeight: Layout.minimumHeight
            }

            PropertyChanges {
                target: sizeHelper

                font {
                    pixelSize: Kirigami.Units.gridUnit * 2
                }
                fontSizeMode: Text.HorizontalFit
                width: iconAndTextRoot.width
            }
        }
    ]

    Kirigami.Icon {
        id: icon

        isMask: plasmoid.configuration.applyColorScheme ? true : false
        color: Kirigami.Theme.textColor

        readonly property int implicitMinimumIconSize: Math.max(iconSize, minimumIconSize)
        // reset implicit size, so layout in free dimension does not stop at the default one
        implicitWidth: minimumIconSize
        implicitHeight: minimumIconSize
    }

    Item {
        id: text

        // Otherwise it takes up too much space while loading
        visible: label.text.length > 0

        Text {
            id: sizeHelper

            font {
                family: label.font.family
                weight: label.font.weight
                italic: label.font.italic
            }
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit / 2)
            wrapMode: Text.NoWrap

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors {
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
            }
            visible: false

            // pattern to reserve some constant space TODO: improve and take formatting/i18n into account
            text: "---" + label.text
            textFormat: Text.PlainText
        }

        PlasmaComponents.Label {
            id: label

            font {
                family: (plasmoid.configuration.autoFontAndSize || plasmoid.configuration.fontFamily.length === 0) ? Kirigami.Theme.defaultFont.family : plasmoid.configuration.fontFamily
                weight: plasmoid.configuration.autoFontAndSize ? Kirigami.Theme.defaultFont.weight : plasmoid.configuration.fontWeight
                italic: plasmoid.configuration.autoFontAndSize ? Kirigami.Theme.defaultFont.italic : plasmoid.configuration.italicText
                bold: plasmoid.configuration.autoFontAndSize ? Kirigami.Theme.defaultFont.bold : plasmoid.configuration.boldText
                underline: plasmoid.configuration.autoFontAndSize ? Kirigami.Theme.defaultFont.underline : plasmoid.configuration.underlineText
                strikeout: plasmoid.configuration.autoFontAndSize ? Kirigami.Theme.defaultFont.strikeout : plasmoid.configuration.strikeoutText
                pixelSize: plasmoid.configuration.autoFontAndSize ? 3 * Kirigami.Theme.defaultFont.pixelSize : pointToPixel(plasmoid.configuration.fontSize)
            }
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit / 2)
            fontSizeMode: Text.Fit
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap

            height: 0
            width: 0
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            anchors {
                fill: parent
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
            }
        }
    }
}
