function GetForecastWeather(latitud, longitud, fechaInicio, fechaFin, callback) {
     let url = `https://api.open-meteo.com/v1/forecast?latitude=${latitud}&longitude=${longitud}&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&start_date=${fechaInicio}&end_date=${fechaFin}`;

     let req = new XMLHttpRequest();
     req.open("GET", url, true);

     req.onreadystatechange = function () {
         if (req.readyState === 4) {
             if (req.status === 200) {
                 let datos = JSON.parse(req.responseText);

                 let daily = datos.daily;
                 let codes = daily.weather_code.join(' ');
                 let max = daily.temperature_2m_max.join(' ');
                 let min = daily.temperature_2m_min.join(' ');

                 let full = codes + " " + max + " " + min
                 console.log(`${full}`);
                 callback(full);
             } else {
                 console.error(`Error en la solicitud: ${req.status}`);
             }
         }
     };

     req.send();
}
