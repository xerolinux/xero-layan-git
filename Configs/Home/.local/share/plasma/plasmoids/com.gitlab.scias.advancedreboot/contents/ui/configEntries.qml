import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls

import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.ScrollViewKCM {
  id: generalRoot

  property alias cfg_rebootMode: rebootMode.currentIndex
  property var allEntries: ListModel { }

  header: Controls.Label {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: i18n("Displayed boot entries in the plasmoid view")
    wrapMode: Text.WordWrap
  }

  view: ListView {
    focus: true
    model: allEntries
    delegate: Controls.SwitchDelegate {
      required property string showTitle
      required property string id
      required property string version
      width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
      text: showTitle
      checked: !plasmoid.configuration.blacklist.includes(id)
      onToggled: toggleEntry(id, checked)
    }

    ErrorMessage {
      id: noEntriesMsg
      sIcon: "dialog-error-symbolic"
      message: i18n("No boot entries could be found.")
      show: !plasmoid.configuration.savedEntries || plasmoid.configuration.appState == 4
    }
    //TODO: Placeholder while entries not ready yet
  }

  footer: RowLayout {
    Layout.fillWidth: true

    Controls.Label {
      Layout.alignment: Qt.AlignRight
      text: i18n("Behavior upon selecting an entry :")
    }

    Controls.ComboBox {
      Layout.alignment: Qt.AlignLeft
      id: rebootMode
      model: [i18n("Reboot immediately"), i18n("Reboot after confirmation"), i18n("Don't reboot")]
    }
  }

  function toggleEntry(id, enabled) {
    // BUG/WORKAROUND: Have to use copy methods because direct modification (push) doesn't work...
    if (enabled) {
      plasmoid.configuration.blacklist = plasmoid.configuration.blacklist.filter((entry) => entry != id)
    }
    else {
      plasmoid.configuration.blacklist = plasmoid.configuration.blacklist.concat([id])
    }
  }

  Component.onCompleted: {
    if (plasmoid.configuration.savedEntries) {
      for (const entry of JSON.parse(plasmoid.configuration.savedEntries)) {
        allEntries.append({
          id: entry.id,
          showTitle: entry.showTitle,
          version: entry.version
        })
      }
    }
  }

}
