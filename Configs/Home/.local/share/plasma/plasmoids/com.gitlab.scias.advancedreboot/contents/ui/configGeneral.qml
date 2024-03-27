import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls

import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.kcmutils as KCM

// TODO: Better look
// TODO?: Clean hideEntries in case of config changed
KCM.ScrollViewKCM {
  id: root

  property alias cfg_rebootMode: rebootMode.currentIndex

  header: Kirigami.Heading {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: i18n("Displayed boot entries in the plasmoid view")
  }

  view: ListView {
    //anchors.fill: parent
    //height: contentHeight
    focus: true
    model: plasmoid.configuration.allEntries
    delegate: Controls.SwitchDelegate {
      width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
      text: modelData
      checked: !plasmoid.configuration.hideEntries.includes(modelData)
      onToggled: toggleEntry(modelData, !checked)
    }

    ErrorMessage {
      id: noEntriesMsg
      sIcon: "dialog-error-symbolic"
      message: i18n("No boot entries could be found.\nPlease check that your system meets the requirements.")
      show: plasmoid.configuration.allEntries == 0
      // TODO: add open configuration button
      //plasmoid.action("configure").trigger()
    }
  }

  footer: RowLayout {
    Layout.fillWidth: true

    PlasmaComponents.Label {
      Layout.alignment: Qt.AlignRight
      text: i18n("Behavior upon selecting an entry :")
    }

    Controls.ComboBox {
      Layout.alignment: Qt.AlignLeft
      id: rebootMode
      model: [i18n("Reboot immediately"), i18n("Reboot after confirmation"), i18n("Don't reboot")]
    }
  }

  function toggleEntry(entry, hide) {
    // TODO: figure out why push method doesn't work on the plasmoid.configuration item
    let tmpList = plasmoid.configuration.hideEntries
    if (!hide) {
      const index = tmpList.indexOf(entry)
      if (index > -1) tmpList.splice(index, 1)
    }
    else {
      tmpList.push(entry)
    }
    plasmoid.configuration.hideEntries = tmpList
  }

}
