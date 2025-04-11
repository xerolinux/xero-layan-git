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
import QtQuick.Controls as QQC
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: debugConfig

    property alias cfg_logConsole: logConsole.checked
    property alias cfg_useLegacyAPI: useLegacyAPI.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC.CheckBox {
            id: logConsole

            Kirigami.FormData.label: i18n("Write to console.log:")
        }

        QQC.CheckBox {
            id: useLegacyAPI

            Kirigami.FormData.label: i18n("Use Legacy Forecast API:")
        }
    }
}
