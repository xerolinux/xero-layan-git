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
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: switchRoot

    PlasmaComponents.TabBar {
        id: tabBar

        Layout.fillWidth: true

        currentIndex: plasmoid.configuration.defaultLoadPage

        PlasmaComponents.TabButton {
            id: detailsTabButton

            text: i18n("Weather Details")
        }

        PlasmaComponents.TabButton {
            id: forecastTabButton

            text: i18n("Forecast")
        }

        PlasmaComponents.TabButton {
            id: dayChartButton

            text: i18n("Day Chart")
        }

        PlasmaComponents.TabButton {
            id: moreInfoTabButton

            text: i18n("More Info")
        }
    }

    SwipeView {
        id: swipeView

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignCenter

        clip: true

        currentIndex: tabBar.currentIndex

        DetailsItem {
            id: weatherItem

            Layout.preferredWidth: parent.width
            Layout.preferredHeight: parent.height * 0.75

            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        }

        ForecastItem {
            id: forecastItem

            Layout.preferredWidth: parent.width
            Layout.preferredHeight: parent.height * 0.75

            Layout.alignment: Qt.AlignTop
        }

        DayChartItem {
            id: dayChartItem

            Layout.preferredWidth: parent.width
            Layout.preferredHeight: parent.height * 0.75

            Layout.alignment: Qt.AlignTop
        }

        MoreInfoItem {
            id: moreInfoItem

            Layout.preferredWidth: parent.width
            Layout.preferredHeight: parent.height * 0.75

            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        }

        onCurrentIndexChanged: {
            tabBar.setCurrentIndex(currentIndex);
        }
    }
}
