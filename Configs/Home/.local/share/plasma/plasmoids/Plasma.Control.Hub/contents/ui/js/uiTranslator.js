function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}

function getTranslateInJs(language, word) {
    const translatesUi = {
        cs: ["síť", "bluetooth", "offline", "nastavení", "nastavení systému", "vypnuto", "nerušit", "hlasitost", "předpověď počasí"],
        da: ["netværk", "bluetooth", "offline", "indstillinger", "systemindstillinger", "fra", "forstyr ikke", "lydstyrke", "vejrudsigten"],
        de: ["Netzwerk", "Bluetooth", "offline", "Einstellungen", "Systemeinstellungen", "aus", "nicht stören", "Lautstärke", "Wettervorhersage"],
        en: ["network", "bluetooth", "offline", "settings", "system settings", "off", "don't disturb", "volume", "weather forecast"],
        es: ["red", "bluetooth", "sin conexión", "configuración", "configuración del sistema", "apagado", "no molestar", "volumen", "pronóstico del tiempo"],
        et: ["võrk", "bluetooth", "ühenduseta", "seaded", "süsteemi seaded", "väljas", "mitte segada", "helitugevus", "ilmaprognoos"],
        fi: ["verkko", "bluetooth", "offline", "asetukset", "järjestelmäasetukset", "pois", "älä häiritse", "äänenvoimakkuus", "sääennuste"],
        fr: ["réseau", "bluetooth", "hors ligne", "paramètres", "paramètres du système", "éteindre", "ne pas déranger", "volume", "prévisions météorologiques"],
        hr: ["mreža", "bluetooth", "offline", "postavke", "postavke sustava", "isključeno", "ne ometaj", "glasnoća", "vremenska prognoza"],
        hu: ["hálózat", "bluetooth", "offline", "beállítások", "rendszerbeállítások", "kikapcsolva", "ne zavarjanak", "hangerő", "időjárás előrejelzés"],
        is: ["net", "bluetooth", "ótengdur", "stillingar", "kerfisstillingar", "af", "trufla ekki", "hljóðstyrkur", "veðurspá"],
        it: ["rete", "bluetooth", "offline", "impostazioni", "impostazioni di sistema", "spento", "non disturbare", "volume", "previsioni del tempo"],
        lt: ["tinklas", "bluetooth", "neprisijungęs", "nustatymai", "sistemos nustatymai", "išjungta", "netrukdyti", "garsas", "orų prognozė"],
        lv: ["tīkls", "bluetooth", "bezsaistē", "iestatījumi", "sistēmas iestatījumi", "izslēgts", "netraucēt", "skaļums", "laika prognoze"],
        nl: ["netwerk", "bluetooth", "offline", "instellingen", "systeeminstellingen", "uit", "niet storen", "volume", "weersvoorspelling"],
        no: ["nettverk", "bluetooth", "offline", "innstillinger", "systeminnstillinger", "av", "ikke forstyrr", "volum", "værmelding"],
        pl: ["sieć", "bluetooth", "offline", "ustawienia", "ustawienia systemowe", "wyłączony", "nie przeszkadzać", "głośność", "prognoza pogody"],
        pt: ["rede", "bluetooth", "offline", "configurações", "configurações do sistema", "desligado", "não incomodar", "volume", "previsão do tempo"],
        ro: ["rețea", "bluetooth", "offline", "setări", "setări de sistem", "oprit", "nu deranjați", "volum", "prognoza meteo"],
        sk: ["sieť", "bluetooth", "offline", "nastavenia", "nastavenia systému", "vypnuté", "nerušiť", "hlasitosť", "predpoveď počasia"],
        sl: ["omrežje", "bluetooth", "offline", "nastavitve", "sistemske nastavitve", "izklopljeno", "ne moti", "glasnost", "vremenska napoved"],
        sq: ["rrjet", "bluetooth", "offline", "cilësimet", "cilësimet e sistemit", "fikur", "mos shqetësoni", "vëllimi", "parashikimi i motit"],
        sv: ["nätverk", "bluetooth", "offline", "inställningar", "systeminställningar", "av", "stör ej", "volym", "väderprognos"]
    };

    const index = translatesUi['en'].indexOf(word.toLowerCase());
    if (index !== -1) {
        const translatedWord = translatesUi[language] ? translatesUi[language][index] : translatesUi["en"][index];
        return capitalizeFirstLetter(translatedWord);
    } else {
        return capitalizeFirstLetter(word);
    }
}


