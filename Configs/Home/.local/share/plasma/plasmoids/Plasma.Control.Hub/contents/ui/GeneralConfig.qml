import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.11
import org.kde.kirigami as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: configRoot

    QtObject {
        id: units
        property var isCelsius
    }
    signal configurationChanged

    property var measurementUnits: ["Celsius", "Fahrenheit"]

    property alias cfg_latitudeC: latitude.text
    property alias cfg_longitudeC: longitude.text
    property alias cfg_useCoordinatesIp: autamateCoorde.checked
    property alias cfg_weatheCardActive: weatherCard.checked
    property alias cfg_userAndAvaAveilable: usrCheck.checked
    property alias cfg_celsius: units.isCelsius
    property alias cfg_coverByNetwork: downloadMissingCovers.checked


    Kirigami.FormLayout {
        id: unitsSelector
        width: configRoot.width
        CheckBox {
            id: downloadMissingCovers
            Kirigami.FormData.label: i18n("Download missing album covers:")
        }
        ComboBox {
            id: scales
            Kirigami.FormData.label: i18n("Temperature Unit:")
            model: measurementUnits
            displayText: units.isCelsius ? "Celsius" : "Fahrenheit"
            onActivated: {
                units.isCelsius = scales.currentText === "Celsius"
            }
        }
        CheckBox {
            id: autamateCoorde
            Kirigami.FormData.label: i18n('Use IP location')
        }
        TextField {
            id: latitude
            visible: !autamateCoorde.checked
            Kirigami.FormData.label: i18n("Latitude:")
            width: 200
        }
        TextField {
            id: longitude
            visible: !autamateCoorde.checked
            Kirigami.FormData.label: i18n("Longitude:")
            width: 200
        }
        Item {
            Kirigami.FormData.isSection: true
        }
        CheckBox {
            id: weatherCard
            Kirigami.FormData.label: i18n("Active Weather Card")
        }
        CheckBox {
            id: usrCheck
            Kirigami.FormData.label: i18n("Avatar And Name User")
        }
        Item {
            Kirigami.FormData.isSection: true
        }
    }
    Label {
        id: instructions
        visible: !autamateCoorde.checked
        wrapMode: Text.WordWrap
        anchors.top: unitsSelector.bottom
        opacity: 0.7
        horizontalAlignment: Text.AlignHCenter
        width: parent.width
        text: i18n("To know your geographic coordinates, I recommend using the following website https://open-meteo.com/en/docs")
    }



}
