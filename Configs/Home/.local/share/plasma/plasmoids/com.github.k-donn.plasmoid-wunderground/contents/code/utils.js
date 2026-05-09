/*
 * Copyright 2026  Kevin Donnelly
 * Copyright 2022  Rafal (Raf) Liwoch
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

var UNITS_SYSTEM = {
	METRIC: 0,
	IMPERIAL: 1,
	HYBRID: 2,
	CUSTOM: 3,
};

var TEMP_UNITS = {
	C: 0,
	F: 1,
	K: 2,
};

var WIND_UNITS = {
	KMH: 0,
	MPH: 1,
	MPS: 2,
};

var RAIN_UNITS = {
	MM: 0,
	IN: 1,
	CM: 2,
};

var SNOW_UNITS = {
	MM: 0,
	IN: 1,
	CM: 2,
};

var PRES_UNITS = {
	MB: 0,
	INHG: 1,
	MMHG: 2,
	HPA: 3,
	PSI: 4,
};

function mbToPsi(mb) {
	return mb * 0.0145037738;
}

function psiToMb(psi) {
	return psi / 0.0145037738;
}

var ELEV_UNITS = {
	M: 0,
	FT: 1,
};

var hourlyModelDictV1 = {
	temperature: "temp",
	cloudCover: "clds",
	humidity: "rh",
	precipitationChance: "pop",
	precipitationRate: "qpf",
	snowPrecipitationRate: "snow_qpf",
	wind: "wspd",
	pressure: "mslp",
	uvIndex: "uv_index",
	iconCode: "icon_code",
};

var hourlyModelDictV3 = {
	temperature: "temperature",
	cloudCover: "cloudCover",
	humidity: "relativeHumidity",
	precipitationChance: "precipChance",
	precipitationRate: "qpf",
	snowPrecipitationRate: "qpfSnow",
	wind: "windSpeed",
	pressure: "pressureMeanSeaLevel",
	uvIndex: "uvIndex",
	iconCode: "iconCode",
};

var systemIconMap = {
	0: "weather-storm",
	1: "weather-storm",
	2: "weather-storm",
	3: "weather-storm",
	4: "weather-storm",
	5: "weather-snow-rain",
	6: "weather-snow-rain",
	7: "weather-freezing-rain",
	8: "weather-freezing-rain",
	9: "weather-showers-scattered",
	10: "weather-freezing-rain",
	11: "weather-showers",
	12: "weather-showers",
	13: "weather-snow-scattered",
	14: "weather-snow",
	15: "weather-snow",
	16: "weather-snow",
	17: "weather-hail",
	18: "weather-snow-scattered",
	19: "weather-many-clouds-wind",
	20: "weather-fog",
	21: "weather-fog",
	22: "weather-fog",
	23: "weather-clouds-wind",
	24: "weather-clouds-wind",
	25: "weather-snow",
	26: "weather-many-clouds",
	27: "weather-many-clouds",
	28: "weather-clouds",
	29: "weather-clouds-night",
	30: "weather-few-clouds",
	31: "weather-clear-night",
	32: "weather-clear",
	33: "weather-few-clouds-night",
	34: "weather-few-clouds-day",
	35: "weather-freezing-storm-day",
	36: "weather-clear",
	37: "weather-storm-day",
	38: "weather-storm-day",
	39: "weather-showers-scattered-day",
	40: "weather-showers",
	41: "weather-snow-scattered-day",
	42: "weather-snow",
	43: "weather-snow",
	44: "weather-none-available",
	45: "weather-showers-scattered-night",
	46: "weather-snow-storm-night",
	47: "weather-storm-night",
	temperature: "\uF00C",
	uvIndex: "\uF009",
	pressure: "\uF00A",
	cloudCover: "\uF03B",
	humidity: "\uF008",
	precipitationChance: "\uF007",
	precipitationRate: "\uF04C",
	snowPrecipitationRate: "\uF02D",
	wind: "\uF040",
	weatherStation: "\uF00B",
	compass: "\uF01C",
	pin: "\uF014",
	"0-2": "\uF006",
	"3-7": "\uF005",
	"8-12": "\uF004",
	"13-17": "\uF003",
	"18-22": "\uF002",
	"23-27": "\uF001",
	"28-32": "\uF000",
};

var iconMap = {
	0: "\uF057",
	1: "\uF056",
	2: "\uF055",
	3: "\uF054",
	4: "\uF053",
	5: "\uF052",
	6: "\uF051",
	7: "\uF050",
	8: "\uF04F",
	9: "\uF04E",
	10: "\uF04D",
	11: "\uF04C",
	12: "\uF04B",
	13: "\uF04A",
	14: "\uF049",
	15: "\uF048",
	16: "\uF047",
	17: "\uF046",
	18: "\uF045",
	19: "\uF044",
	20: "\uF043",
	21: "\uF042",
	22: "\uF041",
	23: "\uF040",
	24: "\uF03F",
	25: "\uF03E",
	26: "\uF03D",
	27: "\uF03C",
	28: "\uF03B",
	29: "\uF03A",
	30: "\uF039",
	31: "\uF038",
	32: "\uF037",
	33: "\uF036",
	34: "\uF035",
	35: "\uF034",
	36: "\uF033",
	37: "\uF032",
	38: "\uF031",
	39: "\uF030",
	40: "\uF02F",
	41: "\uF02E",
	42: "\uF02D",
	43: "\uF02C",
	44: "\uF02B",
	45: "\uF02A",
	46: "\uF029",
	47: "\uF028",
	temperature: "\uF00C",
	uvIndex: "\uF009",
	pressure: "\uF00A",
	"pressure@2": "\uF059",
	cloudCover: "\uF03B",
	"cloudCover@2": "\uF05B",
	humidity: "\uF008",
	"humidity@2": "\uF058",
	precipitationChance: "\uF007",
	precipitationRate: "\uF04C",
	snowPrecipitationRate: "\uF02D",
	wind: "\uF040",
	"wind@2": "\uF05A",
	weatherStation: "\uF00B",
	compass: "\uF01C",
	pin: "\uF014",
	"0-2": "\uF006",
	"3-7": "\uF005",
	"8-12": "\uF004",
	"13-17": "\uF003",
	"18-22": "\uF002",
	"23-27": "\uF001",
	"28-32": "\uF000",
};

var severityColorMap = {
	1: "#cc3300",
	2: "#ff9966",
	3: "#ffcc00",
	4: "#99cc33",
	5: "#ffcc00",
};

/**
 * Turn a 1-360° angle into the corresponding part on the compass.
 *
 * @param {number} deg Angle in degrees
 *
 * @returns {string} Cardinal direction
 */
