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

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: delegateRoot

    required property int index
    required property string stationID
    required property string address
    required property real latitude
    required property real longitude
    required property bool selected

    signal selectStation()
    signal deleteStation()
    signal editStation(string newName)

    width: parent.width
    height: 36

    Rectangle {
        anchors.fill: parent
        color: delegateRoot.selected ? Kirigami.Theme.highlightColor : (delegateRoot.index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor)
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
        border.width: 1
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Station ID Column
        PlasmaComponents.Label {
            text: delegateRoot.stationID
            Layout.preferredWidth: 120
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            clip: true
        }

        Rectangle {
            width: 1
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            height: parent.height
        }

        // Station Name Column (Editable)
        Item {
            Layout.preferredWidth: 160
            Layout.fillHeight: true

            PlasmaComponents.Label {
                anchors.centerIn: parent
                text: delegateRoot.address
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                clip: true
                visible: !nameEditor.visible
                width: parent.width - 8
            }

            QQC.TextField {
                id: nameEditor
                anchors.centerIn: parent
                text: delegateRoot.address
                width: parent.width - 8
                height: 28
                visible: false
                horizontalAlignment: Text.AlignHCenter

                Keys.onEscapePressed: {
                    nameEditor.visible = false
                    text = delegateRoot.address
                }
            }

            QQC.Button {
                anchors.right: nameEditor.right
                anchors.verticalCenter: nameEditor.verticalCenter
                visible: nameEditor.visible
                icon.name: "dialog-ok-apply"
                onClicked: {
                    nameEditor.visible = false
                    if (nameEditor.text !== delegateRoot.address) {
                        delegateRoot.editStation(nameEditor.text)
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: !nameEditor.visible
                onDoubleClicked: {
                    nameEditor.visible = true
                    nameEditor.forceActiveFocus()
                    nameEditor.selectAll()
                }
            }
        }

        Rectangle {
            width: 1
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            height: parent.height
        }

        // Latitude Column
        PlasmaComponents.Label {
            text: delegateRoot.latitude
            Layout.preferredWidth: 80
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            clip: true
        }

        Rectangle {
            width: 1
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            height: parent.height
        }

        // Longitude Column
        PlasmaComponents.Label {
            text: delegateRoot.longitude
            Layout.preferredWidth: 80
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            clip: true
        }

        Rectangle {
            width: 1
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            height: parent.height
        }

        // Actions Column
        RowLayout {
            Layout.preferredWidth: 140
            spacing: 2

            QQC.Button {
                icon.name: "dialog-ok-apply"
                enabled: !delegateRoot.selected
                implicitWidth: 32
                PlasmaComponents.ToolTip.text: i18n("Select")
                PlasmaComponents.ToolTip.visible: hovered
                onClicked: delegateRoot.selectStation()
                Layout.leftMargin: 8
            }

            QQC.Button {
                icon.name: "document-edit"
                implicitWidth: 32
                PlasmaComponents.ToolTip.text: i18n("Edit Name")
                PlasmaComponents.ToolTip.visible: hovered
                onClicked: {
                    nameEditor.visible = true
                    nameEditor.forceActiveFocus()
                    nameEditor.selectAll()
                }
            }

            QQC.Button {
                icon.name: "dialog-cancel"
                implicitWidth: 32
                PlasmaComponents.ToolTip.text: i18n("Remove")
                PlasmaComponents.ToolTip.visible: hovered
                onClicked: delegateRoot.deleteStation()
            }
        }
    }
}
