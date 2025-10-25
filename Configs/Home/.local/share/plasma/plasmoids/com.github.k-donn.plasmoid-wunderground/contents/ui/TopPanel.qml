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
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/utils.js" as Utils

RowLayout {
    id: topPanelRoot

    Layout.preferredHeight: preferredIconSize

    readonly property int preferredIconSize: plasmoid.configuration.detailsIconSize

    Item {
        Layout.alignment: Qt.AlignLeft | Qt.AlignTop

        Layout.fillWidth: true
        Layout.preferredWidth: 1

        Kirigami.Icon {
            id: topPanelIcon

            source: Utils.getConditionIcon(iconCode)

            isMask: plasmoid.configuration.applyColorScheme ? true : false
            color: Kirigami.Theme.textColor

            implicitHeight: preferredIconSize
            implicitWidth: implicitHeight
        }
    }

    PlasmaComponents.Label {
        id: tempOverview

        text: showForecast ? i18n("High: %1 Low: %2", Utils.currentTempUnit(Utils.toUserTemp(currDayHigh), plasmoid.configuration.forecastPrecision), Utils.currentTempUnit(Utils.toUserTemp(currDayLow), plasmoid.configuration.forecastPrecision)) : i18n("Loading...")

        verticalAlignment: Text.AlignBottom
        horizontalAlignment: Text.AlignHCenter

        Layout.fillWidth: true
        Layout.preferredWidth: 1
    }

    PlasmaComponents.Label {
        id: narrativeLabel

        text: conditionNarrative ? conditionNarrative : i18n("Loading...")

        verticalAlignment: Text.AlignBottom
        horizontalAlignment: Text.AlignRight

        Layout.fillWidth: true
        Layout.preferredWidth: 1
    }
}
