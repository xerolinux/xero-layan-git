/*
 * Copyright 2024  Kevin Donnelly
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */

/** @type {string} */
let API_KEY = "e1f10a1e78da46f5b10a1e78da96f525"

/** Map from Wunderground provided icon codes to opendesktop icon theme descs */
let iconThemeMap = {
	0: "weather-storm-symbolic",
	1: "weather-storm-symbolic",
	2: "weather-storm-symbolic",
	3: "weather-storm-symbolic",
	4: "weather-storm-symbolic",
	5: "weather-snow-rain-symbolic",
	6: "weather-snow-rain-symbolic",
	7: "weather-freezing-rain-symbolic",
	8: "weather-freezing-rain-symbolic",
	9: "weather-showers-scattered-symbolic",
	10: "weather-freezing-rain-symbolic",
	11: "weather-showers-symbolic",
	12: "weather-showers-symbolic",
	13: "weather-snow-scattered-symbolic",
	14: "weather-snow-symbolic",
	15: "weather-snow-symbolic",
	16: "weather-snow-symbolic",
	17: "weather-hail-symbolic",
	18: "weather-snow-scattered-symbolic",
	19: "weather-many-clouds-wind-symbolic",
	20: "weather-fog-symbolic",
	21: "weather-fog-symbolic",
	22: "weather-fog-symbolic",
	23: "weather-clouds-wind-symbolic",
	24: "weather-clouds-wind-symbolic",
	25: "weather-snow-symbolic",
	26: "weather-clouds-symbolic",
	27: "weather-many-clouds-symbolic",
	28: "weather-clouds-symbolic",
	29: "weather-clouds-night-symbolic",
	30: "weather-few-clouds-symbolic",
	31: "weather-clear-night-symbolic",
	32: "weather-clear-symbolic",
	33: "weather-few-clouds-night-symbolic",
	34: "weather-few-clouds-day-symbolic",
	35: "weather-freezing-storm-day-symbolic",
	36: "weather-clear-symbolic",
	37: "weather-storm-day-symbolic",
	38: "weather-storm-day-symbolic",
	39: "weather-showers-scattered-day-symbolic",
	40: "weather-showers-symbolic",
	41: "weather-snow-scattered-day-symbolic",
	42: "weather-snow-symbolic",
	43: "weather-snow-symbolic",
	44: "weather-none-available-symbolic",
	45: "weather-showers-scattered-night-symbolic",
	46: "weather-snow-storm-night-symbolic",
	47: "weather-storm-night"
}

/**
 * Pull the most recent observation from the selected weather station.
 *
 * This handles setting errors and making the loading screen appear.
 */
function getCurrentData() {
	var req = new XMLHttpRequest();

	var url = "https://api.weather.com/v2/pws/observations/current";
	url += "?stationId=" + stationID;
	url += "&format=json";

	if (unitsChoice === 0) {
		url += "&units=m";
	} else if (unitsChoice === 1) {
		url += "&units=e";
	} else {
		url += "&units=h";
	}

	url += "&apiKey=" + API_KEY;
	url += "&numericPrecision=decimal";

	printDebug("[pws-api.js] " + url);

	req.open("GET", url);

	req.setRequestHeader("Accept-Encoding", "gzip");
	req.setRequestHeader("Origin", "https://www.wunderground.com");

	req.onerror = function () {
		errorStr = "Request couldn't be sent" + req.statusText;

		appState = showERROR;

		printDebug("[pws-api.js] " + errorStr);
	};

	req.onreadystatechange = function () {
		if (req.readyState == 4) {
			if (req.status == 200) {
				var sectionName = "";

				if (unitsChoice === 0) {
					sectionName = "metric";
				} else if (unitsChoice === 1) {
					sectionName = "imperial";
				} else {
					sectionName = "uk_hybrid";
				}

				var res = JSON.parse(req.responseText);

				var tmp = {};
				var tmp = res["observations"][0];

				var details = res["observations"][0][sectionName];
				tmp["details"] = details;

				weatherData = tmp;

				plasmoid.configuration.latitude = weatherData["lat"];
				plasmoid.configuration.longitude = weatherData["lon"];

				printDebug("[pws-api.js] Got new current data");

				findIconCode();

				appState = showDATA;
			} else {
				if (req.status == 204) {
					errorStr = "Station not found or station not active";

					printDebug("[pws-api.js] " + errorStr);
				} else {
					errorStr = "Request failed: " + req.responseText;

					printDebug("[pws-api.js] " + errorStr);
				}

				appState = showERROR;
			}
		}
	};

	req.send();
}

/**
 * Fetch the forecast data and place it in the forecast data model.
 *
 * @todo Incorporate a bitmapped appState field so an error with forecasts
 * doesn't show an error screen for entire widget.
 */
