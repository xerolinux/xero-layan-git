import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
 
KCM.SimpleKCM {
ColumnLayout {
    property alias cfg_sys_mon_interval: sysMonInterval.value
    Title {
        text: i18n("System Monitor")
    }
    NumberField {
        id: sysMonInterval
        text: i18n("Interval (in milliseconds)")
    }
    Item {
        Layout.fillHeight: true
    }
}
}
