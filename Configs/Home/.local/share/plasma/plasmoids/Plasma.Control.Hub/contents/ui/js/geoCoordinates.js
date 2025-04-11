function obtenerCoordenadas(callback) {
    let url = "http://ip-api.com/json/?fields=lat,lon";

    let req = new XMLHttpRequest();
    req.open("GET", url, true);

    req.onreadystatechange = function () {
        if (req.readyState === 4) {
            if (req.status === 200) {
                try {
                    let datos = JSON.parse(req.responseText);
                    let latitud = datos.lat;
                    let longitud = datos.lon;
                    let full = `${latitud}, ${longitud}`;
                    console.log(`Coordenadas obtenidas: ${full}`);
                    callback(full); // Devolver coordenadas completas
                } catch (error) {
                    console.error("Error procesando la respuesta JSON:", error);
                    callback(null); // Devolver null en caso de error de parsing
                }
            } else {
                console.error(`Error en la solicitud: ${req.status}`);
                callback(null); // Devolver null en caso de error de solicitud
            }
        }
    };

    req.onerror = function () {
        console.error("Error de red al intentar obtener coordenadas.");
        callback(null); // Devolver null en caso de error de red
    };

    req.send();
}
