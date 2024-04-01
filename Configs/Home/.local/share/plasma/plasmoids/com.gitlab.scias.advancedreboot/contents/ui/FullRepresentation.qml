import QtQuick 2.15
import QtQuick.Layouts 1.15

import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import org.kde.notification

// TODO: Trim long entries or make them scroll
// TODO: Put stuff inside parenthesis / kernel versions in a separate line below
PlasmaExtras.Representation {

  property var shownEntries: ListModel { }
  property var selectedEntry
  property bool busy: false

  implicitWidth: Kirigami.Units.gridUnit * 20
  implicitHeight: mainList.height + header.height + Kirigami.Units.largeSpacing

  Layout.preferredWidth: implicitWidth
  Layout.minimumWidth: implicitWidth
  Layout.preferredHeight: implicitHeight
  Layout.maximumHeight: implicitHeight
  Layout.minimumHeight: implicitHeight

  header: PlasmaExtras.PlasmoidHeading {
    contentItem: Kirigami.Heading {
      padding: Kirigami.Units.smallSpacing
      horizontalAlignment: Text.AlignHCenter
      text: i18n("Reboot into...")
    }
  }

    ListView {
      id: mainList

      interactive: false
      spacing: Kirigami.Units.smallSpacing

      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: shownEntries.count > 0 ? contentHeight : 300

      model: shownEntries

      delegate: PlasmaComponents.ItemDelegate {
        required property string id
        required property string bIcon
        required property string title
        required property string version
        width: parent ? parent.width : 0 // BUG: Occasional error here
        contentItem: RowLayout {

          Layout.fillWidth: true

          Kirigami.Icon {
            source: Qt.resolvedUrl("../../assets/icons/" + bIcon + ".svg")
            color: Kirigami.Theme.colorSet
            smooth: true
            isMask: true
            scale: 0.8
          }
          ColumnLayout {
            spacing: 0
            Kirigami.Heading {
              level: 4
              Layout.fillWidth: true
              text: title
            }
            PlasmaComponents.Label {
              color: Kirigami.Theme.disabledTextColor
              Layout.fillWidth: true
              visible: version
              text: version
            }
          }
        }
        onClicked: {
          root.expanded = !root.expanded
          selectedEntry = title
          myNotif.sendEvent()
          bootMgr.bootEntry(id)
        }
    }

    // TODO: sections
    /*section.property: "system"
    section.delegate: Kirigami.ListSectionHeader {
      width: parent.width
      label: section == 1 ? "System entries" : "Custom entries"
    }*/

    ErrorMessage {
      id: noEntriesMsg
      anchors.centerIn: parent
      sIcon: "dialog-warning-symbolic"
      message: i18n("No boot entries could be listed.\nPlease check this applet settings.")
      show: bootMgr.step === BootManager.Ready && shownEntries.count == 0 && !busy
      // TODO: add open configuration button
      //Plasmoid.internalAction("configure").trigger()
    }

    PlasmaComponents.BusyIndicator {
      implicitWidth: 150
      implicitHeight: 150
      anchors.centerIn: parent
      visible: bootMgr.step < BootManager.Ready || busy
    }

    ErrorMessage {
      id: notEligibleMsg
      anchors.centerIn: parent
      sIcon: "dialog-error-symbolic"
      message: i18n("This applet cannot work on this system.\nPlease check that the system is booted in UEFI mode and that systemd, systemd-boot are used and configured properly.")
      show: bootMgr.step === BootManager.Error
    }

    ErrorMessage {
      id: rootRequired
      anchors.centerIn: parent
      sIcon: "dialog-password-symbolic"
      message: i18n("Root access is required to get the full boot entries list.")
      show: bootMgr.step === BootManager.RootRequired
      action: Kirigami.Action {
        text: i18n("Retry as root")
        icon.name: "unlock-symbolic"
        onTriggered: bootMgr.getEntriesFull(true)
      }
      PlasmaComponents.Button {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        text: i18n("Ignore")
        icon.name: "errornext"
        onClicked: bootMgr.finish(true)
        visible: bootMgr.step === BootManager.RootRequired
      }
    }

  }

  Notification {
    id: myNotif
    componentName: "plasma_workspace"
    eventId: "warning"
    title: i18n("Advanced reboot")
    text: i18n("The entry <b>") + selectedEntry + i18n("</b> has been set for the next reboot.")
    iconName: "refreshstructure"
  }

  function updateModel() {
    busy = true
    shownEntries.clear()
    for (let entry of bootMgr.bootEntries) {
      if (!plasmoid.configuration.blacklist.includes(entry.id)) {
        shownEntries.append(entry)
      }
    }
    busy = false
  }

  Component.onCompleted: {
    if (bootMgr.step === BootManager.Ready) { 
      updateModel()
    }
  }

  Connections {
    target: bootMgr

    function onLoaded(signal) {
      if (signal === BootManager.Ready) {
        bootMgr.alog("Boot entries are ready - Updating the listview")
        updateModel()
      }
    }
  
  }

  Connections {
    target: plasmoid.configuration

    function onValueChanged(value) {
      if (bootMgr.step === BootManager.Ready && value == "blacklist") {
        //bootMgr.alog("Configuration has changed - Updating the listview")
        updateModel()
      }
    }
   }

}
