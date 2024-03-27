import QtQuick

import org.kde.kirigami as Kirigami

Item {

  width: Kirigami.Units.gridUnit * 4
  height: Kirigami.Units.gridUnit * 4

  Kirigami.Icon {
    opacity: 1
    width: parent.width - 3
    height: parent.height - 3
    anchors.centerIn: parent
    active: mouseArea.containsMouse
    source: Qt.resolvedUrl("../../assets/plasmoid.svg")
    color: Kirigami.Theme.colorSet
    smooth: true
    isMask: true

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      onClicked: root.expanded = !root.expanded
    }
  }
}
