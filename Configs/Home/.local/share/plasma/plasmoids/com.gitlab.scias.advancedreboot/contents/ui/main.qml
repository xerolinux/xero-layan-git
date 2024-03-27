import QtQuick

import org.kde.plasma.plasmoid

PlasmoidItem {
  id: root

  BootManager { id: bootMgr }

  preferredRepresentation: compactRepresentation

  compactRepresentation: CompactRepresentation { id: compact }
  fullRepresentation: FullRepresentation {
    id: full
    eligible: bootMgr.canEfi || bootMgr.canMenu || bootMgr.canEntry || bootMgr.bootEntries.count > 0
  }

  Component.onCompleted: {
    plasmoid.configuration.allEntries = []
    bootMgr.doChecks()
    bootMgr.getEntries()
  }

}
