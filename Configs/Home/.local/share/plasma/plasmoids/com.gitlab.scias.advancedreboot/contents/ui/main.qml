import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents

PlasmoidItem {
  id: root

  BootManager { id: bootMgr }

  preferredRepresentation: compactRepresentation

  compactRepresentation: CompactRepresentation { id: compact }

  fullRepresentation: FullRepresentation { id: full }

  Component.onCompleted: {
    bootMgr.initialize()
  }

}