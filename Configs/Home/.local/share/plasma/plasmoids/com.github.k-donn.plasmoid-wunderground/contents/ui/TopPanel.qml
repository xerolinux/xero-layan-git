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
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import "../code/utils.js" as Utils

RowLayout {
    id: topPanelRoot

    readonly property int preferredIconSize: plasmoid.configuration.detailsIconSize

    Kirigami.Icon {
        id: topPanelIcon

        source: Utils.getConditionIcon(iconCode)

        isMask: plasmoid.configuration.applyColorScheme ? true : false
        color: Kirigami.Theme.textColor

        Layout.margins: plasmoid.configuration.topIconMargins

        Layout.minimumWidth: preferredIconSize
        Layout.minimumHeight: preferredIconSize
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight
    }

    PlasmaComponents.Label {
        id: tempOverview

        text: showForecast ? i18n("High: %1 Low: %2", Utils.currentTempUnit(Utils.toUserTemp(currDayHigh),plasmoid.configuration.forecastPrecision), Utils.currentTempUnit(Utils.toUserTemp(currDayLow),plasmoid.configuration.forecastPrecision)) : i18n("Loading...")

        verticalAlignment: Text.AlignBottom
        horizontalAlignment: Text.AlignHCenter

        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
    }

    PlasmaComponents.Label {
        id: currStation

        text: conditionNarrative ? conditionNarrative : i18n("Loading...")

        verticalAlignment: Text.AlignBottom
        horizontalAlignment: Text.AlignRight

        Layout.alignment: Qt.AlignRight
    }
}
