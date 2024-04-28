/*
 * Copyright 2024  Kevin Donnelly
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
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: appearanceConfig

    property alias cfg_compactPointSize: compactPointSize.value
    property alias cfg_propHeadPointSize: propHeadPointSize.value
    property alias cfg_propPointSize: propPointSize.value
    property alias cfg_tempPointSize: tempPointSize.value
    property alias cfg_tempAutoColor: tempAutoColor.checked
    property alias cfg_showForecastDefault: showForecastDefault.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            text: i18n("Compact Representation")
        }

        ConfigFontFamily {
            id: compactFontFamily

            configKey: "compactFamily"

            Kirigami.FormData.label: i18n("Font")
        }

        SpinBox {
            id: compactPointSize

            editable: true

            Kirigami.FormData.label: i18n("Font size (0px=scale to widget)")
        }

        ConfigTextFormat {
            Kirigami.FormData.label: i18n("Font styles")
        }

        Kirigami.Separator {}

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            text: i18n("Full Representation")
        }

        SpinBox {
            id: propHeadPointSize

            editable: true

            Kirigami.FormData.label: i18n("Property header text size")
        }

        SpinBox {
            id: propPointSize

            editable: true

            Kirigami.FormData.label: i18n("Property text size")
        }

        SpinBox {
            id: tempPointSize

            editable: true

            Kirigami.FormData.label: i18n("Temperature text size")
        }

        CheckBox {
            id: tempAutoColor

            Kirigami.FormData.label: i18n("Auto-color temperature:")
        }

        CheckBox {
            id: showForecastDefault

            Kirigami.FormData.label: i18n("Show forecast page on load:")
        }

    }
}
