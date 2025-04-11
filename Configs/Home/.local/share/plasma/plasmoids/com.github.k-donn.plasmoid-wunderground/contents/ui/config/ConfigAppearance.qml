/*
 * Copyright 2025  Kevin Donnelly
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
import QtQuick.Dialogs as QtDialogs
import org.kde.kcmutils as KCM
import QtQuick.Controls as QQC
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

import "../lib" as Lib

KCM.SimpleKCM {
    id: appearanceConfig

    property alias cfg_autoFontAndSize: autoFontAndSizeRadioButton.checked
    property alias cfg_fontFamily: fontDialog.fontChosen.family
    property alias cfg_boldText: fontDialog.fontChosen.bold
    property alias cfg_italicText: fontDialog.fontChosen.italic
    property alias cfg_underlineText: fontDialog.fontChosen.underline
    property alias cfg_strikeoutText: fontDialog.fontChosen.strikeout
    property alias cfg_fontWeight: fontDialog.fontChosen.weight
    property alias cfg_fontStyleName: fontDialog.fontChosen.styleName
    property alias cfg_fontSize: fontDialog.fontChosen.pointSize


    property alias cfg_showCompactTemp: showCompactTemp.checked
    property alias cfg_propHeadPointSize: propHeadPointSize.value
    property alias cfg_propPointSize: propPointSize.value
    property alias cfg_tempPointSize: tempPointSize.value
    property alias cfg_useSystemThemeIcons: useSystemIcons.checked
    property alias cfg_applyColorScheme: applyColorScheme.checked
    property alias cfg_topIconMargins: topIconMargins.value
    property alias cfg_tempAutoColor: tempAutoColor.checked
    property alias cfg_defaultLoadPage: defaultLoadPage.currentIndex
    property alias cfg_showPresTrend: showPresTrend.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Separator {
            Kirigami.FormData.label: i18nd("plasma_applet_org.kde.desktopcontainment", "Show Background")
            Kirigami.FormData.isSection: true
        }

        Lib.BackgroundToggle {}

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Compact Representation")
            Kirigami.FormData.isSection: true
        }

        QQC.CheckBox {
            id: showCompactTemp

            Kirigami.FormData.label: i18n("Show temperature:")
        }

        QQC.ButtonGroup {
            buttons: [autoFontAndSizeRadioButton, manualFontAndSizeRadioButton]
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.FormData.label: i18n("Text display:")

            QQC.RadioButton {
                id: autoFontAndSizeRadioButton
                text: i18n("Automatic")
            }

            Kirigami.Icon {
                source: "dialog-question-symbolic"

                isMask: plasmoid.configuration.applyColorScheme ? true : false
                color: Kirigami.Theme.textColor

                Layout.maximumHeight: autoFontAndSizeRadioButton.height * 0.8

                PlasmaCore.ToolTipArea {
                    anchors.fill: parent

                    interactive: true
                    subText: i18n("Text will follow the system font and expand to fill the available space.")
                }
            }
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            QQC.RadioButton {
                id: manualFontAndSizeRadioButton
                text: i18n("Manual")
                checked: !cfg_autoFontAndSize
                onClicked: {
                    if (cfg_fontFamily === "") {
                        fontDialog.fontChosen = Kirigami.Theme.defaultFont
                    }
                }
            }

            QQC.Button {
                text: i18n("Choose Style…")
                icon.name: "settings-configure"
                enabled: manualFontAndSizeRadioButton.checked
                onClicked: {
                    fontDialog.selectedFont = fontDialog.fontChosen;
                    fontDialog.open();
                }
            }

        }

        QtDialogs.FontDialog {
            id: fontDialog
            title: i18n("Choose a Font")
            modality: Qt.WindowModal
            parentWindow: appearanceConfig.Window.window

            property font fontChosen: Qt.font()

            onAccepted: {
                fontChosen = selectedFont;
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

        Lib.ConfigComboBox {
            configKey: "detailsIconSize"

            model: [
                { value: 16, text: i18n("small (16x16)")},
                { value: 22, text: i18n("smallMedium (22x22)")},
                { value: 32, text: i18n("medium (32x32)")},
                { value: 48, text: i18n("large (48x48)")},
                { value: 64, text: i18n("huge (64x64)")},
                { value: 128, text: i18n("enormous (128x128)")}
            ]

            Kirigami.FormData.label: i18n("Details icon size:")
        }

        QQC.SpinBox {
            id: topIconMargins

            editable: true

            Kirigami.FormData.label: i18n("Top panel icon margins:")
        }

        QQC.CheckBox {
            id: useSystemIcons

            Kirigami.FormData.label: i18n("Use system theme icons:")
        }

        QQC.CheckBox {
            id: applyColorScheme

            Kirigami.FormData.label: i18n("Apply system colors to icons:")
        }

        QQC.CheckBox {
            id: tempAutoColor

            Kirigami.FormData.label: i18n("Auto-color temperature:")
        }

        QQC.ComboBox {
            id: defaultLoadPage

            model: [i18n("Weather Details"), i18n("Forecast"), i18n("Day Chart"), i18n("More Info")]

            Kirigami.FormData.label: i18n("Default page shown:")
        }
        QQC.CheckBox {
            id: showPresTrend

            Kirigami.FormData.label: i18n("Show pressure trend:")
        }
    }
}
