function obtenerDatosClimaticos(latitud, longitud, fechaInicio, hours, callback) {
    let url = `https://api.open-meteo.com/v1/forecast?latitude=${latitud}&longitude=${longitud}&hourly=temperature_2m&current=temperature_2m,is_day,weather_code,wind_speed_10m&hourly=uv_index&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto&start_date=${fechaInicio}&end_date=${fechaInicio}`;

    let req = new XMLHttpRequest();
    req.open("GET", url, true);

    req.onreadystatechange = function () {
        if (req.readyState === 4) {
            if (req.status === 200) {
                let datos = JSON.parse(req.responseText);
                let currents = datos.current;
                let isday = currents.is_day;

                let temperaturaActual = currents.temperature_2m;
                let windSpeed = currents.wind_speed_10m;
                let codeCurrentWeather = currents.weather_code;

                let datosDiarios = datos.daily;
                let propabilityPrecipitationCurrent = datosDiarios.precipitation_probability_max[0];

                let hourly = datos.hourly
                let propabilityUVindex = hourly.uv_index[hours];

                let tempMin = datosDiarios.temperature_2m_min[0];
                let tempMax = datosDiarios.temperature_2m_max[0];

                let full = temperaturaActual + " " + tempMin + " " + tempMax + " " + codeCurrentWeather + " " + propabilityPrecipitationCurrent + " " + windSpeed + " " + propabilityUVindex + " " + isday
                console.log(`${full}`);
                callback(full);
            } else {
                console.error(`Error en la solicitud: weathergeneral ${req.status}`);
                //callback(`failed ${req.status}`)
            }
        }
    };

    req.send();
}
