import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import "components" as Components
import org.kde.plasma.plasmoid
import QtQuick.Effects
import "js/funcs.js" as Funcs

Item {
    id: weatherItem
    property string nameLogo: ""
    property string city: weatherData.city
    property bool resetFullRep: true
    property bool value: false


    Components.WeatherData {
        id: weatherData
    }

    Item {
        id: wrapperWeatherMinimal
        width: parent.width
        height: parent.height
        //spacing: 5
        visible: resetFullRep
        Kirigami.Icon {
            id: logo
            source: weatherData.iconWeatherCurrent
            color: Kirigami.Theme.textColor
            width: parent.height *.65
            height: width
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            id: maxAndMin
            width: maxCurrent.width
            height: logo.height
            visible: value
            anchors.verticalCenter: logo.verticalCenter
            anchors.left: logo.right
            opacity: 0.8
            Column {
                width: parent.width
                height: (maxCurrent.implicitHeight * 2) + 1.5
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: maxCurrent
                    text: Math.round(Funcs.celsiusToFahrenheit(weatherData.maxweatherCurrent, Plasmoid.configuration.celsius)) + "°"
                    font.pixelSize: logo.height*.3
                    color: Kirigami.Theme.textColor
                    verticalAlignment: Text.AlignTop
                }
                Rectangle {
                    width: parent.width *.9
                    color: Kirigami.Theme.textColor
                    height: 1.5
                }
                Text {
                    text: Math.round(Funcs.celsiusToFahrenheit(weatherData.minweatherCurrent, Plasmoid.configuration.celsius)) + "°"
                    font.pixelSize: logo.height*.3
                    color: Kirigami.Theme.textColor
                    verticalAlignment: Text.AlignBottom
                }

            }
        }

        Item {
            id: currentTemp
            width: textTempCurrent.implicitWidth
            height: textTempCurrent.implicitHeight + probability.implicitHeight
            anchors.left: parent.left
            anchors.leftMargin: maxAndMin.visible ? maxAndMin.width + logo.width + 5 : logo.width + 5
            anchors.top: parent.top
            anchors.topMargin: (parent.height - height - 24) /2

            Text {
                id: textTempCurrent
                width: parent.width
                height: parent.height - probability.implicitHeight
                text: weatherData.currentTemperature === "?" ? "?" : Funcs.celsiusToFahrenheit(weatherData.currentTemperature, Plasmoid.configuration.celsius) + "°"
                font.pixelSize: wrapperWeatherMinimal.height*.3
                color: Kirigami.Theme.textColor
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }

        }
        Image {
            id: rainProbabilityLogo
            width: 16
            height: 16
            source: "../icons/rain-probability.svg"
            sourceSize: Qt.size(width, width)
            fillMode: Image.PreserveAspectFit
            visible: false
        }


        MultiEffect {
            id: rainProbabilityLogoColorized
            source: rainProbabilityLogo
            width: 16
            height: 16
            colorizationColor: Kirigami.Theme.textColor
            colorization: 1.0
            anchors.top: currentTemp.bottom
            anchors.topMargin: 15
            anchors.left: currentTemp.left
        }

        Text {
            text: " " + weatherData.probabilidadDeLLuvia + "%"
            height: 20
            anchors.top: currentTemp.bottom
            anchors.topMargin: 15
            anchors.left: rainProbabilityLogoColorized.right
            //anchors.leftMargin: 26
            font.pixelSize: lo.height*.8
            verticalAlignment: Text.AlignVCenter
            color: Kirigami.Theme.textColor
        }
        Item {
            width: parent.width - logo.width - currentTemp.width - 20
            height: (city !== "unk") ? textWeather.implicitHeight + textCity.implicitHeight + 4 : textWeather.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10
            Column {
                width: parent.width
                height: parent.height
                spacing: 4
                Text {
                    id: textWeather
                    width: parent.width
                    height: (city !== "unk") ? parent.height - textCity.implicitHeight :  parent.height
                    text: weatherData.weatherShottext
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    font.pixelSize: wrapperWeatherMinimal.height*.2
                    color: Kirigami.Theme.textColor
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    id: textCity
                    height: parent.height - textWeather.height
                    width: parent.width
                    text: city
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    font.pixelSize: wrapperWeatherMinimal.height*.15
                    visible: city !== "unk"
                    color: Kirigami.Theme.textColor
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }
            }

        }
        MouseArea {
            height: parent.height
            width: parent.width
            anchors.centerIn: parent
            onClicked: {
                //wrapperWeatherMinimal.visible = !wrapperWeatherMinimal.visible
                resetFullRep = !resetFullRep
            }
        }
    }

    ListModel {
        id: forecastModel
    }

    function agregarUnDia(x) {
        var fechaActual = new Date();
        fechaActual.setDate(fechaActual.getDate() + x); // Sumar días
        return fechaActual.getDate().toString(); // Obtener solo el día como número
    }


    function updateForecastModel() {

        let icons = {
            0: weatherData.oneIcon,
            1: weatherData.twoIcon,
            2: weatherData.threeIcon,
            3: weatherData.fourIcon,
            4: weatherData.fiveIcon,
            5: weatherData.sixIcon,
            6: weatherData.sevenIcon
        }
        let Maxs = {
            0: weatherData.oneMax,
            1: weatherData.twoMax,
            2: weatherData.threeMax,
            3: weatherData.fourMax,
            4: weatherData.fiveMax,
            5: weatherData.sixMax,
            6: weatherData.sevenMax
        }
        let Mins = {
            0: weatherData.oneMin,
            1: weatherData.twoMin,
            2: weatherData.threeMin,
            3: weatherData.fourMin,
            4: weatherData.fiveMin,
            5: weatherData.sixMin,
            6: weatherData.sevenMin
        }
        forecastModel.clear();
        for (var i = 0; i < 7; i++) {
            var icon = icons[i]
            var maxTemp = Maxs[i]
            var minTemp = Mins[i]
            var date = agregarUnDia(i)

            forecastModel.append({
                date: date,
                icon: icon,
                maxTemp: maxTemp,
                minTemp: minTemp
            });


        }

    }

    onResetFullRepChanged: {
        wrapperWeatherMinimal.visible = resetFullRep
    }
    Component.onCompleted: {
        weatherData.dataChanged.connect(() => {
            Qt.callLater(updateForecastModel); // Asegura que la función se ejecute al final del ciclo de eventos
            value = true
        });

    }



    ListView {
        width: parent.width
        height: parent.width
        model: forecastModel
        orientation: Qt.Horizontal
        layoutDirection : Qt.LeftToRight
        visible: !wrapperWeatherMinimal.visible

        delegate: Item {
            height: parent.height
            width: weatherItem.width/7

            Column {
                id: column
                width: max.implicitWidth
                height: parent.height
                Text {
                    width: parent.width
                    //height: parent.height/4
                    text: model.date
                    horizontalAlignment: Text.AlignHCenter
                    color: Kirigami.Theme.textColor
                    verticalAlignment:  Text.AlignVCenter
                    //anchors.horizontalCenter: parent.horizontalCenter

                }

                Kirigami.Icon {
                    id: forecastLogo
                    width: 24
                    height: 24
                    source: model.icon
                    color: Kirigami.Theme.textColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    id: max
                    width: parent.width
                    //height: parent.height/4
                    text: Funcs.celsiusToFahrenheit(model.maxTemp, Plasmoid.configuration.celsius) + "°"
                    color: Kirigami.Theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    id: min
                    width: parent.width
                    //height: parent.height/4
                    text: Funcs.celsiusToFahrenheit(model.minTemp, Plasmoid.configuration.celsius) + "°"
                    color: Kirigami.Theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: 0.8
                }
            }

        }
        anchors.horizontalCenter: parent.horizontalCenter
        MouseArea {
            height: parent.height
            width: parent.width
            anchors.centerIn: parent
            onClicked: {
                resetFullRep = !resetFullRep
            }
        }
    }
}
