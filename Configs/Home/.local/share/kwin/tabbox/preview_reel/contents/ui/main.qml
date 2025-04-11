import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0
import org.kde.kwin 2.0 as KWin

// Reused code from the Grid Thumbnail switcher.
// https://techbase.kde.org/Development/Tutorials/KWin/WindowSwitcher
KWin.Switcher {
    id: tabBox
    currentIndex: thumbnailListView.currentIndex

    PlasmaCore.Dialog {
        id: dialog
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.5 - dialogMainItem.width * 0.5
        y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - dialogMainItem.height * 0.5

        mainItem: Item {
            id: dialogMainItem

            property int maxWidth: tabBox.screenGeometry.width * 0.75
            property int maxHeight: tabBox.screenGeometry.height * 0.9
            property real screenFactor: tabBox.screenGeometry.width / tabBox.screenGeometry.height
            property int listRows: thumbnailListView.count

            width: thumbnailListView.width
            height: thumbnailListView.height

            clip: true


            // just to get the margin sizes
            PlasmaCore.FrameSvgItem {
                id: hoverItem
                imagePath: "widgets/viewitem"
                prefix: "hover"
                visible: false
            }

            ListView {
                id: thumbnailListView
                model: tabBox.model
                orientation: ListView.Vertical
                anchors.fill: parent

                property int captionRowHeight: 22
                property int thumbnailWidth: dialogMainItem.maxWidth
                property int thumbnailHeight: thumbnailWidth * (1.0/dialogMainItem.screenFactor)
                width: hoverItem.margins.left + thumbnailWidth + hoverItem.margins.right
                height: hoverItem.margins.top + captionRowHeight + thumbnailHeight + hoverItem.margins.bottom

                delegate: Item {
                    width: thumbnailListView.width
                    height: thumbnailListView.height

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            parent.select_relative(0)
                        }
                        onWheel: {
                            if (wheel.angleDelta.x < 0) {
                                parent.select_relative(1)
                            } else {
                                parent.select_relative(-1)
                            }

                        }
                    }

                    function select_relative(x) {
                        thumbnailListView.currentIndex = (index + thumbnailListView.count + x) % thumbnailListView.count;
                        thumbnailListView.currentIndexChanged(thumbnailListView.currentIndex);
                    }


                    Item {
                        z: 0
                        anchors.fill: parent
                        anchors.leftMargin: hoverItem.margins.left
                        anchors.topMargin: hoverItem.margins.top
                        anchors.rightMargin: hoverItem.margins.right
                        anchors.bottomMargin: hoverItem.margins.bottom


                        RowLayout {
                            id: captionRow
                            anchors.top: parent.top
                            anchors.right: parent.right
                            height: thumbnailListView.captionRowHeight
                            spacing: 4

                            QIconItem {
                                id: iconItem
                                icon: model.icon
                                width: parent.height
                                height: parent.height
                                state: index == thumbnailListView.currentIndex ? QIconItem.ActiveState : QIconItem.DefaultState
                            }

                            PlasmaComponents.Label {
                                text: model.caption
                                height: parent.height
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            PlasmaComponents.Label {
                                text: model.desktopName
                                color: "green"
                                height: parent.height
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            PlasmaComponents.ToolButton {
                                visible: model.closeable && typeof tabBox.model.close !== 'undefined' || false
                                iconSource: 'window-close-symbolic'
                                onClicked: {
                                    console.log(tabBox.model, index, model.closeable, tabBox.model.close)
                                    tabBox.model.close(index)
                                }
                            }
                        }

                        // Cannot draw icon on top of thumbnail.
                        KWin.ThumbnailItem {
                            wId: windowId
                            // clip: true
                            // clipTo: thumbnailListView
                            clip: true
                            clipTo: parent
                            anchors.fill: parent
                            anchors.topMargin: captionRow.height
                        }
                    }
                } // GridView.delegate

                highlight: PlasmaCore.FrameSvgItem {
                    id: highlightItem
                    imagePath: "widgets/viewitem"
                    prefix: "hover"
                    width: thumbnailListView.width
                    height: thumbnailListView.height
                }
                highlightMoveDuration: 200
                // property int selectedIndex: -1
                Connections {
                    target: tabBox
                    onCurrentIndexChanged: {
                        thumbnailListView.currentIndex = tabBox.currentIndex
                    }
                }

                // keyNavigationEnabled: true // Requires: Qt 5.7 and QtQuick 2.? (2.7 didn't work).
                // keyNavigationWraps: true // Requires: Qt 5.7 and QtQuick 2.? (2.7 didn't work).

            } // GridView


            // This doesn't work, nor does keyboard input work on any other tabbox skin (KDE 5.7.4)
            // It does work in the preview however.
        } // Dialog.mainItem
    } // Dialog


}