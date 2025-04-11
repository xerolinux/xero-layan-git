function getNameCity(latitude, longitud, leng, callback) {
    let url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitud}&accept-language=${leng}`;
    console.log("Generated URL: ", url); // Para verificar la URL generada

    let req = new XMLHttpRequest();
    req.open("GET", url, true);

    req.onreadystatechange = function () {
        if (req.readyState === 4) {
            if (req.status === 200) {
                try {
                    let datos = JSON.parse(req.responseText);
                    let address = datos.address;
                    let city = address.city;
                    let county = address.county;
                    let state = address.state;
                    let full = city ? city : state ? state : county;
                    console.log(full);
                    callback(full);
                } catch (e) {
                    console.error("Error al analizar la respuesta JSON: ", e);
                }
            } else {
                console.error(`city failed`);
            }
        }
    };

    req.onerror = function () {
        console.error("La solicitud falló");
    };

    req.ontimeout = function () {
        console.error("La solicitud excedió el tiempo de espera");
    };

    req.send();
}