function getForecastData() {
	var req = new XMLHttpRequest();

	var url = "https://api.weather.com/v1/geocode";
	url +=
		"/" +
		plasmoid.configuration.latitude +
		"/" +
		plasmoid.configuration.longitude;
	url += "/forecast/daily/7day.json";
	url += "?apiKey=" + API_KEY;
	url += "&language=en-US";

	if (unitsChoice === 0) {
		url += "&units=m";
	} else if (unitsChoice === 1) {
		url += "&units=e";
	} else {
		url += "&units=h";
	}

	printDebug("[pws-api.js] " + url);

	req.open("GET", url);

	req.setRequestHeader("Accept-Encoding", "gzip");

	req.onreadystatechange = function () {
		if (req.readyState == 4) {
			if (req.status == 200) {
				forecastModel.clear();

				var res = JSON.parse(req.responseText);

				var forecasts = res["forecasts"];

				for (var period = 0; period < forecasts.length; period++) {
					var forecast = forecasts[period];

					var day = forecast["day"];
					var night = forecast["night"];

					var isDay = day !== undefined;

					var fullDateTime = forecast["fcst_valid_local"];
					var date = parseInt(
						fullDateTime.split("T")[0].split("-")[2]
					);

					var snowDesc = "";
					if (isDay) {
						snowDesc =
							day["snow_phrase"] === ""
								? "No snow"
								: day["snow_phrase"];
					} else {
						snowDesc =
							night["snow_phrase"] === ""
								? "No snow"
								: night["snow_phrase"];
					}

					forecastModel.append({
						date: date,
						dayOfWeek: isDay ? forecast["dow"] : "Tonight",
						iconCode: isDay ? iconThemeMap[day["icon_code"]] : iconThemeMap[night["icon_code"]],
						high: isDay ? forecast["max_temp"] : night["hi"],
						low: forecast["min_temp"],
						feelsLike: isDay ? day["hi"] : night["hi"],
						shortDesc: isDay
							? day["phrase_12char"]
							: night["phrase_12char"],
						longDesc: isDay ? day["narrative"] : night["narrative"],
						thunderDesc: isDay
							? day["thunder_enum_phrase"]
							: night["thunder_enum_phrase"],
						winDesc: isDay
							? day["wind_phrase"]
							: night["wind_phrase"],
						UVDesc: isDay ? day["uv_desc"] : night["uv_desc"],
						snowDesc: snowDesc,
						golfDesc: isDay
							? day["golf_category"]
							: "Don't play golf at night.",
					});
				}

				// These are placed seperate from forecastModel since items part of ListModels
				// cannot be property bound
				currDayHigh = forecastModel.get(0).high;
				currDayLow = forecastModel.get(0).low;

				printDebug("[pws-api.js] Got new forecast data");

				showForecast = true;
			} else {
				errorStr = "Could not fetch forecast data";

				printDebug("[pws-api.js] " + errorStr);

				appState = showERROR;
			}
		}
	};

	req.send();
}

/**
 * Find the nearest PWS with the choosen coordinates.
 */
function getNearestStation() {
	var long = plasmoid.configuration.longitude;
	var lat = plasmoid.configuration.latitude;

	var req = new XMLHttpRequest();

	var url = "https://api.weather.com/v3/location/near";
	url += "?geocode=" + lat + "," + long;
	url += "&product=pws";
	url += "&format=json";
	url += "&apiKey=" + API_KEY;

	printDebug("[pws-api.js] " + url);

	req.open("GET", url);

	req.setRequestHeader("Accept-Encoding", "gzip");

	req.onreadystatechange = function () {
		if (req.readyState == 4) {
			if (req.status == 200) {
				var res = JSON.parse(req.responseText);

				var stations = res["location"]["stationId"];
				if (stations.length > 0) {
					var closest = stations[0];
					stationID.text = closest;
				}
			} else {
				printDebug("[pws-api.js] " + req.responseText);
			}
		}
	};

	req.send();
}

function findIconCode() {
	var req = new XMLHttpRequest();

	var long = plasmoid.configuration.longitude;
	var lat = plasmoid.configuration.latitude;

	var url = "https://api.weather.com/v3/wx/observations/current";

	url += "?geocode=" + lat + "," + long;
	url += "&apiKey=" + API_KEY;
	url += "&language=en-US";

	if (unitsChoice === 0) {
		url += "&units=m";
	} else if (unitsChoice === 1) {
		url += "&units=e";
	} else {
		url += "&units=h";
	}

	url += "&format=json";

	req.open("GET", url);

	req.setRequestHeader("Accept-Encoding", "gzip");
	req.setRequestHeader("Origin", "https://www.wunderground.com");

	req.onerror = function () {
		printDebug("[pws-api.js] " + req.responseText);
	};

	printDebug("[pws-api.js] " + url);

	req.onreadystatechange = function () {
		if (req.readyState == 4) {
			if (req.status == 200) {
				var res = JSON.parse(req.responseText);

				iconCode = iconThemeMap[res["iconCode"]];
				conditionNarrative = res["wxPhraseLong"];

				// Determine if the precipitation is snow or rain
				// All of these codes are for snow
				if (
					iconCode === 5 ||
					iconCode === 13 ||
					iconCode === 14 ||
					iconCode === 15 ||
					iconCode === 16 ||
					iconCode === 42 ||
					iconCode === 43 ||
					iconCode === 46
				) {
					isRain = false;
				}
			}
		}
	};

	req.send();
}
