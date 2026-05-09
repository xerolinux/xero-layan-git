/*
 * Copyright 2022  Rafal (Raf) Liwoch
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
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.quickcharts as Charts
import org.kde.quickcharts.controls as ChartsControls
import "../code/utils.js" as Utils

ColumnLayout {
    id: todayRoot

    property string currentLegendText: "temperature"
    property var staticRange: ["cloudCover", "humidity", "precipitationChance"]
    property var availableReadings: ["temperature", "uvIndex", "pressure", "cloudCover", "humidity", "precipitationChance", "precipitationRate", "snowPrecipitationRate", "wind"]

    RowLayout {
        Item {
            Layout.fillWidth: true
        }

        Repeater {
            model: availableReadings

            Layout.fillWidth: true

            PlasmaComponents.Label {
                required property int index

                id: iconHolder

                Layout.minimumWidth: Kirigami.Units.gridUnit * 1.5
                Layout.minimumHeight: Kirigami.Units.gridUnit * 1.5
                width: Layout.minimumWidth
                height: Layout.minimumHeight


                font.family: "weather-icons"
                font.pixelSize: Layout.minimumHeight
                text: Utils.getConditionIcon(availableReadings[index])
                color: Kirigami.Theme.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    PlasmaCore.ToolTipArea {
                        anchors.fill: parent
                        subText: propInfoDict[availableReadings[index]].name
                    }

                    onEntered: {
                        hoverOverlay.opacity = 0.2
                    }
                    onExited: {
                        hoverOverlay.opacity = 0
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

                        horizontalLines.major.frequency = majorFreq;
                        horizontalLines.minor.frequency = majorFreq / 2;
                    }
                }

                Rectangle {
                    anchors.fill: parent

                    color: Kirigami.Theme.highlightColor
                    opacity: (todayRoot.currentLegendText === availableReadings[index]) ? 0.3 : 0
                    radius: 4
                }

                Rectangle {
                    id: hoverOverlay
                    anchors.fill: parent

                    color: "white"
                    radius: 4
                    opacity: 0
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.leftMargin: 3 * Kirigami.Units.gridUnit
        Layout.rightMargin: 3 * Kirigami.Units.gridUnit
        Layout.topMargin: 2 * Kirigami.Units.gridUnit
        Layout.bottomMargin: 3 * Kirigami.Units.gridUnit

        Item {
            id: mainChartItem

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 7 * 1.3
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Charts.LineChart {
                id: lineChart

                z: 999
                anchors.fill: parent
                smooth: true
                yRange.automatic: true
                yRange.increment: 5
                fillOpacity: 0.5
                indexingMode: Charts.Chart.IndexEachSource
                valueSources: [
                    Charts.ModelSource {
                        roleName: "temperature"
                        model: hourlyModel
                    }
                ]

                colorSource: Charts.SingleValueSource {
                    value: Kirigami.Theme.disabledTextColor
                }

                nameSource: Charts.SingleValueSource {
                    value: currentLegendText
                }

                pointDelegate: Item {
                    id: pointItem

                    Rectangle {
                        anchors.centerIn: parent
                        width: textSize.normal
                        height: width
                        radius: width / 2
                        color: parent.Charts.LineChart.color
                        ToolTip.visible: mouse.containsMouse
                        ToolTip.text: "%1: %2".arg(propInfoDict[parent.Charts.LineChart.name].name).arg(parent.Charts.LineChart.value)

                        MouseArea {
                            id: mouse

                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }

            ChartsControls.GridLines {
                id: horizontalLines

                anchors.fill: lineChart
                chart: lineChart
                opacity: 1
                direction: ChartsControls.GridLines.Vertical // KDE uses a different convention for horz/vert lines?
                major.frequency: 2
                major.lineWidth: 2
                major.color: Qt.rgba(0.8, 0.8, 0.8, 0.1)
                minor.frequency: 1
                minor.lineWidth: 1
                minor.color: Qt.rgba(0.8, 0.8, 0.8, 0.1)
            }

            ChartsControls.GridLines {
                id: verticalLines

                anchors.fill: lineChart
                chart: lineChart
                opacity: 1
                major.frequency: 3
                major.lineWidth: 1
                major.color: Qt.rgba(0.8, 0.8, 0.8, 0.3)
                minor.frequency: 1
                minor.lineWidth: 1
                minor.color: Qt.rgba(0.8, 0.8, 0.8, 0.1)
            }

            ChartsControls.AxisLabels {
                id: yAxisLabels

                direction: ChartsControls.AxisLabels.VerticalBottomTop

                anchors {
                    right: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    rightMargin: (textSize.tiny) / 2
                }

                delegate: PlasmaComponents.Label {
                    id: yAxisLabelId

                    font.pointSize: textSize.tiny
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        var chunks = (ChartsControls.AxisLabels.label.toString()).split(".");
                        if (chunks.length > 1) {
                            return chunks[0] + "." + chunks[1].substring(0, 2);
                        } else {
                            return ChartsControls.AxisLabels.label;
                        }
                    }
                }

                source: Charts.ChartAxisSource {
                    chart: lineChart
                    axis: Charts.ChartAxisSource.YAxis
                    itemCount: 5
                }
            }

            ChartsControls.AxisLabels {
                id: xAxisLabels

                constrainToBounds: false
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                anchors {
                    left: parent.left
                    right: parent.right
                    top: lineChart.bottom
                }

                delegate: PlasmaComponents.Label {
                    id: xAxisLabelId

                    rotation: 0
                    font.pointSize: textSize.tiny
                    text: "<b>" + Qt.formatDateTime(hourlyModel.count > 0 ? hourlyModel.get(ChartsControls.AxisLabels.label).time : new Date(), plasmoid.configuration.dayChartTimeFormat) + "</b>"
                }

                source: Charts.ChartAxisSource {
                    chart: lineChart
                    axis: Charts.ChartAxisSource.XAxis
                    itemCount: 8
                }
            }

            ChartsControls.AxisLabels {
                id: xAxisLabelsWeatherDay

                constrainToBounds: false
                direction: ChartsControls.AxisLabels.HorizontalLeftRight

                anchors {
                    left: lineChart.left
                    right: lineChart.right
                    bottom: lineChart.top
                    bottomMargin: Kirigami.Units.gridUnit / 4
                }

                source: Charts.ChartAxisSource {
                    chart: lineChart
                    axis: Charts.ChartAxisSource.XAxis
                    itemCount: 8
                }

                delegate: Loader {
                    id: xAxisLabelWeatherDayId

                    sourceComponent: plasmoid.configuration.useSystemThemeIcons ? systemIconLabelComponent : fontIconLabelComponent

                    onLoaded: {
                        item.weatherElement = hourlyModel.get(ChartsControls.AxisLabels.label)
                    }
                }

                Component {
                    id: systemIconLabelComponent

                    Kirigami.Icon {
                        property var weatherElement

                        source: Utils.getConditionIcon(weatherElement !== undefined ? weatherElement.iconCode : 32, true)
                        width: Kirigami.Units.iconSizes.smallMedium
                        height: Kirigami.Units.iconSizes.smallMedium
                    }
                }
                
                Component {
                    id: fontIconLabelComponent

                    PlasmaComponents.Label {
                        property var weatherElement

                        color: Kirigami.Theme.textColor
                        text: Utils.getConditionIcon(weatherElement !== undefined ? weatherElement.iconCode : 32)
                        font.family: "weather-icons"
                        font.pixelSize: Kirigami.Units.iconSizes.smallMedium
                        width: Kirigami.Units.iconSizes.smallMedium
                        height: Kirigami.Units.iconSizes.smallMedium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            PlasmaComponents.Label {
                id: legendLabel

                property var unitInterval: (currentLegendText === "precipitationRate" || currentLegendText === "snowPrecipitationRate" ? i18nc("per 12 hours, please keep it short", "/12h") : "")

                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                // text: `${dictVals[currentLegendText].name} ${Utils.wrapInBrackets(dictVals[currentLegendText].unit, unitInterval)}`
                text: propInfoDict[currentLegendText].name + " " + Utils.wrapInBrackets(propInfoDict[currentLegendText].unit, unitInterval)

                anchors {
                    top: xAxisLabels.bottom
                    horizontalCenter: lineChart.horizontalCenter
                }

                font {
                    weight: Font.Bold
                    pointSize: textSize.small
                }
            }
        }
    }
}