function windDirToCard(deg) {
	var directions = [
		"N",
		"NNE",
		"NE",
		"ENE",
		"E",
		"ESE",
		"SE",
		"SSE",
		"S",
		"SSW",
		"SW",
		"WSW",
		"W",
		"WNW",
		"NW",
		"NNW",
	];
	deg *= 10;
	return directions[Math.round((deg % 3600) / 255)];
}

function degToRad(d) {
	return (d * Math.PI) / 180.0;
}

// Web-Mercator projection (meters)
function lonToMercX(lon) {
	return 6378137.0 * degToRad(lon);
}
function latToMercY(lat) {
	var rad = degToRad(lat);
	return 6378137.0 * Math.log(Math.tan(Math.PI / 4 + rad / 2));
}

function zoomForBoundingBox(bbox, map, padding) {
	if (padding === undefined) padding = 20;

	var xMin = lonToMercX(bbox.minLon);
	var xMax = lonToMercX(bbox.maxLon);
	var yMin = latToMercY(bbox.minLat);
	var yMax = latToMercY(bbox.maxLat);

	var widthMeters = Math.abs(xMax - xMin);
	var heightMeters = Math.abs(yMax - yMin);

	var availW = Math.max(1, map.width - 2 * padding);
	var availH = Math.max(1, map.height - 2 * padding);

	var metersPerPixelNeeded = Math.max(
		widthMeters / availW,
		heightMeters / availH,
	);

	var initialResolution = 156543.03392804097; // 2πR / 256

	var zoom = Math.log(initialResolution / metersPerPixelNeeded) / Math.log(2);

	return Math.min(Math.max(zoom, 0), 22);
}

function zoomForCircle(centerCoord, radiusMeters, map, padding) {
	const EARTH_RADIUS = 6378137;
	const lat = degToRad(centerCoord.latitude);
	const lon = degToRad(centerCoord.longitude);

	const angularRadius = radiusMeters / EARTH_RADIUS;

	const latMax = Math.asin(
		Math.sin(lat) * Math.cos(angularRadius) +
			Math.cos(lat) * Math.sin(angularRadius),
	);
	const latMin = Math.asin(
		Math.sin(lat) * Math.cos(angularRadius) -
			Math.cos(lat) * Math.sin(angularRadius),
	);

	const latCos = Math.cos(lat);
	const angularRadiusCos = Math.cos(angularRadius);
	const lonDelta =
		latCos === 0
			? Math.PI // At poles, span all longitudes
			: Math.acos(
					(angularRadiusCos - Math.sin(lat) * Math.sin(latMax)) /
						(Math.cos(lat) * Math.cos(latMax)),
				);

	const lonMin = lon - lonDelta;
	const lonMax = lon + lonDelta;

	var bbox = {
		minLat: (latMin * 180) / Math.PI,
		maxLat: (latMax * 180) / Math.PI,
		minLon: (lonMin * 180) / Math.PI,
		maxLon: (lonMax * 180) / Math.PI,
	};

	if (bbox.minLon < -180) {
		bbox.minLon = bbox.minLon + 360;
	}
	if (bbox.maxLon > 180) {
		bbox.maxLon = bbox.maxLon - 360;
	}

	return zoomForBoundingBox(bbox, map, padding);
}

