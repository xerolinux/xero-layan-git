import QtQuick 2.15
import QtQuick.Controls 2.15
import "../js/traductor.js" as Traduc
import "../js/GetInfoApi.js" as GetInfoApi
import "../js/geoCoordinates.js" as GeoCoordinates
import "../js/GetCity.js" as GetCity
import "../js/GetModelWeather.js" as GetModelWeather

Item {
  signal dataChanged // Definir el signal aquí

  function obtener(texto, indice) {
    var palabras = texto.split(/\s+/); // Divide el texto en palabras utilizando el espacio como separador
    return palabras[indice - 1]; // El índice - 1 porque los índices comienzan desde 0 en JavaScript
  }

  function fahrenheit(temp) {
    if (temperatureUnit == 0) {
      return temp;
    } else {
      return Math.round((temp * 9 / 5) + 32);
    }
  }

  property bool active: Plasmoid.configuration.weatheCardActive
  property bool isInExecution:  false
  property string useCoordinatesIp: plasmoid.configuration.useCoordinatesIp
  property string latitudeC: plasmoid.configuration.latitudeC
  property string longitudeC: plasmoid.configuration.longitudeC
  property string temperatureUnit: plasmoid.configuration.temperatureUnit

  property string latitude: (useCoordinatesIp === "true") ? latitudeIP : (latitudeC === "0") ? latitudeIP : latitudeC
  property string longitud: (useCoordinatesIp === "true") ? longitudIP : (longitudeC === "0") ? longitudIP : longitudeC

  property var observerCoordenates: latitude + longitud

  property int currentTime: Number(Qt.formatDateTime(new Date(), "h"))

  property string datosweather: "0"
  property string forecastWeather: "0"
  //property string observer: datosweather + forecastWeather
  property int retrysCity: 0

  property string oneIcon: asingicon(obtener(forecastWeather, 1))
  property string twoIcon: asingicon(obtener(forecastWeather, 2))
  property string threeIcon: asingicon(obtener(forecastWeather, 3))
  property string fourIcon: asingicon(obtener(forecastWeather, 4))
  property string fiveIcon: asingicon(obtener(forecastWeather, 5))
  property string sixIcon: asingicon(obtener(forecastWeather, 6))
  property string sevenIcon: asingicon(obtener(forecastWeather, 7))
  property int oneMax: fahrenheit(obtener(forecastWeather, 8))
  property int twoMax: fahrenheit(obtener(forecastWeather, 9))
  property int threeMax: fahrenheit(obtener(forecastWeather, 10))
  property int fourMax: fahrenheit(obtener(forecastWeather, 11))
  property int fiveMax: fahrenheit(obtener(forecastWeather, 12))
  property int sixMax: fahrenheit(obtener(forecastWeather, 13))
  property int sevenMax: fahrenheit(obtener(forecastWeather, 14))
  property int oneMin: fahrenheit(obtener(forecastWeather, 15))
  property int twoMin: fahrenheit(obtener(forecastWeather, 16))
  property int threeMin: fahrenheit(obtener(forecastWeather, 17))
  property int fourMin: fahrenheit(obtener(forecastWeather, 18))
  property int fiveMin: fahrenheit(obtener(forecastWeather, 19))
  property int sixMin: fahrenheit(obtener(forecastWeather, 20))
  property int sevenMin: fahrenheit(obtener(forecastWeather, 21))

  property string day: (Qt.formatDateTime(new Date(), "yyyy-MM-dd"))
  property string therday: Qt.formatDateTime(new Date(new Date().getTime() + (numberOfDays * 24 * 60 * 60 * 1000)), "yyyy-MM-dd")
  property int numberOfDays: 6
  property string currentTemperature: datosweather !== "0" ? fahrenheit(obtener(datosweather, 1)) : "?"
  property string codeleng: ((Qt.locale().name)[0] + (Qt.locale().name)[1])
  property string codeweather: obtener(datosweather, 4)
  property string codeweatherTomorrow: obtener(forecastWeather, 2)
  property string codeweatherDayAftertomorrow: obtener(forecastWeather, 3)
  property string codeweatherTwoDaysAfterTomorrow: obtener(forecastWeather, 4)
  property string minweatherCurrent: fahrenheit(obtener(datosweather, 2))
  property string maxweatherCurrent: fahrenheit(obtener(datosweather, 3))
  property string minweatherTomorrow: twoMin
  property string maxweatherTomorrow: twoMax
  property string minweatherDayAftertomorrow: threeMin
  property string maxweatherDayAftertomorrow: threeMax
  property string minweatherTwoDaysAfterTomorrow: fourMax
  property string maxweatherTwoDaysAfterTomorrow: fourMax
  property string iconWeatherCurrent: asingicon(codeweather)
  property string uvindex: uvIndexLevelAssignment(obtener(datosweather, 7))
  property string windSpeed: obtener(datosweather, 6)

  property string weatherLongtext: i18n(textWeather(codeweather))
  property string weatherShottext: i18n(shortTextWeather(codeweather))

  property string probabilidadDeLLuvia: obtener(datosweather, 5)
  property string textProbability: Traduc.rainProbabilityText(codeleng)

  property string completeCoordinates: ""
  property string oldCompleteCoordinates: "1"
  property string latitudeIP: completeCoordinates.substring(0, (completeCoordinates.indexOf(' ')) - 1)
  property string longitudIP: completeCoordinates.substring(completeCoordinates.indexOf(' ') + 1)

  property string uvtext: Traduc.uvRadiationText(codeleng)
  property string windSpeedText: Traduc.windSpeedText(codeleng)
  property int isDay: obtener(datosweather, 8)
  property string city: "unk"
  property string prefixIcon: isDay === 1 ? "" : "-night"

  Component.onCompleted: {
    updateWeather(1);
  }

  function uvIndexLevelAssignment(nivel) {
    if (nivel < 3) {
      return nivel + " " + Traduc.lavelUV(codeleng, 0);
    } else {
      if (nivel < 6) {
        return nivel + " " + Traduc.lavelUV(codeleng, 1);
      } else {
        if (nivel < 8) {
          return nivel + " " + Traduc.lavelUV(codeleng, 2);
        } else {
          if (nivel < 11) {
            return nivel + " " + Traduc.lavelUV(codeleng, 3);
          } else {
            return nivel + " " + Traduc.lavelUV(codeleng, 4);
          }
        }
      }
    }
  }

  function getCoordinatesWithIp() {
    GeoCoordinates.obtenerCoordenadas(function(result) {

        completeCoordinates = result;
        retryCoordinate.start()
    });
  }

  onObserverCoordenatesChanged: {
    console.log("Coordenadas cambiaron, actualizando clima");
    if (latitude && longitud && latitude !== "0" && longitud !== "0") {
      updateWeather(2);
      getCityFuncion();
    } else {
      console.warn("Coordenadas inválidas, reintentando...");
      retryCoordinate.start();
    }
  }

  function getCityFuncion() {

    if (!latitude || !longitud || latitude === "0" || longitud === "0") {
        console.error("Coordenadas inválidas para la solicitud de ciudad");
        return;
    }
    GetCity.getNameCity(latitude, longitud, codeleng, function(result) {

        city = result;
        retrycity.start()
    });
}

  function getWeatherApi() {
    GetInfoApi.obtenerDatosClimaticos(latitude, longitud, day, currentTime, function(result) {
        datosweather = result;
        getForecastWeather()
        retry.start()
    });
  }

  function getForecastWeather() {
    GetModelWeather.GetForecastWeather(latitude, longitud, day, therday, function(result) {
      forecastWeather = result;
      //retry.start()
    });
  }



  function asingicon(x, b) {
    let wmocodes = {
      0: "clear",
      1: "few-clouds",
      2: "few-clouds",
      3: "clouds",
      51: "showers-scattered",
      53: "showers-scattered",
      55: "showers-scattered",
      56: "showers-scattered",
      57: "showers-scattered",
      61: "showers",
      63: "showers",
      65: "showers",
      66: "showers-scattered",
      67: "showers",
      71: "snow-scattered",
      73: "snow",
      75: "snow",
      77: "hail",
      80: "showers",
      81: "showers",
      82: "showers",
      85: "snow-scattered",
      86: "snow",
      95: "storm",
      96: "storm",
      99: "storm",
    };
    var iconName = "weather-" + (wmocodes[x] || "unknown");
    var iconNamePresicion = iconName + prefixIcon
    return b === "preciso" ? iconNamePresicion : iconName;
  }

  function textWeather(x) {
    let text = {
      0: "Clear",
      1: "Mainly clear",
      2: "Partly cloudy",
      3: "Overcast",
      51: "Drizzle light intensity",
      53: "Drizzle moderate intensity",
      55: "Drizzle dense intensity",
      56: "Freezing Drizzle light intensity",
      57: "Freezing Drizzle dense intensity",
      61: "Rain slight intensity",
      63: "Rain moderate intensity",
      65: "Rain heavy intensity",
      66: "Freezing Rain light intensity",
      67: "Freezing Rain heavy intensity",
      71: "Snowfall slight intensity",
      73: "Snowfall moderate intensity",
      75: "Snowfall heavy intensity",
      77: "Snow grains",
      80: "Rain showers slight",
      81: "Rain showers moderate",
      82: "Rain showers violent",
      85: "Snow showers slight",
      86: "Snow showers heavy",
      95: "Thunderstorm",
      96: "Thunderstorm with slight hail"
    };
    return text[x]
  }

  function shortTextWeather(x) {
    let text = {
      0: "Clear",
      1: "Clear",
      2: "Cloudy",
      3: "Cloudy",
      51: "Drizzle",
      53: "Drizzle",
      55: "Drizzle",
      56: "Drizzle",
      57: "Drizzle",
      61: "Rain",
      63: "Rain",
      65: "Rain",
      66: "Rain",
      67: "Rain",
      71: "Snow",
      73: "Snow",
      75: "Snow",
      77: "Hail",
      80: "Showers",
      81: "Showers",
      82: "Showers",
      85: "Showers",
      86: "Showers",
      95: "Storm",
      96: "Storm",
      99: "Storm"
    };
    return text[x]
  }

  function updateWeather(x) {
    if (x === 1) {
      if (useCoordinatesIp === "true") {
        getCoordinatesWithIp();
      } else {
        if (latitudeC === "0" || longitudC === "0") {
          getCoordinatesWithIp();
        } else {
          getWeatherApi()
        }
      }
    }
///
    if (x === 2) {
      getWeatherApi();
    }
  }



  onForecastWeatherChanged: {
    if (forecastWeather.length > 3) {
      dataChanged(); // Emitir el signal dataChanged cuando los datos estén listos
    }
  }

  Timer {
    id: retryCoordinate
    interval: 5000
    running: false
    repeat: false
    onTriggered: {
      if (completeCoordinates === "") {
        getCoordinatesWithIp();
      }

    }
  }
  Timer {
    id: retrycity
    interval: 6000
    running: false
    repeat: false
    onTriggered: {
      if (city === "unk" && retrysCity < 5) {
        retrysCity = retrysCity + 1
        getCityFuncion();
      }
    }
  }
  Timer {
    id: retry
    interval: 5000
    running: false
    repeat: false
    onTriggered: {
      if (datosweather === "0") {
        getWeatherApi();
      }
    }
  }

  Timer {
    id: weatherupdate
    interval: 900000
    running: false
    repeat: true
    onTriggered: {
      oldCompleteCoordinates = completeCoordinates
      updateWeather(1);
      veri.start()
    }
  }

  Timer {
    id: veri
    interval: 4000
    running: false
    repeat: false
    onTriggered: {
     if (oldCompleteCoordinates === completeCoordinates) {
       updateWeather(2)
    }
    }
  }


  onUseCoordinatesIpChanged: {
    if (active) {
      console.log(active, "esto no deberia ejectutarse")
      updateWeather(1);
      isInExecution = true
    }
  }
}

