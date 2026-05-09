/*
 * Copyright 2026  Kevin Donnelly
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents

KCM.SimpleKCM {

    id: appearancePage
    property int cfg_layoutType
    property int cfg_widgetOrder
    property int cfg_planarLayoutType
    property int cfg_propIconSize
    property int cfg_forecastIconSize

    property alias cfg_propHeadPointSize: propHeadPointSize.value
    property alias cfg_propPointSize: propPointSize.value
    property alias cfg_tempPointSize: tempPointSize.value
    property alias cfg_propIconSizeIndex: propIconSize.currentIndex
    property alias cfg_forecastIconSizeIndex: forecastIconSize.currentIndex
    property alias cfg_topIconMargins: topIconMargins.value

    property string cfg_leftOuterMargin: plasmoid.configuration.leftOuterMargin
    property string cfg_innerMargin: plasmoid.configuration.innerMargin
    property string cfg_rightOuterMargin: plasmoid.configuration.rightOuterMargin
    property string cfg_topOuterMargin: plasmoid.configuration.topOuterMargin
    property string cfg_bottomOuterMargin: plasmoid.configuration.bottomOuterMargin

    onCfg_layoutTypeChanged: {
        switch (cfg_layoutType) {
            case 0:
                layoutTypeGroup.checkedButton = layoutTypeRadioHorizontal;
                break;
            case 1:
                layoutTypeGroup.checkedButton = layoutTypeRadioVertical;
                break;
            case 2:
                layoutTypeGroup.checkedButton = layoutTypeRadioCompact;
                break;
            default:
        }
    }

    QQC.ButtonGroup {
        id: layoutTypeGroup

        Component.onCompleted: {
            cfg_layoutTypeChanged()
        }
    }

    onCfg_widgetOrderChanged: {
        switch (cfg_widgetOrder) {
            case 0:
                widgetOrderGroup.checkedButton = widgetOrderIconFirst;
                break;
            case 1:
                widgetOrderGroup.checkedButton = widgetOrderTextFirst;
                break;
            default:
        }
    }

    QQC.ButtonGroup {
        id: widgetOrderGroup

        Component.onCompleted: {
            cfg_widgetOrderChanged()
        }
    }

    onCfg_planarLayoutTypeChanged: {
        switch (cfg_planarLayoutType) {
            case 0:
                planarLayoutTypeGroup.checkedButton = planarLayoutTypeRadioFull;
                break;
            case 1:
                planarLayoutTypeGroup.checkedButton = planarLayoutTypeRadioCompact;
                break;
            default:
        }
    }

    QQC.ButtonGroup {
        id: planarLayoutTypeGroup

        Component.onCompleted: {
            cfg_planarLayoutTypeChanged()
        }
    }

    onCfg_propIconSizeIndexChanged: {
        switch (cfg_propIconSizeIndex) {
            case 0:
                cfg_propIconSize = 16;
                break;
            case 1:
                cfg_propIconSize = 22;
                break;
            case 2:
                cfg_propIconSize = 32;
                break;
            case 3:
                cfg_propIconSize = 48;
                break;
            case 4:
                cfg_propIconSize = 64;
                break;
            case 5:
                cfg_propIconSize = 128;
                break;
            default:
        }
    }

    onCfg_forecastIconSizeIndexChanged: {
        switch (cfg_forecastIconSizeIndex) {
            case 0:
                cfg_forecastIconSize = 16;
                break;
            case 1:
                cfg_forecastIconSize = 22;
                break;
            case 2:
                cfg_forecastIconSize = 32;
                break;
            case 3:
                cfg_forecastIconSize = 48;
                break;
            case 4:
                cfg_forecastIconSize = 64;
                break;
            case 5:
                cfg_forecastIconSize = 128;
                break;
            default:
        }
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("General")
            Kirigami.FormData.isSection: true
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Planar layout") + ":"
            Kirigami.FormData.labelAlignment: Qt.AlignTop

            QQC.RadioButton {
                id: planarLayoutTypeRadioFull
                QQC.ButtonGroup.group: planarLayoutTypeGroup
                text: i18n("Full Representation")
                onCheckedChanged: if (checked) cfg_planarLayoutType = 0;
            }

            QQC.RadioButton {
                id: planarLayoutTypeRadioCompact
                QQC.ButtonGroup.group: planarLayoutTypeGroup
                text: i18n("Compact Representation")
                onCheckedChanged: if (checked) cfg_planarLayoutType = 1;
            }

            PlasmaComponents.Label {
                text: i18n("Used on the desktop or in a desktop grouper")
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Full Representation")
            Kirigami.FormData.isSection: true
        }

        QQC.SpinBox {
            id: propHeadPointSize

            editable: true

            Kirigami.FormData.label: i18n("Property header text size")
        }

        QQC.SpinBox {
            id: propPointSize

            editable: true

            Kirigami.FormData.label: i18n("Property text size")
        }

        QQC.SpinBox {
            id: tempPointSize

            editable: true

            Kirigami.FormData.label: i18n("Temperature text size")
        }

        QQC.ComboBox {
            id: forecastIconSize

            model: [i18n("small (16x16)"),i18n("smallMedium (22x22)"),i18n("medium (32x32)"),i18n("large (48x48)"),i18n("huge (64x64)"),i18n("enormous (128x128)")]

            Kirigami.FormData.label: i18n("Forecast icon size:")
        }

        QQC.ComboBox {
            id: propIconSize

            model: [i18n("small (16x16)"),i18n("smallMedium (22x22)"),i18n("medium (32x32)"),i18n("large (48x48)"),i18n("huge (64x64)"),i18n("enormous (128x128)")]

            Kirigami.FormData.label: i18n("Property icon size:")
        }

        QQC.SpinBox {
            id: topIconMargins

            editable: true

            Kirigami.FormData.label: i18n("Top panel icon margins:")
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Compact Representation")
            Kirigami.FormData.isSection: true
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Layout type") + ":"
            Kirigami.FormData.labelAlignment: Qt.AlignTop


            QQC.RadioButton {
                id: layoutTypeRadioHorizontal
                QQC.ButtonGroup.group: layoutTypeGroup
                text: i18n("Horizontal")
                onCheckedChanged: if (checked) cfg_layoutType = 0;
            }

            QQC.RadioButton {
                id: layoutTypeRadioVertical
                QQC.ButtonGroup.group: layoutTypeGroup
                text: i18n("Vertical")
                onCheckedChanged: if (checked) cfg_layoutType = 1;
            }

            QQC.RadioButton {
                id: layoutTypeRadioCompact
                QQC.ButtonGroup.group: layoutTypeGroup
                text: i18n("Compressed")
                onCheckedChanged: if (checked) cfg_layoutType = 2;
            }

            PlasmaComponents.Label {
                text: i18n("Layout type is not available in the system tray")
            }
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Widget order") + ":"
            Kirigami.FormData.labelAlignment: Qt.AlignTop


            QQC.RadioButton {
                id: widgetOrderIconFirst
                QQC.ButtonGroup.group: widgetOrderGroup
                text: i18n("Icon first")
                onCheckedChanged: if (checked) cfg_widgetOrder = 0;
            }
            QQC.RadioButton {
                id: widgetOrderTextFirst
                QQC.ButtonGroup.group: widgetOrderGroup
                text: i18n("Text first")
                onCheckedChanged: if (checked) cfg_widgetOrder = 1;
            }

            PlasmaComponents.Label {
                text: i18n("Widget order is not available in the system tray")
                wrapMode: Text.NoWrap
            }
        }

        Row {
            Kirigami.FormData.label: i18n("Top Margin") + ":"

            QQC.SpinBox {
                id: topOuterMargin
                stepSize: 1
                from: -999
                value: cfg_topOuterMargin
                to: 999
                onValueChanged: {
                    cfg_topOuterMargin = topOuterMargin.value
                }
            }
            PlasmaComponents.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("pixels", "px")
            }
        }

        Row {
            Kirigami.FormData.label: i18n("Bottom Margin") + ":"

            QQC.SpinBox {
                id: bottomOuterMargin
                stepSize: 1
                from: -999
                value: cfg_bottomOuterMargin
                to: 999
                onValueChanged: {
                    cfg_bottomOuterMargin = bottomOuterMargin.value
                }
            }
            PlasmaComponents.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("pixels", "px")
            }
        }

        Row {
            Kirigami.FormData.label: i18n("Left Margin") + ":"

            QQC.SpinBox {
                id: leftOuterMargin
                stepSize: 1
                from: -999
                value: cfg_leftOuterMargin
                to: 999
                onValueChanged: {
                    cfg_leftOuterMargin = leftOuterMargin.value
                }
            }
            PlasmaComponents.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("pixels", "px")
            }
        }

        Row {
            Kirigami.FormData.label: i18n("Right Margin") + ":"

            QQC.SpinBox {
                id: rightOuterMargin
                stepSize: 1
                from: -999
                value: cfg_rightOuterMargin
                to: 999
                onValueChanged: {
                    cfg_rightOuterMargin = rightOuterMargin.value
                }
            }
            PlasmaComponents.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("pixels", "px")
            }
        }

        Row {
            Kirigami.FormData.label: i18n("Inner Margin") + ":"

            QQC.SpinBox {
                id: innerMargin
                stepSize: 1
                from: -999
                value: cfg_innerMargin
                to: 999
                onValueChanged: {
                    cfg_innerMargin = innerMargin.value
                }
            }
            PlasmaComponents.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("pixels", "px")
            }
        }
    }
}