function cToF(degC) {
	return degC * 1.8 + 32;
}

function cToK(degC) {
	return degC + 273.15;
}

function fToC(degF) {
	return (degF - 32) / 1.8;
}

function kmhToMph(kmh) {
	return kmh * 0.6213711922;
}

function mphToKts(mph) {
	return mph * 0.8689758;
}

function kmhToKts(kmh) {
	return kmh * 0.5399565;
}

function kmhToMps(kmh) {
	return kmh * 0.2777778;
}

function ktsToMph(kts) {
	return kts * 1.15078;
}

function ktsToKmh(kts) {
	return kts * 1.852;
}

function mToFt(m) {
	return m * 3.28084;
}

function mmToIn(mm) {
	return mm * 0.0393701;
}

function mmToCm(mm) {
	return mm * 0.1;
}

function cmToMm(cm) {
	return cm * 10;
}

function cmToIn(cm) {
	return cm * 0.393701;
}

function mbToInhg(mb) {
	return mb * 0.02953;
}

function mbToMmhg(mb) {
	return mb * 0.750062;
}

function kToC(degK) {
	return degK - 273.15;
}

function inhgToMb(inhg) {
	return inhg / 0.02953;
}

function mmhgToMb(mmhg) {
	return mmhg / 0.750062;
}

/**
 * Returns whether value is within the range of [low, high).
 * Inclusive lower; exclusive upper
 *
 * @param {number} value Value to compare
 * @param {number} low Lower bound
 * @param {number} high Upper bound
 */
function within(value, low, high) {
	return value >= low && value < high;
}

/**
 * Return what the air feels like with the given temperature.
 *
 * This converts everything into imperial units then runs the function
 * on that data.
 *
 * @param {number} temp Temp in Celcius or Fahrenheit
 * @param {number} relHumid Percent humidity
 * @param {number} windSpeed Speed in kmh or mph
 *
 * @returns {number} What the air feels like in user units
 */
function feelsLike(temp, relHumid, windSpeed) {
	var degF, windSpeedMph, finalRes;
	if (unitsChoice === UNITS_SYSTEM.METRIC) {
		degF = cToF(temp);
		windSpeedMph = kmhToMph(windSpeed);

		var res = feelsLikeImperial(degF, relHumid, windSpeedMph);

		finalRes = fToC(res);
	} else if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
		degF = temp;
		windSpeedMph = windSpeed;

		finalRes = feelsLikeImperial(degF, relHumid, windSpeedMph);
	} else if (unitsChoice === UNITS_SYSTEM.HYBRID) {
		degF = cToF(temp);
		windSpeedMph = windSpeed;

		var res = feelsLikeImperial(degF, relHumid, windSpeedMph);

		finalRes = fToC(res);
	} else {
		// When custom units are choosen, the API gives metric units.
		degF = cToF(temp);
		windSpeedMph = kmhToMph(windSpeed);

		var res = feelsLikeImperial(degF, relHumid, windSpeedMph);

		// Convert degF result to degC so it can be passed in expected degC to toUserTemp
		var tmpRes = fToC(res);

		finalRes = toUserTemp(tmpRes);
	}
	return finalRes;
}

/**
 * Return what the air feels like in imperial units.
 *
 * @param {number} degF Temp in Fahrenheit
 * @param {number} relHumid Percent humidity
 * @param {number} windSpeedMph Speed in m/h
 *
 * @returns {number} What the air feels like in Fahrenheit
 */
function feelsLikeImperial(degF, relHumid, windSpeedMph) {
	if (degF >= 80 && relHumid >= 40) {
		return heatIndexF(degF, relHumid);
	} else if (degF <= 50 && windSpeedMph >= 3) {
		return windChillF(degF, windSpeedMph);
	} else {
		return degF;
	}
}

/**
 * Return how hot the air feels with humidity.
 *
 * @param {number} degF Temp in Fahrenheit
 * @param {number} relHumid Percent humidity
 *
 * @returns {number} Temp in Fahrenheit
 */
function heatIndexF(degF, relHumid) {
	var hIndex;

	hIndex =
		-42.379 +
		2.04901523 * degF +
		10.14333127 * relHumid -
		0.22475541 * degF * relHumid -
		6.83783 * Math.pow(10, -3) * degF * degF -
		5.481717 * Math.pow(10, -2) * relHumid * relHumid +
		1.22874 * Math.pow(10, -3) * degF * degF * relHumid +
		8.5282 * Math.pow(10, -4) * degF * relHumid * relHumid -
		1.99 * Math.pow(10, -6) * degF * degF * relHumid * relHumid;
	return hIndex;
}

/**
 * Return what the air feels like with wind blowing.
 *
 * @param {number} degF Temp in Fahrenheit
 * @param {number} windSpeedMph Wind speed in m/h
 *
 * @returns {number} Temp in Fahrenheit
 */
