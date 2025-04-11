import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

Item {
    property var mpris2Model: Mpris.Mpris2Model { }
    property var indexPlayer: mpris2Model.currentPlayer
    readonly property string trackName: mpris2Model.currentPlayer?.track
    readonly property string albumName: mpris2Model.currentPlayer?.album
    readonly property string artistName: mpris2Model.currentPlayer?.artist
    readonly property int playbackStatus: mpris2Model.currentPlayer?.playbackStatus ?? 0
    readonly property bool isPlaying: playbackStatus === Mpris.PlaybackStatus.Playing

    property bool coverByNetwork: Plasmoid.configuration.coverByNetwork
    property bool coverMprisIsImage: false
    property url coverMpris: mpris2Model.currentPlayer?.artUrl
    property url cover: coverMprisIsImage ? coverMpris : coverByNetwork ? onlineCover : coverMpris

    property url onlineCover

    // Contador de reintentos y máximo permitido
    property int retryCount: 0
    property int maxRetries: 3

    Image {
        id: cov
        source: coverMpris
        visible: false
        sourceSize.width: 16
        sourceSize.height: 16
        retainWhileLoading: false
        onStatusChanged: {
            if (cov.status === Image.Ready) {
                coverMprisIsImage = true
            }
        }
    }

    function nextTrack() {
        mpris2Model.currentPlayer.Next();
    }
    function playPause() {
        mpris2Model.currentPlayer.PlayPause();
    }
    function prevTrack() {
        mpris2Model.currentPlayer.Previous();
    }

    onCoverByNetworkChanged: {
        if (coverByNetwork) {
            getCover.start()
        }
    }
    onTrackNameChanged: {
        onlineCover = ""
        coverMprisIsImage = coverByNetwork ? false : true
        // Reiniciamos el contador de reintentos al cambiar de canción
        retryCount = 0
        getCover.start()
    }

    Component.onCompleted: {
        if (coverByNetwork && isPlaying) {
            getCoverArt(artistName, albumName, trackName)
        }
    }

    Timer {
        id: getCover
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            if (coverByNetwork) {
                getCoverArt(artistName, albumName, trackName)
            }
        }
    }

    // Función que consulta la API de iTunes Search para obtener la portada del álbum.
    // Ahora también utiliza el nombre de la canción para mejorar la precisión.
    function getCoverArt(artist, album, track) {
        var term = (artist + " " + album + " " + track);
        var itunesUrl = "https://itunes.apple.com/search?term=" + encodeURIComponent(term) + "&entity=song&limit=1";
        console.log("Consultando iTunes en:", itunesUrl);

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText);
                    if (response.resultCount > 0 && response.results.length > 0) {
                        var songData = response.results[0];
                        // Verificar si el nombre del álbum coincide
                        if (songData.collectionName && songData.collectionName.toLowerCase() === album.toLowerCase()) {
                            var coverUrl = songData.artworkUrl100;
                            coverUrl = coverUrl.replace(/100x100bb.jpg$/, "600x600bb.jpg");
                            console.log("Cover URL encontrado:", coverUrl);
                            onlineCover = coverUrl;
                            retryCount = 0; // Reseteamos el contador al encontrar un resultado válido
                        } else {
                            console.log("El resultado no coincide con el nombre del álbum. Reintentando...");
                            retrySearch(artist, album, track);
                        }
                    } else {
                        console.log("No se encontró resultado. Reintentando sin nombre de canción...");
                        getCoverArtWithoutTrack(artist, album);
                    }
                } else {
                    console.log("Error en la consulta: " + xhr.status);
                }
            }
        };
        xhr.open("GET", itunesUrl);
        xhr.send();
    }

    // Función para buscar la portada sin usar el nombre de la canción
    function getCoverArtWithoutTrack(artist, album) {
        var term = (artist + " " + album);
        var itunesUrl = "https://itunes.apple.com/search?term=" + encodeURIComponent(term) + "&entity=album&limit=1";
        console.log("Consultando iTunes sin nombre de canción en:", itunesUrl);

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText);
                    if (response.resultCount > 0 && response.results.length > 0) {
                        var albumData = response.results[0];
                        var coverUrl = albumData.artworkUrl100;
                        coverUrl = coverUrl.replace(/100x100bb.jpg$/, "600x600bb.jpg");
                        console.log("Cover URL encontrado:", coverUrl);
                        onlineCover = coverUrl;
                        retryCount = 0; // Reseteamos el contador al obtener un resultado
                    } else {
                        console.log("No se encontró resultado incluso sin nombre de canción. Reintentando...");
                        retrySearch(artist, album, "");
                    }
                } else {
                    console.log("Error en la consulta: " + xhr.status);
                }
            }
        };
        xhr.open("GET", itunesUrl);
        xhr.send();
    }

    // Función para reintentar la búsqueda eliminando texto entre corchetes o caracteres innecesarios.
    function retrySearch(artist, album, track) {
        if (retryCount >= maxRetries) {
            console.log("Máximo de reintentos alcanzado. Se cancela la búsqueda.");
            return;
        }
        retryCount++;

        var newArtist = artist.replace(/\[[^\]]*\]/g, "").trim();
        var newAlbum = album.replace(/\[[^\]]*\]/g, "").trim();
        var newTrack = track.replace(/\[[^\]]*\]/g, "").trim();

        if (newArtist !== artist || newAlbum !== album || newTrack !== track) {
            console.log("Reintentando con valores modificados:", newArtist, newAlbum, newTrack);
            getCoverArt(newArtist, newAlbum, newTrack);
        } else {
            console.log("No se encontró resultado incluso tras eliminar texto entre []. Se intenta sin el nombre de la canción.");
            getCoverArtWithoutTrack(artist, album);
        }
    }
}

