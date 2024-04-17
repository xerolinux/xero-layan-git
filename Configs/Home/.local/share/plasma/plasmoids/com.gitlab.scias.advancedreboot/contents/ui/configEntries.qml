import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls

import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.kcmutils as KCM

KCM.ScrollViewKCM {
  id: generalRoot

  property alias cfg_rebootMode: rebootMode.currentIndex
  property var allEntries: ListModel { }
  readonly property var transition: Transition { 
    NumberAnimation { properties: "x,y"; duration: 300; easing.type: Easing.OutQuart }
  }

  header: Controls.Label {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: i18n("Toggle and rearrange entries displayed in the main view")
    wrapMode: Text.WordWrap
  }

  view: ListView {
    id: entriesView
    focus: true
    model: allEntries
    reuseItems: true
    move: transition
    displaced: transition

    delegate: Rectangle {
      required property int index
      //required property string title
      required property string showTitle
      //required property string id
      //required property string version
      required property string bIcon
      required property bool show
      color: index % 2 == 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor
      width: parent.width
      height: rowEntry.implicitHeight
      RowLayout {
        id: rowEntry
        width: parent.width
        Kirigami.Icon {
            source: Qt.resolvedUrl("../../assets/icons/" + bIcon + ".svg")
            color: Kirigami.Theme.colorSet
            smooth: true
            isMask: true
            scale: 0.5
        }
        Controls.Label {
          Layout.fillWidth: true
          text: showTitle
          elide: Text.ElideRight
        }
        Controls.ToolButton {
          icon.name: show ? "password-show-on" : "password-show-off"
          onClicked: toggleEntry(index, !show)
          icon.color: show ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
          PlasmaComponents.ToolTip { text: i18n("Toggle display of this entry") }
        }
        Controls.ToolButton {
          icon.name: "arrow-up"
          onClicked: moveEntry(index, index - 1)
          opacity: index > 0 ? 1 : 0
          enabled: index > 0
          PlasmaComponents.ToolTip { text: i18n("Move this entry up the list") }
        }
        Controls.ToolButton {
          icon.name: "arrow-down"
          onClicked: moveEntry(index, index + 1)
          opacity: index < allEntries.count - 1 ? 1 : 0
          enabled: index < allEntries.count - 1
          PlasmaComponents.ToolTip { text: i18n("Move this entry down the list") }
        }
      }
    }

    ErrorMessage {
      id: noEntriesMsg
      sIcon: "dialog-error-symbolic"
      message: i18n("No boot entries could be found.")
      show: allEntries.count == 0 || plasmoid.configuration.appState == 4
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

  function moveEntry(from, to) {
    allEntries.move(from, to, 1)
    saveEntries()
  }

  function toggleEntry(index, show) {
    allEntries.setProperty(index, "show", show)
    saveEntries()
  }

  function loadEntries() {
    if (plasmoid.configuration.savedEntries) {
      try {
        for (const entry of JSON.parse(plasmoid.configuration.savedEntries)) {
          allEntries.append(entry)
        }
      }
      catch (err) {
        console.log("advancedreboot: Error parsing saved entries for the config view: " + err)
      }
    }
  }

  function saveEntries() {
    let tmp = []
    for (let i = 0; i < allEntries.count; i++) {
      let entry = allEntries.get(i)
      tmp.push({
        id: entry.id,
        title: entry.title,
        showTitle: entry.showTitle,
        version: entry.version,
        bIcon: entry.bIcon,
        show: entry.show,
      })
    }
    try {
      plasmoid.configuration.savedEntries = JSON.stringify(tmp)
    }
    catch (err) {
      console.log("advancedreboot: Error saving entries from the config view: " + err)
    }
  }

  Component.onCompleted: {
    if (plasmoid.configuration.savedEntries) loadEntries()
  }

}
