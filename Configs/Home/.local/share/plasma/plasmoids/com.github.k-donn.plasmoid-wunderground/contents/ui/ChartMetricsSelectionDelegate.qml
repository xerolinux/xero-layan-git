/*
 * Copyright 2022  Rafal (Raf) Liwoch
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
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import "../code/utils.js" as Utils

Component {
    id: chartMetricsSelectionDelegate

    Column {
        Kirigami.Icon {
            id: iconHolder

            Layout.minimumWidth: Kirigami.Units.gridUnit * 1.3
            Layout.minimumHeight: Kirigami.Units.gridUnit * 1.3
            width: Layout.minimumWidth
            height: Layout.minimumHeight

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    iconsListView.currentIndex = index;
                }
                onPressed: {
                    currentLegendText = availableReadings[index];
                    lineChart.nameSource.value = currentLegendText;
                    if (staticRange.includes(currentLegendText)) {
                        lineChart.yRange.automatic = false;
                        lineChart.yRange.from = 0;
                        lineChart.yRange.to = 100;
                    } else if (currentLegendText == "pressure") {
                        var pressureUnit = Utils.rawPresUnit();
                        lineChart.yRange.automatic = false;
                        // mmHG is the final unit
                        lineChart.yRange.from = (pressureUnit === "hPa" || pressureUnit === "mb") ? 970 : pressureUnit === "inHG" ? 28.6 : 727;
                        lineChart.yRange.to = (pressureUnit === "hPa" || pressureUnit === "mb") ? 1040 : pressureUnit === "inHG" ? 30.7 : 780;
                    } else {
                        lineChart.yRange.automatic = true;
                    }
                    lineChart.valueSources[0].roleName = currentLegendText;

                    var majorFreq = Math.ceil(rangeValDict[currentLegendText] / 4);

                    if (majorFreq < 2) {
                        majorFreq = 2;
                    } else if (majorFreq % 2 === 1) {
                        majorFreq += 1;
                    }

                    horizontalLines.major.frequency = majorFreq
                    horizontalLines.minor.frequency = majorFreq / 2;
                }
            }

            isMask: plasmoid.configuration.applyColorScheme ? true : false
            color: Kirigami.Theme.textColor

            source: Utils.getChartIcon(availableReadings[index])

        }

    }

}