function windChillF(degF, windSpeedMph) {
	var newTemp =
		35.74 +
		0.6215 * degF -
		35.75 * Math.pow(windSpeedMph, 0.16) +
		0.4275 * degF * Math.pow(windSpeedMph, 0.16);
	return newTemp;
}

/**
 * Return a color to match how hot it is.
 *
 * This determines what unit is passed and calls corresponding func.
 *
 * @param {number} temp Temp in API units
 *
 * @returns {string} Hex color code
 */
function heatColor(temp, bgColor) {
	if (unitsChoice === UNITS_SYSTEM.METRIC) {
		return heatColorC(temp, bgColor);
	} else if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
		return heatColorF(temp, bgColor);
	} else if (unitsChoice === UNITS_SYSTEM.HYBRID) {
		return heatColorC(temp, bgColor);
	} else {
		// Then, temp is in Celcius
		return heatColorC(temp, bgColor);
	}
}

/**
 * Return a color to match how hot it is.
 *
 * Reds for hot, blues for cold
 *
 * @param {number} degC Temp in Celcius
 *
 * @returns {string} Hex color code
 */
function heatColorC(degC, bgColor) {
	return degC > 37.78
		? "#9E1642"
		: degC > 32.2
			? "#D53E4F"
			: degC > 26.6
				? "#F46D43"
				: degC > 23.9
					? "#FDAE61"
					: degC > 21.1
						? lightDark(bgColor, "#E2B434", "#FEE08B")
						: degC > 15.5
							? lightDark(bgColor, "#B1CC2E", "#E6F598")
							: degC > 10
								? lightDark(bgColor, "#6EBA50", "#ABDDA4")
								: degC > 4.4
									? lightDark(bgColor, "#66C2A5", "#2F9374")
									: degC > 0
										? "#3288BD"
										: "#5E4FA2";
}

/**
 * Return a color to match how hot it is.
 *
 * Reds for hot, blues for cold
 *
 * @param {number} degF Temp in Fahrenheit
 *
 * @returns {string} Hex color code
 */
function heatColorF(degF, bgColor) {
	return degF > 100
		? "#9E1642"
		: degF > 90
			? "#D53E4F"
			: degF > 80
				? "#F46D43"
				: degF > 75
					? "#FDAE61"
					: degF > 70
						? lightDark(bgColor, "#E2B434", "#FEE08B")
						: degF > 60
							? lightDark(bgColor, "#B1CC2E", "#E6F598")
							: degF > 50
								? lightDark(bgColor, "#6EBA50", "#ABDDA4")
								: degF > 40
									? lightDark(bgColor, "#66C2A5", "#2F9374")
									: degF > 32
										? "#3288BD"
										: "#5E4FA2";
}

/**
 * Wrap a unit/value pair with a rate value with brackets.
 *
 * @param {string} unit Compare string unit to display
 * @param {string} unitInterval Rate that value is displayed
 * @returns {string} Provided text wrapped in brackets
 */
function wrapInBrackets(unit, unitInterval) {
	return unit !== "" ? `[${unit}${unitInterval}]` : unit;
}

// Credit to @Gojir4
/*!
 *   Select a color depending on whether the background is light or dark.
 *   \c lightColor is the color used on a light background.
 *   \c darkColor is the color used on a dark background.
 */
function lightDark(background, lightColor, darkColor) {
	return isDarkColor(background) ? darkColor : lightColor;
}

/*!
 *   Returns true if the color is dark and should have light content on top
 */
function isDarkColor(background) {
	var temp = Qt.darker(background, 1); //Force conversion to color QML type object
	var a = 1 - (0.299 * temp.r + 0.587 * temp.g + 0.114 * temp.b);
	return temp.a > 0 && a >= 0.3;
}

/**
 * Return an icon to represent the changing barometric pressure.
 *
 * @param {0|1|2|3|4} code Code provided by API
 * @returns {string} Opendesktop icon name
 */
function getPressureTrendIcon(code) {
	if (code === 0) {
		return "list-remove-symbolic";
	} else if (code === 1) {
		return "arrow-up-symbolic";
	} else if (code === 2) {
		return "arrow-down-symbolic";
	} else if (code === 3) {
		return "arrow-up-double-symbolic";
	} else {
		return "arrow-down-double-symbolic";
	}
}

/**
 * Return the filename of the wind barb that should be shown for
 * the given windspeed.
 *
 * @param {number} Wind speed in API units
 *
 * @retruns {string} Filename
 */
