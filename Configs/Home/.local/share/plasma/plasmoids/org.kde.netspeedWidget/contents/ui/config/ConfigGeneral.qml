/*
 * Copyright 2016  Daniel Faust <hessijames@gmail.com>
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
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_showSeparately: showSeparately.checked
    property alias cfg_showLowSpeeds: showLowSpeeds.checked
    property string cfg_speedLayout: 'auto'
    property bool cfg_swapDownUp: false
    property alias cfg_showIcons: showIcons.checked
    property alias cfg_showUnits: showUnits.checked
    property string cfg_speedUnits: 'bytes'
    property alias cfg_shortUnits: shortUnits.checked
    property alias cfg_fontSize: fontSize.value
    property alias cfg_updateInterval: updateInterval.value
    property alias cfg_customColors: customColors.checked
    property alias cfg_byteColor: byteColorPicker.chosenColor
    property alias cfg_kilobyteColor: kilobyteColorPicker.chosenColor
    property alias cfg_megabyteColor: megabyteColorPicker.chosenColor
    property alias cfg_gigabyteColor: gigabyteColorPicker.chosenColor

    GridLayout {
        columns: 2

        Label {
            text: i18n('Layout:')
        }

        ComboBox {
            id: speedLayout
            textRole: 'label'
            model: [
                {
                    'label': i18n('Automatic'),
                    'value': 'auto'
                },
                {
                    'label': i18n('Above each other'),
                    'value': 'rows'
                },
                {
                    'label': i18n('Side by side'),
                    'value': 'columns'
                }
            ]
            onCurrentIndexChanged: cfg_speedLayout = model[currentIndex]['value']

            Component.onCompleted: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i]['value'] == plasmoid.configuration.speedLayout) {
                        speedLayout.currentIndex = i
                    }
                }
            }
        }

        Label {
            text: i18n('Display order:')
        }

        ComboBox {
            id: displayOrder
            textRole: 'label'
            model: [
                {
                    'label': i18n('Show upload speed first'),
                    'value': 'up'
                },
                {
                    'label': i18n('Show download speed first'),
                    'value': 'down'
                }
            ]
            onCurrentIndexChanged: cfg_swapDownUp = model[currentIndex]['value'] == 'up'

            Component.onCompleted: {
                if (plasmoid.configuration.swapDownUp) {
                    displayOrder.currentIndex = 0
                } else {
                    displayOrder.currentIndex = 1
                }
            }
        }

        Label {
            text: i18n('Speed units:')
        }

        ComboBox {
            id: speedUnits
            textRole: 'label'
            model: [
                {
                    'label': i18n('Bits'),
                    'value': 'bits'
                },
                {
                    'label': i18n('Bytes'),
                    'value': 'bytes'
                }
            ]
            onCurrentIndexChanged: cfg_speedUnits = model[currentIndex]['value']

            Component.onCompleted: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i]['value'] == plasmoid.configuration.speedUnits) {
                        speedUnits.currentIndex = i
                    }
                }
            }

            property string currentVal: model[currentIndex]['value']
        }

        CheckBox {
            id: showUnits
            text: i18n('Show speed units')
            Layout.columnSpan: 2
        }

        CheckBox {
            id: shortUnits
            text: i18n('Use shortened speed units')
            Layout.columnSpan: 2
            enabled: showUnits.checked
        }

        CheckBox {
            id: showIcons
            text: i18n('Show upload and download icons')
            Layout.columnSpan: 2
        }

        CheckBox {
            id: showSeparately
            text: i18n('Show download and upload speed separately')
            Layout.columnSpan: 2
        }

        CheckBox {
            id: showLowSpeeds
            text: i18n('Show speeds below 1 kb/s')
            Layout.columnSpan: 2
        }

        Label {
            text: i18n('Font size:')
        }

        SpinBox {
            id: fontSize
            from: 10
            to: 200
            stepSize: 5
            textFromValue: function(value) { return value + ' %'; }
            valueFromText: function(text) { return Number(text.remove(RegExp(' %$'))); }
        }

        Label {
            text: i18n('Update interval:')
        }

        SpinBox {
            id: updateInterval
            from: 1
            to: 10
            stepSize: 1
            textFromValue: function(value) { return value + ' s'; }
            valueFromText: function(text) { return Number(text.remove(RegExp(' s$'))); }
        }

        GroupBox {
            label: CheckBox {
                id: customColors
                text: 'Use custom colors'
            }
            Layout.columnSpan: 2

            GridLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                columns: 2

                Label {
                    text: {
                        if (speedUnits.currentVal === 'bits') {
                            return shortUnits.checked ? 'b' : 'b/s:'
                        } else {
                            return shortUnits.checked ? 'B' : 'B/s:'
                        }
                    }
                    Layout.alignment: Qt.AlignRight
                }

                ColorPicker {
                    id: byteColorPicker
                }

                Label {
                    text: {
                        if (speedUnits.currentVal === 'bits') {
                            return shortUnits.checked ? 'k:' : 'kb/s:'
                        } else {
                            return shortUnits.checked ? 'K:' : 'KiB/s:'
                        }
                    }
                    Layout.alignment: Qt.AlignRight
                }

                ColorPicker {
                    id: kilobyteColorPicker
                }

                Label {
                    text: {
                        if (speedUnits.currentVal === 'bits') {
                            return shortUnits.checked ? 'm:' : 'Mb/s:'
                        } else {
                            return shortUnits.checked ? 'M:' : 'MiB/s:'
                        }
                    }
                    Layout.alignment: Qt.AlignRight
                }

                ColorPicker {
                    id: megabyteColorPicker
                }

                Label {
                    text: {
                        if (speedUnits.currentVal === 'bits') {
                            return shortUnits.checked ? 'g:' : 'Gb/s:'
                        } else {
                            return shortUnits.checked ? 'G:' : 'GiB/s:'
                        }
                    }
                    Layout.alignment: Qt.AlignRight
                }

                ColorPicker {
                    id: gigabyteColorPicker
                }
            }
        }
    }
}
