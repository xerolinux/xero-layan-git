import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
  id: root

  BootManager { id: bootMgr }

  property var shownEntries: ListModel { }

  preferredRepresentation: compactRepresentation

  compactRepresentation: CompactRepresentation { id: compact }
  fullRepresentation: FullRepresentation { id: entryList }

  PlasmaCore.Action {
    id: resetAction
    onTriggered: {
      shownEntries.clear()
      bootMgr.reset()
    }
  }

  Component.onCompleted: {
    Plasmoid.setInternalAction("reset", resetAction)
    bootMgr.initialize()
  }

}