function getWindBarbIcon(windSpeed) {
	var speedKts, fileName;
	if (unitsChoice === UNITS_SYSTEM.METRIC) {
		speedKts = kmhToKts(windSpeed);
	} else if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
		speedKts = mphToKts(windSpeed);
	} else if (unitsChoice === UNITS_SYSTEM.HYBRID) {
		speedKts = mphToKts(windSpeed);
	} else {
		speedKts = kmhToKts(windSpeed);
	}

	printDebug(speedKts)

	if (within(speedKts, 0, 2.9999)) {
		fileName = "0-2";
	} else if (within(speedKts, 3, 7.9999)) {
		fileName = "3-7";
	} else if (within(speedKts, 8, 12.9999)) {
		fileName = "8-12";
	} else if (within(speedKts, 13, 17.9999)) {
		fileName = "13-17";
	} else if (within(speedKts, 18, 22.9999)) {
		fileName = "18-22";
	} else if (within(speedKts, 23, 27.9999)) {
		fileName = "23-27";
	} else if (within(speedKts, 28, 32.9999)) {
		fileName = "28-32";
	} else {
		fileName = "28-32";
	}

	return Qt.resolvedUrl("../icons/wind-barbs/" + fileName + ".svg");
}

/**
 * Return the icon representing a weather condition or info element.
 *
 * @param {number} codeID Identifier code for the icon
 * @param {boolean} [useSystemThemeIcons=false] Whether to show system bundled icons
 * @returns {string} opendesktop icon name or unicode escape string
 */
function getConditionIcon(codeID, useSystemThemeIcons = false) {
	return useSystemThemeIcons ? systemIconMap[codeID] : iconMap[codeID];
}

/**
 * Return whether pressure has increased.
 * True = increased
 * False = decreased/no change
 *
 * @param {0|1|2|3|4} code Code provided by API
 * @returns {boolean}
 */
function hasPresIncreased(code) {
	if (code === 1 || code === 3) {
		return true;
	} else {
		return false;
	}
}

/**
 * Take in API temp values and convert them to user choosen units.
 * When a user chooses custom units, the API returns metric. So,
 * convert from metric to choice.
 *
 * @param {number} value Temp in API units
 *
 * @returns {number} Temp in user units
 */
function toUserTemp(value) {
	if (unitsChoice === UNITS_SYSTEM.CUSTOM) {
		// Then, value is in Celcius
		if (plasmoid.configuration.tempUnitsChoice === TEMP_UNITS.C) {
			return value;
		} else if (plasmoid.configuration.tempUnitsChoice === TEMP_UNITS.F) {
			return cToF(value);
		} else {
			return cToK(value);
		}
	} else {
		// The user wants the units the API gives
		return value;
	}
}

/**
 * Return the user's choice of temperature unit with no additional data.
 *
 * @returns {"°C"|"°F"|"°K"} User shoosen unit
 */
function rawTempUnit() {
	var res = "";
	if (unitsChoice === UNITS_SYSTEM.METRIC) {
		res = "°C";
	} else if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
		res = "°F";
	} else if (unitsChoice === UNITS_SYSTEM.HYBRID) {
		res = "°C";
	} else {
		if (plasmoid.configuration.tempUnitsChoice === TEMP_UNITS.C) {
			res = "°C";
		} else if (plasmoid.configuration.tempUnitsChoice === TEMP_UNITS.F) {
			res = "°F";
		} else {
			res = "°K";
		}
	}
	return res;
}

/**
 * Take in a numeric temperature value and return a string
 * with the user specified unit attached.
 *
 * @param {number} value Temperature
 * @param {number} precision Decimal places to round value to
 *
 * @returns {string} User-shown value
 */
function currentTempUnit(value, precision) {
	var res = value.toFixed(precision);
	var unit = rawTempUnit();
	return res + " " + unit;
}

/**
 * Take in API wind speed values and convert them to user choosen units.
 * When a user chooses custom units, the API returns metric. So,
 * convert from metric to choice.
 *
 * @param {number} value Wind speed in API units
 *
 * @returns {number} Wind speed in user units
 */
function toUserSpeed(value) {
	if (unitsChoice === UNITS_SYSTEM.CUSTOM) {
		// Then, value is in kmh
		if (plasmoid.configuration.windUnitsChoice === WIND_UNITS.KMH) {
			return value;
		} else if (plasmoid.configuration.windUnitsChoice === WIND_UNITS.MPH) {
			return kmhToMph(value);
		} else {
			return kmhToMps(value);
		}
	} else {
		// The user wants the units the API gives
		return value;
	}
}

/**
 * Return the user's choice of wind speed unit with no additional data.
 *
 * @returns {"kmh"|"mph"|"m/s"} User choosen unit
 */
function rawSpeedUnit() {
	var res = "";
	if (unitsChoice === UNITS_SYSTEM.METRIC) {
		res = "kmh";
	} else if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
		res = "mph";
	} else if (unitsChoice === UNITS_SYSTEM.HYBRID) {
		res = "mph";
	} else {
		if (plasmoid.configuration.windUnitsChoice === WIND_UNITS.KMH) {
			res = "kmh";
		} else if (plasmoid.configuration.windUnitsChoice === WIND_UNITS.MPH) {
			res = "mph";
		} else {
			res = "m/s";
		}
	}
	return res;
}

