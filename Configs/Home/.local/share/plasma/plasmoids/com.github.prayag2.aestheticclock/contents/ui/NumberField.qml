import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore

RowLayout {
    property alias text: label.text
    property alias value: spinbox.value
    property alias enabled: spinbox.enabled
    
    Label {
        id: label
        color: spinbox.enabled ? PlasmaCore.Theme.textColor : PlasmaCore.Theme.disabledTextColor
    }
    SpinBox {
        id: spinbox
        from: 0; to: 999999
    }
}
