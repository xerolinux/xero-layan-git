import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls

import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
  id: infoRoot

  // TODO: find a better way
  property var itemLabels: [
    i18n("systemd is at version 251 or above"), 
    i18n("bootctl is present"), 
    i18n("Can reboot to the Firmware Setup"), 
    i18n("Can reboot to the Bootloader Menu"), 
    i18n("Can reboot to a custom entry"),
    i18n("Could get the custom entries")
    ]

  header: Controls.Label {
    text: i18n("In case of issues or missing entries, please ensure that the requirements shown below are met")
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    topPadding: Kirigami.Units.largeSpacing
    bottomPadding: Kirigami.Units.largeSpacing
  }

  // BUG: The checks if the user changes rebootMode...
  ColumnLayout {
    spacing: Kirigami.Units.largeSpacing
    Layout.fillWidth: true
    Repeater {
      model: itemLabels
      RowLayout {
        required property string modelData
        required property int index
        Controls.Label {
          Layout.fillWidth: true
          Layout.leftMargin: Kirigami.Units.gridUnit*2
          verticalAlignment: Text.AlignVCenter
          text: modelData
        }
        Kirigami.Icon {
          Layout.rightMargin: Kirigami.Units.gridUnit*2
          source: plasmoid.configuration.checkState[index].toString() == "true" ? "dialog-ok-apply" : "error"
          color: plasmoid.configuration.checkState[index].toString() == "true" ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Kirigami.Units.largeSpacing

      Item {
        Layout.fillWidth: true
      }
      Controls.Button {
        text: i18n("Reset configuration")
        onClicked: resetDialog.open()
      }
      Controls.Button {
        text: i18n("View log")
        onClicked: logDialog.open()
      }
      Item {
        Layout.fillWidth: true
      }
    }
  }

  Kirigami.PromptDialog {
    id: resetDialog
    title: i18n("Reset settings?")
    subtitle: i18n("This will reset this plasmoid's configuration and state.")
    standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

    onAccepted: {
      plasmoid.configuration.entriesID = ""
      plasmoid.configuration.savedEntries = ""
      plasmoid.configuration.blacklist = []
      plasmoid.configuration.rebootMode = 0
      // TODO: Maybe there's a way to restart the plasmoid?
      showPassiveNotification(i18n("This plasmoid's configuration and state have been reset. Please restart it (or Plasma) to start anew."))
    }
  }

  Kirigami.PromptDialog {
    id: logDialog
    width: parent.width - Kirigami.Units.gridUnit * 4

    title: i18n("Log")
    standardButtons: Kirigami.Dialog.NoButton

    Controls.TextArea {
      id: field
      readOnly: true
      Layout.fillWidth: true
      text: plasmoid.configuration.appLog
      wrapMode: Controls.TextArea.WordWrap
    }
  }
}