/**
 * Take in a numeric wind speed value and return a string
 * with the user specified unit attached.
 *
 * @param {number} value Wind speed
 *
 * @returns {string} User-shown value
 */
function currentSpeedUnit(value, precision) {
	var res = value.toFixed(precision);
	var unit = rawSpeedUnit();
	return res + " " + unit;
}

/**
 * Take in API elevation and convert it to user choosen units.
 * When a user chooses custom units, the API returns metric. So,
 * convert from metric to choice.
 *
 * @param {number} value Elevation in API units
 *
 * @returns {number} Wind speed in user units
 */
function toUserElev(value) {
	if (unitsChoice === UNITS_SYSTEM.CUSTOM) {
		// Then, value is in meters
		if (plasmoid.configuration.elevUnitsChoice === ELEV_UNITS.M) {
			return value;
		} else {
			return mToFt(value);
		}
	} else {
		// The user wants the units the API gives
		return value;
	}
}

/**
 * Return the user's choice of elevation unit with no additional data.
 *
 * @returns {"m"|"ft"} User choosen unit
 */
function rawElevUnit() {
	var res = "";
	if (unitsChoice === UNITS_SYSTEM.METRIC) {
		res = "m";
	} else if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
		res = "ft";
	} else if (unitsChoice === UNITS_SYSTEM.HYBRID) {
		res = "ft";
	} else {
		if (plasmoid.configuration.elevUnitsChoice === ELEV_UNITS.M) {
			res = "m";
		} else {
			res = "ft";
		}
	}
	return res;
}

/**
 * Take in a numeric elevation value and return a string
 * with the user specified unit attached.
 *
 * @param {number} value Elevation
 *
 * @returns {string} User-shown value
 */
function currentElevUnit(value) {
	var res = Math.round(value);
	var unit = rawElevUnit();
	return res + " " + unit;
}

/**
 * Take in API precip and convert it to user choosen units.
 * When a user chooses custom units, the API returns metric. So,
 * convert from metric to choice.
 *
 * @param {number} value Precip in API units
 *
 * @returns {number} Precip in user units
 */
function toUserPrecip(value, isRain) {
	if (isRain === undefined) {
		isRain = true;
	}
	if (unitsChoice === UNITS_SYSTEM.CUSTOM) {
		if (isRain) {
			// Then, value is in mm
			if (plasmoid.configuration.rainUnitsChoice === RAIN_UNITS.MM) {
				return value;
			} else if (
				plasmoid.configuration.rainUnitsChoice === RAIN_UNITS.IN
			) {
				return mmToIn(value);
			} else {
				return mmToCm(value);
			}
		} else {
			// Then, value is in cm
			if (plasmoid.configuration.snowUnitsChoice === SNOW_UNITS.MM) {
				return cmToMm(value);
			} else if (
				plasmoid.configuration.snowUnitsChoice === SNOW_UNITS.IN
			) {
				return cmToIn(value);
			} else {
				return value;
			}
		}
	} else {
		// The user wants the units the API gives
		return value;
	}
}

/**
 * Return the user's choice of precipitation unit with no additional data.
 *
 * @param {boolean} isRain Whether the measured precip is rain
 * @returns {"mm"|"cm"|"in"}
 */
function rawPrecipUnit(isRain) {
	var res = "";
	if (isRain === undefined) {
		isRain = true;
	}
	if (unitsChoice === UNITS_SYSTEM.METRIC) {
		if (isRain) {
			res = "mm";
		} else {
			res = "cm";
		}
	} else if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
		return (res = "in");
	} else if (unitsChoice === UNITS_SYSTEM.HYBRID) {
		if (isRain) {
			res = "mm";
		} else {
			res = "cm";
		}
	} else {
		// This is not redundant because the user can choose different rain/snow
		// units and the result of this function must reflect that.
		if (isRain) {
			if (plasmoid.configuration.rainUnitsChoice === RAIN_UNITS.MM) {
				res = "mm";
			} else if (
				plasmoid.configuration.rainUnitsChoice === RAIN_UNITS.IN
			) {
				res = "in";
			} else {
				res = "cm";
			}
		} else {
			if (plasmoid.configuration.snowUnitsChoice === SNOW_UNITS.MM) {
				res = "mm";
			} else if (
				plasmoid.configuration.snowUnitsChoice === SNOW_UNITS.IN
			) {
				res = "in";
			} else {
				res = "cm";
			}
		}
	}
	return res;
}

/**
 * Take in a numeric precip value and return a string
 * with the user specified unit attached.
 *
 * @param {number} value Precipitation
 *
 * @returns {string} User-shown value
 */
function currentPrecipUnit(value, isRain) {
	var res = value.toFixed(2);
	var unit = rawPrecipUnit(isRain);
	return res + " " + unit;
}

