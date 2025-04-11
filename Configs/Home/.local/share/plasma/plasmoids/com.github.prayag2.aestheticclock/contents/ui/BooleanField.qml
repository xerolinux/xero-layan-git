import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    property alias text: label.text
    property alias checked: checkbox.checked
    
    Label {
        id: label
    }
    CheckBox {
        id: checkbox
    }
}