/**
 * Take in API pressure and convert it to user choosen units.
 * When a user chooses custom units, the API returns metric. So,
 * convert from metric to choice.
 *
 * @param {number} value Precip in API units
 *
 * @returns {number} Precip in user units
 */
function toUserPres(value) {
	if (unitsChoice === UNITS_SYSTEM.CUSTOM) {
		// Then, value is in mb
		if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.MB) {
			return value;
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.INHG) {
			return mbToInhg(value);
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.MMHG) {
			return mbToMmhg(value);
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.HPA) {
			return value; // hPa and mb are equivalent
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.PSI) {
			return mbToPsi(value);
		} else {
			return value;
		}
	} else {
		// The user wants the units the API gives
		return value;
	}
}

/**
 * Return the user's choice of pressure unit with no additional data.
 *
 * @returns {"mb"|"inHG"|"mmHG"|"hPa"|"psi"} User choosen unit
 */
function rawPresUnit() {
	var res = "";
	if (unitsChoice === UNITS_SYSTEM.METRIC) {
		res = "mb";
	} else if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
		res = "inHG";
	} else if (unitsChoice === UNITS_SYSTEM.HYBRID) {
		res = "mb";
	} else {
		if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.MB) {
			res = "mb";
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.INHG) {
			res = "inHG";
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.MMHG) {
			res = "mmHG";
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.HPA) {
			res = "hPa";
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.PSI) {
			res = "psi";
		} else {
			res = "hPa";
		}
	}
	return res;
}

/**
 * Take in a numeric pressure value and return a string
 * with the user specified unit attached.
 *
 * @param {number} value Pressure
 *
 * @returns {string} User-shown value
 */
function currentPresUnit(value) {
	var res = value.toFixed(2);
	var unit = rawPresUnit();
	return res + " " + unit;
}

/**
 * Take in values inside the `hourlyModel` structure and convert
 * them to the desired user units.
 *
 * @param {number} value Number in API unit
 * @param {string} prop Name of the property according to hourlyModel
 * @returns {number} Converted value
 */
function toUserProp(value, prop) {
	if (prop === "temperature") {
		return toUserTemp(value);
	} else if (prop === "precipitationRate") {
		return toUserPrecip(value, true);
	} else if (prop === "snowPrecipitationRate") {
		return toUserPrecip(value, false);
	} else if (prop === "wind") {
		return toUserSpeed(value);
	} else if (prop === "pressure") {
		return toUserPres(value);
	} else {
		return value;
	}
}

/**
 * Get hostname
 *
 * @returns {string} hostname
 */
function getAPIHost() {
	var hosts = ["aaa", "a91", "0a3", "75b", "fd6"];
	var host = hosts[Math.floor(Math.random() * hosts.length)];
	return "https://wps.mitchell-" + host + ".workers.dev";
}

/**
 * Calculate total light time between sunrise and sunset
 *
 * @param {string} sunrise Time in HH:MM format
 * @param {string} sunset Time in HH:MM format
 * @returns {string} Total light time in HH:MM format or "N/A"
 */
function calculateTotalLightTime(sunrise, sunset) {
	if (!sunrise || !sunset) return "N/A";
	try {
		var riseParts = sunrise.split(":");
		var setParts = sunset.split(":");
		var riseDate = new Date();
		riseDate.setHours(parseInt(riseParts[0]), parseInt(riseParts[1]), 0, 0);
		var setDate = new Date();
		setDate.setHours(parseInt(setParts[0]), parseInt(setParts[1]), 0, 0);
		if (setDate < riseDate) {
			setDate.setDate(setDate.getDate() + 1); // Next day
		}
		var diffMs = setDate - riseDate;
		var diffHours = Math.floor(diffMs / (1000 * 60 * 60));
		var diffMins = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
		return diffHours + ":" + (diffMins < 10 ? "0" : "") + diffMins;
	} catch (e) {
		return "N/A";
	}
}

function calculateTimeDifference(startDate, endDate, isShowSeconds) {
	printDebug(
		`Calculating time difference between ${startDate} and ${endDate}`,
	);
	var diff = new Date(endDate).getTime() - new Date(startDate).getTime();
	
	if (isNaN(diff) || diff < 0) {
		printDebug(`Invalid time difference: ${diff}`);
		return "N/A";
	}

	var totalSeconds = Math.floor(diff / 1000);
	var hours = Math.floor(totalSeconds / 3600);
	var minutes = Math.floor((totalSeconds % 3600) / 60);
	var seconds = totalSeconds % 60;

	printDebug(`Time difference reported as: ${hours}h ${minutes}m ${seconds}s`);

	if (isShowSeconds) {
		return `${hours}h ${minutes}m ${seconds}s`;
	} else {
		return `${hours}h ${minutes}m`;
	}
}

function calculateNeedlePosition(startDate, endDate) {
	printDebug("Calculating needle position");
	var startTs = new Date(startDate).getTime();
	var endTs = new Date(endDate).getTime();
	var nowTs = new Date().getTime();

	if (nowTs < startTs) {
		return 0;
	} else if (nowTs > endTs) {
		return 100;
	}

	var diff = endTs - startTs;

	var nowDiff = endTs - nowTs;

	var result = Math.round((nowDiff * 100) / diff);

	if (result < 0) {
		result = 0;
	} else if (result > 100) {
		result = 100;
	}

	printDebug(
		`Start ${startTs}, End: ${endTs}, diff: ${diff}, nowDiff: ${nowDiff}, effective needle: ${100 - result}`,
	);

	return 100 - result;
}

function getDayLength(startDate, endDate, isShowSeconds) {
	var dayLength = Utils.calculateTimeDifference(startDate, endDate, isShowSeconds);

	return dayLength;
}

function remainingUntilSinceDaylight(startDate, endDate, isShowSeconds) {
	var rise = new Date(startDate);
	var set = new Date(endDate);
	var now = new Date();
	var timeSunlight = "";

	printDebug(`Rise ${rise}, Set: ${set}, Now: ${now}`);

	if (now.getTime() < rise.getTime()) {
		timeSunlight =
			i18n("To sunrise") +
			": " +
			Utils.calculateTimeDifference(now, rise, isShowSeconds);

		printDebug(` ${timeSunlight}`);
	} else if (
		now.getTime() >= rise.getTime() &&
		now.getTime() < +set.getTime()
	) {
		timeSunlight =
			i18nc("Daylight remaining time, keep short", "Remaining") +
			": " +
			Utils.calculateTimeDifference(now, set, isShowSeconds);
		printDebug(` ${timeSunlight}`);
	} else if (now.getTime() > set.getTime()) {
		timeSunlight =
			i18n("Since sunset") +
			": " +
			Utils.calculateTimeDifference(set, now, isShowSeconds);
		printDebug(`${timeSunlight}`);
	}

	return timeSunlight;
}

function getMoonPhaseIcon(phaseCode) {
	var moonPhasesDict = {
		N: "\uF068",
		WXC: "\uF066",
		FQ: "\uF06A",
		WXG: "\uF067",
		F: "\uF069",
		WNG: "\uF065",
		LQ: "\uF063",
		WNC: "\uF064",
	};

	return moonPhasesDict[phaseCode];
}

/**
 * Convert temperature from user units to degrees Celsius.
 *
 * @param {number} value Temperature in user units
 * @returns {number} Temperature in degrees Celsius
 */
function userTempToC(value) {
	if (unitsChoice === UNITS_SYSTEM.CUSTOM) {
		if (plasmoid.configuration.tempUnitsChoice === TEMP_UNITS.C) {
			return value;
		} else if (plasmoid.configuration.tempUnitsChoice === TEMP_UNITS.F) {
			return fToC(value);
		} else {
			return kToC(value);
		}
	} else {
		if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
			return fToC(value);
		} else {
			return value;
		}
	}
}

/**
 * Convert pressure from user units to hPa (hectopascals).
 *
 * @param {number} value Pressure in user units
 * @returns {number} Pressure in hPa
 */
function userPresToHpa(value) {
	if (unitsChoice === UNITS_SYSTEM.CUSTOM) {
		if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.MB || plasmoid.configuration.presUnitsChoice === PRES_UNITS.HPA) {
			return value;
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.INHG) {
			return inhgToMb(value);
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.MMHG) {
			return mmhgToMb(value);
		} else if (plasmoid.configuration.presUnitsChoice === PRES_UNITS.PSI) {
			return psiToMb(value);
		}
	} else {
		if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
			return inhgToMb(value);
		} else {
			return value;
		}
	}
}

/**
 * Convert API temperature value to degrees Celsius.
 * API units depend on unitsChoice: CUSTOM=C, IMPERIAL=F, METRIC/HYBRID=C
 *
 * @param {number} value Temperature from API
 * @returns {number} Temperature in degrees Celsius
 */
function apiTempToC(value) {
	if (unitsChoice === UNITS_SYSTEM.CUSTOM || unitsChoice === UNITS_SYSTEM.METRIC || unitsChoice === UNITS_SYSTEM.HYBRID) {
		return value; // Already in C
	} else if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
		return fToC(value); // Convert F to C
	}
}

/**
 * Convert API pressure value to hPa (hectopascals).
 * API units depend on unitsChoice: CUSTOM=mb, IMPERIAL=inHG, METRIC/HYBRID=mb
 *
 * @param {number} value Pressure from API
 * @returns {number} Pressure in hPa
 */
function apiPresToHpa(value) {
	if (unitsChoice === UNITS_SYSTEM.CUSTOM || unitsChoice === UNITS_SYSTEM.METRIC || unitsChoice === UNITS_SYSTEM.HYBRID) {
		return value; // Already in mb/hPa
	} else if (unitsChoice === UNITS_SYSTEM.IMPERIAL) {
		return inhgToMb(value); // Convert inHG to mb
	}
}
