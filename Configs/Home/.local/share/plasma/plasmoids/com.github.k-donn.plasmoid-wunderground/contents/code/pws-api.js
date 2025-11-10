/*
 * Copyright 2025  Kevin Donnelly
 * Copyright 2024  dniminenn
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

/**
 * @callback requestCallback
 * @param {{ type: string, message: string }|null} err - Parsed error object
 * @param {Object|null} res - Returned response from the API
 * @param {number} status - Status of the API request
 * @param {string} raw - Raw responseText from the API
 */

/**
 * @callback responseCallback
 * @param {{ type: string, message: string }|null} err - Error object
 * @param {Object} res - API response
 */

// Load utility definitions
try {
	if (typeof Qt !== "undefined" && Qt.include) Qt.include("utils.js");
} catch (e) {
	// If Qt is not available (e.g. static analysis or unit tests), ignore.
}

if (typeof Utils === "undefined") {
	var Utils = {
		UNITS_SYSTEM: typeof UNITS_SYSTEM !== "undefined" ? UNITS_SYSTEM : {},
		PRES_UNITS: typeof PRES_UNITS !== "undefined" ? PRES_UNITS : {},
		hourlyModelDictV1:
			typeof hourlyModelDictV1 !== "undefined" ? hourlyModelDictV1 : {},
		hourlyModelDictV3:
			typeof hourlyModelDictV3 !== "undefined" ? hourlyModelDictV3 : {},
		severityColorMap:
			typeof severityColorMap !== "undefined" ? severityColorMap : {},
		toUserProp:
			typeof toUserProp !== "undefined"
				? toUserProp
				: function (val) {
						return val;
				  },
		getAPIHost:
			typeof getAPIHost !== "undefined"
				? getAPIHost
				: function () {
						return "";
				  },
	};
}

/**
 * Build a URL-encoded query string from an object of parameters.
 *
 * Example:
 *  _buildQuery({ a: 1, b: 'x y' }) -> 'a=1&b=x%20y'
 *
 * @param {Object} params - Key/value map of parameters to encode.
 * @returns {string} Encoded query string (no leading '?').
 */
function _buildQuery(params) {
	var pairs = [];
	for (var k in params) {
		if (!params.hasOwnProperty(k)) continue;
		var v = params[k];
		if (v === undefined || v === null) continue;
		pairs.push(encodeURIComponent(k) + "=" + encodeURIComponent(v));
	}
	return pairs.length ? pairs.join("&") : "";
}

/**
 * Build a full request URL by prepending the API host and appending
 * an encoded query string produced from `params`.
 *
 * This helper always calls Utils.getAPIHost() to select the runtime
 * API host used by the application.
 *
 * @param {string} path - API path (e.g. '/v3/location/search').
 * @param {Object} params - Query parameters.
 * @returns {string} Fully-qualified URL ready to be fetched.
 */
function _buildUrl(path, params) {
	var host = Utils.getAPIHost();
	var q = _buildQuery(params);
	return host + path + (q ? (path.indexOf("?") === -1 ? "?" : "&") + q : "");
}

/**
 * Perform a GET request and normalize the response via an error-first
 * callback.
 *
 * Callback signature:
 *   cb(err, res, status, raw)
 *
 * - On a successful 200 response `err` is null and `res` is the
 *   parsed JSON (or null when the response has no body).
 * - On a non-200 response `err` will be either an object with `{type,message}`
 * 	 or null if the error message came back non-json
 *
 * @param {string} url - The full URL to GET.
 * @param {requestCallback} cb - Error-first callback.
 */
function _httpGet(url, cb) {
	var req = new XMLHttpRequest();
	req.open("GET", url);
	req.onerror = function () {
		cb(
			{
				type: "Could not send request",
				message: req.statusText || "Network error",
			},
			null,
			req.status,
			req.responseText
		);
	};
	req.onreadystatechange = function () {
		if (req.readyState !== 4) return;
		if (req.status === 200) {
			try {
				var parsed = req.responseText
					? JSON.parse(req.responseText)
					: null;
				cb(null, parsed, req.status, req.responseText);
			} catch (e) {
				cb(
					{ type: "parse", message: e.message },
					null,
					req.status,
					req.responseText
				);
			}
		} else {
			// for non-200 we still provide parsed JSON if available
			var parsed = null;
			try {
				var resJson = req.responseText
					? JSON.parse(req.responseText)
					: null;
				if (
					resJson.hasOwnProperty("type") &&
					resJson.hasOwnProperty("message")
				) {
					parsed = resJson;
				} else {
					throw new Error();
				}
			} catch (e) {
				// ignore parse error here; most likely a cloudflare error
			}

			cb(parsed, null, req.status, req.responseText);
		}
	};
	req.send();
}

/**
 * Convert an internal unitsChoice value to the API response section
 * name used in station observation payloads.
 *
 * @param {number} unitsChoice - One of Utils.UNITS_SYSTEM.*
 * @returns {string} Section name used in observation payloads.
 */
function _unitsToSection(unitsChoice) {
	if (unitsChoice === Utils.UNITS_SYSTEM.METRIC) return "metric";
	if (unitsChoice === Utils.UNITS_SYSTEM.IMPERIAL) return "imperial";
	if (unitsChoice === Utils.UNITS_SYSTEM.HYBRID) return "uk_hybrid";
	return "metric";
}

/**
 * Convert an internal unitsChoice value to the single-letter API units
 * query parameter used by Wunderground ("m"/"e"/"h").
 *
 * @param {number} unitsChoice - One of Utils.UNITS_SYSTEM.*
 * @returns {string} Single-letter units code for the API request.
 */
function _unitsToQuery(unitsChoice) {
	if (unitsChoice === Utils.UNITS_SYSTEM.METRIC) return "m";
	if (unitsChoice === Utils.UNITS_SYSTEM.IMPERIAL) return "e";
	if (unitsChoice === Utils.UNITS_SYSTEM.HYBRID) return "h";
	return "m";
}

/**
 * Return a reasonable chart-range value for pressure based on unit
 * preferences. This is used to set axis ranges for pressure charts.
 *
 * @param {number} unitsChoice - One of Utils.UNITS_SYSTEM.*
 * @param {number} [presUnitsChoice] - Optional explicit pressure unit when using CUSTOM units.
 * @returns {number} Numeric range appropriate to the chosen units.
 */
function _pressureRangeForUnits(unitsChoice, presUnitsChoice) {
	// If the caller provides a specific presUnitsChoice (custom), prefer that
	if (typeof unitsChoice === "undefined")
		unitsChoice = Utils.UNITS_SYSTEM.METRIC;
	if (
		unitsChoice === Utils.UNITS_SYSTEM.METRIC ||
		unitsChoice === Utils.UNITS_SYSTEM.HYBRID
	) {
		return 70; // mb / hPa style
	}
	if (unitsChoice === Utils.UNITS_SYSTEM.IMPERIAL) {
		return 2.1; // inHG style
	}
	// custom - fall back to provided presUnitsChoice when available
	if (presUnitsChoice === Utils.PRES_UNITS.INHG) return 2.1;
	if (presUnitsChoice === Utils.PRES_UNITS.MMHG) return 53;
	return 70;
}

/**
 * Normalize a locale string into the API language form (e.g. 'en-US').
 * If no localeStr is supplied this will use Qt.locale() when available
 * and fall back to 'en-US'.
 *
 * @param {string} [localeStr]
 * @returns {string} Normalized language tag.
 */
function _formatLanguage(localeStr) {
	if (localeStr) return localeStr.replace("_", "-");
	if (typeof Qt !== "undefined" && Qt.locale)
		return Qt.locale().name.replace("_", "-");
	return "en-US";
}

/**
 * Extract the country/territory code from a locale string.
 * Examples: 'en_US' -> 'US', 'fr-FR' -> 'FR'.
 *
 * @param {string} [localeStr]
 * @returns {string} The country code or an empty string when none found.
 */
function _countryCodeFromLocale(localeStr) {
	var name =
		localeStr ||
		(typeof Qt !== "undefined" && Qt.locale ? Qt.locale().name : "");
	if (!name) return "";
	var parts = name.split(/[_-]/);
	return parts.length > 1 ? parts[1] : parts[0];
}

var _SNOW_ICON_CODES = [5, 13, 14, 15, 16, 42, 43, 46];
/**
 * Return true when the provided icon code corresponds to snowy
 * precipitation in the mapping used by the widget.
 *
 * @param {number} iconCode
 * @returns {boolean}
 */
function _isSnowIconCode(iconCode) {
	return _SNOW_ICON_CODES.indexOf(iconCode) !== -1;
}

/**
 * Handle API fields that could be null. If not null, return.
 * Otherwise, return two dashes for placeholder.
 *
 * @param value API value
 * @returns {any|"--"} `value` or "--"
 */
function nullableField(value) {
	if (value !== null) {
		return value;
	} else {
		return "--";
	}
}

/**
 * Find the territory code and return the air quality scale used there.
 *
 * @returns {string} Air quality scale
 */
function getAQScale(localeOrCountry) {
	var countryCode = _countryCodeFromLocale(localeOrCountry);
	var map = {
		CN: "HJ6332012",
		FR: "ATMO",
		DE: "UBA",
		GB: "DAQI",
		IN: "NAQI",
		MX: "IMECA",
		ES: "CAQI",
	};
	return map[countryCode] || "EPA";
}

/**
 * Determine if a PWS station is actively reporting and compute a simple
 * health count of available observation fields.
 *
 * Signature:
 *   isStationActive(stationId, { unitsChoice }, cb)
 *
 * Callback: cb(err, { isActive: boolean, healthCount: number })
 *
 * @param {string} givenID - Station identifier
 * @param {Object} options - Options specific to the call
 * @param {number} [options.unitsChoice] - Units preference (one of Utils.UNITS_SYSTEM)
 * @param {responseCallback} callback - Error-first callback
 */
function isStationActive(givenID, options, callback) {
	options = options || {};
	callback = callback || function () {};

	var units =
		options.unitsChoice !== undefined
			? options.unitsChoice
			: Utils.UNITS_SYSTEM.METRIC;

	var url = _buildUrl("/v2/pws/observations/current", {
		stationId: givenID,
		format: "json",
		units: _unitsToQuery(units),
		numericPrecision: "decimal",
	});

	printDebug("[pws-api.js] " + url);

	_httpGet(url, function (err, res, status, raw) {
		if (err || status !== 200) {
			callback(
				err || {
					type: status || "network",
					message: raw || "Request failed",
				},
				null
			);
			return;
		}

		var requiredObs = [
			"stationID",
			"obsTimeUtc",
			"obsTimeLocal",
			"neighborhood",
			"country",
			"solarRadiation",
			"lat",
			"lon",
			"uv",
			"winddir",
			"humidity",
		];

		var sectionName = _unitsToSection(units);
		var obs = res && res.observations ? res.observations[0] : null;
		if (!obs) {
			callback({ isActive: false, healthCount: 0 }, null);
			return;
		}

		var details = obs[sectionName] || {};
		var healthCount = 0;
		for (var key in details) {
			if (details[key] !== null) healthCount += 1;
		}
		for (var key2 in obs) {
			if (
				key2 !== sectionName &&
				requiredObs.indexOf(key2) !== -1 &&
				obs[key2] !== null
			)
				healthCount += 1;
		}

		callback(null, { isActive: true, healthCount: healthCount });
	});
}

/**
 * Search for nearby PWS stations by query text.
 *
 * Signature:
 *   searchStationID(query, { language }, cb)
 *
 * Callback: cb(err, Array<{stationID,address,latitude,longitude,qcStatus}>)
 *
 * @param {string} query
 * @param {Object} options
 * @param {string} [options.language]
 * @param {responseCallback} callback
 */
function searchStationID(query, options, callback) {
	options = options || {};
	callback = callback || function () {};

	var language = options.language || _formatLanguage();
	var url = _buildUrl("/v3/location/search", {
		query: query,
		locationType: "pws",
		language: language,
		format: "json",
	});

	printDebug("[pws-api.js] " + url);

	_httpGet(url, function (err, res, status, raw) {
		if (err || status !== 200) {
			if (status === 404)
				callback({ type: "404", message: "No stations found" }, null);
			else
				callback(
					err || {
						type: status || "network",
						message: raw || "Request failed",
					},
					null
				);
			return;
		}

		var stationsArr = [];
		var loc = res && res.location;
		if (loc) {
			var count = Array.isArray(loc.pwsId)
				? loc.pwsId.length
				: Array.isArray(loc.address)
				? loc.address.length
				: 0;
			for (var i = 0; i < count; i++) {
				stationsArr.push({
					stationID: loc.pwsId ? loc.pwsId[i] : "",
					address: loc.neighborhood ? loc.neighborhood[i] : "",
					latitude: loc.latitude ? loc.latitude[i] : 0,
					longitude: loc.longitude ? loc.longitude[i] : 0,
					qcStatus: 0,
				});
			}
		}

		callback(null, stationsArr);
	});
}

/**
 * Search for PWS stations near a lat/lon coordinate.
 *
 * Signature:
 *   searchGeocode({latitude,longitude}, { language }, cb)
 *
 * Callback: cb(err, Array<{stationID,address,latitude,longitude}>)
 *
 * @param {{latitude:number,longitude:number}} latLongObj
 * @param {Object} options
 * @param {string} [options.language]
 * @param {responseCallback} callback
 */
function searchGeocode(latLongObj, options, callback) {
	options = options || {};
	callback = callback || function () {};

	var latitude = latLongObj.latitude;
	var longitude = latLongObj.longitude;

	var url = _buildUrl("/v3/location/near", {
		geocode: latitude + "," + longitude,
		product: "pws",
		format: "json",
	});

	printDebug("[pws-api.js] " + url);

	_httpGet(url, function (err, res, status, raw) {
		if (err || status !== 200) {
			if (status === 404)
				callback({ type: "404", message: "No stations found" }, null);
			else
				callback(
					err || {
						type: status || "network",
						message: raw || "Request failed",
					},
					null
				);
			return;
		}

		var stationsArr = [];
		var loc = res && res.location;
		if (loc && Array.isArray(loc.stationId)) {
			for (var i = 0; i < loc.stationId.length; i++) {
				stationsArr.push({
					stationID: loc.stationId[i],
					address: loc.stationName ? loc.stationName[i] : "",
					latitude: loc.latitude ? loc.latitude[i] : 0,
					longitude: loc.longitude ? loc.longitude[i] : 0,
					qcStatus: loc.qcStatus ? loc.qcStatus[i] : 0,
				});
			}
		}

		callback(null, stationsArr);
	});
}

/**
 * Search for the qualified name of a city the user searches for.
 * This can then be used to search for stations in that area.
 *
 * @param {string} city Textual city description
 * @param {(res: Array<{city: string, country: string, latitude: float, longitude: float}>, error: {type: string, message: string}) => void} callback
 */
/**
 * Search for geographic locations (cities) matching free text.
 *
 * Signature:
 *   getLocations(city, { language }, cb)
 *
 * Callback: cb(err, Array<{city,state,country,latitude,longitude}>)
 *
 * @param {string} city
 * @param {Object} options
 * @param {string} [options.language]
 * @param {responseCallback} callback
 */
function getLocations(city, options, callback) {
	options = options || {};
	callback = callback || function () {};

	var language = options.language || _formatLanguage();
	var url = _buildUrl("/v3/location/search", {
		query: city,
		locationType: "city,locality,state,address",
		language: language,
		format: "json",
	});

	printDebug("[pws-api.js] " + url);

	_httpGet(url, function (err, res, status, raw) {
		if (err || status !== 200) {
			if (status === 404)
				callback(
					{ type: "404", message: i18n("Location not found") },
					null
				);
			else
				callback(
					err || {
						type: status || "network",
						message: raw || "Request failed",
					},
					null
				);
			return;
		}

		var locationsArr = [];
		var loc = res && res.location;
		if (loc) {
			var count = Array.isArray(loc.address) ? loc.address.length : 0;
			for (var i = 0; i < count; i++) {
				locationsArr.push({
					address: loc.address ? loc.address[i] : "",
					latitude: loc.latitude ? loc.latitude[i] : 0,
					longitude: loc.longitude ? loc.longitude[i] : 0,
				});
			}
		}

		callback(null, locationsArr);
	});
}

/**
 * Pull the most recent observation from the selected weather station.
 *
 * This handles setting errors and making the loading screen appear.
 *
 * @param {() => void} [callback=function() {}] Function to call after this and getExtendedConditions
 */
/**
 * Fetch the most recent observation for a configured station.
 *
 * Signature:
 *   getCurrentData({ stationID, unitsChoice, oldWeatherData }, cb)
 *
 * Callback: cb(err, { weatherData, configUpdates })
 *  - weatherData: shaped data used by the widget
 *  - configUpdates: latitude/longitude/stationName values discovered
 *
 * @param {Object} options
 * @param {string} options.stationID
 * @param {number} [options.unitsChoice]
 * @param {Object} [options.oldWeatherData]
 * @param {function(Object|null, Object|null)} callback
 */
function getCurrentData(options, callback) {
	options = options || {};
	callback = callback || function () {};

	var station = options.stationID;
	var units =
		options.unitsChoice !== undefined
			? options.unitsChoice
			: Utils.UNITS_SYSTEM.METRIC;
	var prevWeather = options.oldWeatherData || null;

	var url = _buildUrl("/v2/pws/observations/current", {
		stationId: station,
		format: "json",
		units: _unitsToQuery(units),
		numericPrecision: "decimal",
	});

	printDebug("[pws-api.js] " + url);

	_httpGet(url, function (err, res, status, raw) {
		if (err || status !== 200) {
			callback(
				err || {
					type: status || "network",
					message: raw || "Request failed",
				},
				null
			);
			return;
		}

		var sectionName = _unitsToSection(units);
		var obs = res && res.observations ? res.observations[0] : null;
		if (!obs) {
			callback(
				{ type: "no_data", message: "No observation returned" },
				null
			);
			return;
		}

		var details = obs[sectionName] || {};
		var newWeather = {
			stationID: obs["stationID"],
			uv: nullableField(obs["uv"]),
			humidity: obs["humidity"],
			solarRad: nullableField(obs["solarRadiation"]),
			obsTimeLocal: obs["obsTimeLocal"],
			winddir: obs["winddir"],
			latitude: obs["lat"],
			longitude: obs["lon"],
			neighborhood: obs["neighborhood"],
			isNight: prevWeather ? prevWeather["isNight"] : false,
			sunrise: prevWeather ? prevWeather["sunrise"] : "",
			sunset: prevWeather ? prevWeather["sunset"] : "",
			details: {
				temp: details["temp"],
				heatIndex: details["heatIndex"],
				dewpt: details["dewpt"],
				windChill: details["windChill"],
				windSpeed: details["windSpeed"],
				windGust: details["windGust"],
				pressure: details["pressure"],
				precipRate: details["precipRate"],
				precipTotal: details["precipTotal"],
				elev: details["elev"],
				solarRad: prevWeather ? prevWeather["solarRad"] : null,
				pressureTrend: prevWeather
					? prevWeather["pressureTrend"]
					: null,
				pressureTrendCode: prevWeather
					? prevWeather["pressureTrendCode"]
					: null,
				pressureDelta: prevWeather
					? prevWeather["pressureDelta"]
					: null,
			},
			aq: prevWeather && prevWeather["aq"] ? prevWeather["aq"] : {},
		};

		var configUpdates = {
			latitude: obs["lat"],
			longitude: obs["lon"],
			stationName: obs["neighborhood"],
		};

		callback(null, {
			weatherData: newWeather,
			configUpdates: configUpdates,
		});
	});
}

/**
 * Get broad weather info from station area including textual/icon description of conditions and weather warnings.
 *
 * @param {() => void} [callback=function() {}] Function to call after extended conditions are fetched
 */
/**
 * Fetch extended area-level information (day/night, icons, alerts, AQ).
 *
 * Signature:
 *   getExtendedConditions({ latitude, longitude, unitsChoice, language, oldWeatherData }, cb)
 *
 * Callback: cb(err, {
 *   isNight, sunriseTimeLocal, sunsetTimeLocal, pressureTendencyTrend,
 *   pressureTendencyCode, pressureChange, iconCode, conditionNarrative,
 *   isRain, alerts, airQuality
 * })
 *
 * @param {Object} options
 * @param {number} options.latitude
 * @param {number} options.longitude
 * @param {number} [options.unitsChoice]
 * @param {string} [options.language]
 * @param {Object} [options.oldWeatherData]
 * @param {function(Object|null, Object|null)} callback
 */
function getExtendedConditions(options, callback) {
	options = options || {};
	callback = callback || function () {};

	var longitude = options.longitude;
	var latitude = options.latitude;
	var units =
		options.unitsChoice !== undefined
			? options.unitsChoice
			: Utils.UNITS_SYSTEM.METRIC;
	var language = options.language || _formatLanguage();
	var prevWeather = options.oldWeatherData || null;

	var url = _buildUrl(
		"/v3/aggcommon/v3-wx-observations-current;v3alertsHeadlines;v3-wx-globalAirQuality",
		{
			geocodes: latitude + "," + longitude,
			language: language,
			scale: getAQScale(language),
			units: _unitsToQuery(units),
			format: "json",
		}
	);

	printDebug("[pws-api.js] " + url);

	_httpGet(url, function (err, res, status, raw) {
		if (err || status !== 200) {
			callback(
				err || {
					type: status || "network",
					message: raw || "Request failed",
				},
				null
			);
			return;
		}

		var combinedVars = res && res[0] ? res[0] : null;
		if (!combinedVars) {
			callback(
				{ type: "no_data", message: "No extended conditions returned" },
				null
			);
			return;
		}

		var condVars = combinedVars["v3-wx-observations-current"];
		var alertsVars = combinedVars["v3alertsHeadlines"];
		var airQualVars = combinedVars["v3-wx-globalAirQuality"]
			? combinedVars["v3-wx-globalAirQuality"]["globalairquality"]
			: null;

		var isNight = condVars && condVars["dayOrNight"] === "N";
		var newIconCode = condVars ? condVars["iconCode"] : null;
		var newConditionNarrative = condVars ? condVars["wxPhraseLong"] : "";
		var newIsRain = newIconCode ? !_isSnowIconCode(newIconCode) : true;

		var alertsList = [];
		if (
			alertsVars !== null &&
			alertsVars &&
			Array.isArray(alertsVars["alerts"])
		) {
			var alerts = alertsVars["alerts"];
			for (var ai = 0; ai < alerts.length; ai++) {
				var curAlert = alerts[ai];
				var actions = [];
				if (Array.isArray(curAlert["responseTypes"])) {
					for (
						var actionIndex = 0;
						actionIndex < curAlert["responseTypes"].length;
						actionIndex++
					) {
						actions.push(
							curAlert["responseTypes"][actionIndex][
								"responseType"
							]
						);
					}
				}
				var source =
					(curAlert["source"] || "") +
					" - " +
					(curAlert["officeName"] || "") +
					", " +
					(curAlert["officeCountryCode"] || "");
				var disclaimer =
					curAlert["disclaimer"] !== null
						? curAlert["disclaimer"]
						: "None";
				alertsList.push({
					desc: curAlert["eventDescription"],
					severity: curAlert["severity"],
					severityColor:
						Utils.severityColorMap[curAlert["severityCode"]],
					headline: curAlert["headlineText"],
					area: curAlert["areaName"],
					action: actions.join(","),
					source: source,
					disclaimer: disclaimer,
				});
			}
		}

		var aqObj = null;
		if (airQualVars) {
			var primaryPollutant = airQualVars["primaryPollutant"];
			var primaryDetails = airQualVars["pollutants"]
				? airQualVars["pollutants"][primaryPollutant]
				: null;
			aqObj = {
				aqi: airQualVars["airQualityIndex"],
				aqhi: airQualVars["airQualityCategoryIndex"],
				aqDesc: airQualVars["airQualityCategory"],
				aqColor: airQualVars["airQualityCategoryIndexColor"],
				aqPrimary: airQualVars["primaryPollutant"],
				primaryDetails: primaryDetails
					? {
							phrase: primaryDetails["phrase"],
							amount: primaryDetails["amount"],
							unit: primaryDetails["unit"],
							desc: primaryDetails["category"],
							index: primaryDetails["index"],
					  }
					: null,
				messages: {
					general: {
						title: airQualVars["messages"]["General"]["title"],
						phrase: airQualVars["messages"]["General"]["text"],
					},
					sensitive: {
						title: airQualVars["messages"]["Sensitive Group"][
							"title"
						],
						phrase: airQualVars["messages"]["Sensitive Group"][
							"text"
						],
					},
				},
			};
		}

		var result = {
			isNight: isNight,
			sunriseTimeLocal: condVars ? condVars["sunriseTimeLocal"] : null,
			sunsetTimeLocal: condVars ? condVars["sunsetTimeLocal"] : null,
			pressureTendencyTrend: condVars
				? condVars["pressureTendencyTrend"]
				: null,
			pressureTendencyCode: condVars
				? condVars["pressureTendencyCode"]
				: null,
			pressureChange: condVars ? condVars["pressureChange"] : null,
			iconCode: newIconCode,
			conditionNarrative: newConditionNarrative,
			isRain: newIsRain,
			alerts: alertsList,
			airQuality: aqObj,
		};

		callback(null, result);
	});
}

/**
 * Fetch forecast data using the configured API (V1 or V3).
 *
 * Signature:
 *   getForecastData({ latitude, longitude, unitsChoice, useLegacyAPI, language }, cb)
 *
 * Callback: cb(err, { forecast: Array<day>, currDayHigh, currDayLow })
 *
 * @param {Object} options
 * @param {number} options.latitude
 * @param {number} options.longitude
 * @param {number} [options.unitsChoice]
 * @param {boolean} [options.useLegacyAPI]
 * @param {string} [options.language]
 * @param {function(Object|null, Object|null)} callback
 */
function getForecastData(options, callback) {
	options = options || {};
	callback = callback || function () {};

	var useLegacy = options.useLegacyAPI || false;
	if (useLegacy) getForecastDataV1(options, callback);
	else getForecastDataV3(options, callback);
}

/**
 * V3 forecast implementation.
 *
 * @param {Object} options
 * @param {number} options.latitude
 * @param {number} options.longitude
 * @param {number} [options.unitsChoice]
 * @param {string} [options.language]
 * @param {function(Object|null, Object|null)} callback
 */
function getForecastDataV3(options, callback) {
	options = options || {};
	callback = callback || function () {};

	var longitude = options.longitude;
	var latitude = options.latitude;
	var units =
		options.unitsChoice !== undefined
			? options.unitsChoice
			: Utils.UNITS_SYSTEM.METRIC;
	var language = options.language || _formatLanguage();

	var url = _buildUrl("/v3/wx/forecast/daily/7day", {
		geocode: latitude + "," + longitude,
		language: language,
		units: _unitsToQuery(units),
		format: "json",
	});

	printDebug("[pws-api.js] " + url);

	_httpGet(url, function (err, res, status, raw) {
		if (err || status !== 200) {
			callback(
				err || {
					type: status || "network",
					message: raw || "Request failed",
				},
				null
			);
			return;
		}

		var dailyForecastVars = res;
		var dailyDayPart = dailyForecastVars["daypart"]
			? dailyForecastVars["daypart"][0]
			: null;
		var forecastArr = [];
		var count = dailyForecastVars["dayOfWeek"]
			? dailyForecastVars["dayOfWeek"].length
			: 0;
		for (var period = 0; period < count; period++) {
			var isFirstNight =
				period === 0 &&
				dailyDayPart &&
				dailyDayPart["temperature"] &&
				dailyDayPart["temperature"][0] === null;
			var daypartPeriod = isFirstNight ? 1 : period * 2;
			var date = new Date(dailyForecastVars["validTimeLocal"][period]);
			var high = isFirstNight
				? dailyDayPart["temperature"][daypartPeriod]
				: dailyForecastVars["calendarDayTemperatureMax"][period];
			var low = isFirstNight
				? dailyForecastVars["temperatureMin"][period]
				: dailyForecastVars["calendarDayTemperatureMin"][period];

			var heatIndexThresh, windChillThresh;
			if (units === Utils.UNITS_SYSTEM.METRIC) {
				heatIndexThresh = 21.1;
				windChillThresh = 16.17;
			} else if (units === Utils.UNITS_SYSTEM.IMPERIAL) {
				heatIndexThresh = 70;
				windChillThresh = 61;
			} else if (units === Utils.UNITS_SYSTEM.HYBRID) {
				heatIndexThresh = 294.26;
				windChillThresh = 289.32;
			} else {
				heatIndexThresh = 21.1;
				windChillThresh = 16.17;
			}

			var tempVal =
				dailyDayPart && dailyDayPart["temperature"]
					? dailyDayPart["temperature"][daypartPeriod]
					: null;
			var feelsLike =
				tempVal !== null && tempVal > heatIndexThresh
					? dailyDayPart["temperatureHeatIndex"][daypartPeriod]
					: dailyDayPart["temperatureWindChill"][daypartPeriod];

			var shortDesc =
				dailyDayPart &&
				dailyDayPart["wxPhraseShort"] &&
				dailyDayPart["wxPhraseShort"][daypartPeriod] !== ""
					? dailyDayPart["wxPhraseShort"][daypartPeriod]
					: dailyDayPart && dailyDayPart["wxPhraseLong"]
					? dailyDayPart["wxPhraseLong"][daypartPeriod]
					: "";

			var snowDesc =
				dailyDayPart &&
				dailyDayPart["snowRange"] &&
				dailyDayPart["snowRange"][daypartPeriod] !== ""
					? dailyDayPart["snowRange"][daypartPeriod]
					: "N/A";
			var thunderDesc =
				dailyDayPart &&
				typeof dailyDayPart["thunderCategory"] !== "undefined" &&
				dailyDayPart["thunderCategory"][daypartPeriod] !== null &&
				dailyDayPart["thunderCategory"][daypartPeriod] !== ""
					? dailyDayPart["thunderCategory"][daypartPeriod]
					: "N/A";

			forecastArr.push({
				date: date,
				dayOfWeek:
					dailyDayPart && dailyDayPart["daypartName"]
						? dailyDayPart["daypartName"][daypartPeriod]
						: "",
				iconCode:
					dailyDayPart && dailyDayPart["iconCode"]
						? dailyDayPart["iconCode"][daypartPeriod]
						: null,
				high: high,
				low: low,
				feelsLike: feelsLike,
				shortDesc: shortDesc,
				longDesc:
					dailyForecastVars && dailyForecastVars["narrative"]
						? dailyForecastVars["narrative"][period]
						: "",
				thunderDesc: thunderDesc,
				windDesc:
					dailyDayPart && dailyDayPart["windPhrase"]
						? dailyDayPart["windPhrase"][daypartPeriod]
						: "",
				uvDesc:
					dailyDayPart && dailyDayPart["uvDescription"]
						? dailyDayPart["uvDescription"][daypartPeriod]
						: "",
				snowDesc: snowDesc,
				golfDesc: !isFirstNight
					? "Good day for golf."
					: "Don't play golf at night.",
			});
		}

		var currDayHigh = forecastArr.length ? forecastArr[0].high : null;
		var currDayLow = forecastArr.length ? forecastArr[0].low : null;

		printDebug("[pws-api.js] Got new forecast data");
		callback(null, {
			forecast: forecastArr,
			currDayHigh: currDayHigh,
			currDayLow: currDayLow,
		});
	});
}

/**
 * V1 forecast implementation.
 *
 * @param {Object} options
 * @param {number} options.latitude
 * @param {number} options.longitude
 * @param {number} [options.unitsChoice]
 * @param {string} [options.language]
 * @param {function(Object|null, Object|null)} callback
 */
function getForecastDataV1(options, callback) {
	options = options || {};
	callback = callback || function () {};

	var latitude = options.latitude;
	var longitude = options.longitude;
	var units =
		options.unitsChoice !== undefined
			? options.unitsChoice
			: Utils.UNITS_SYSTEM.METRIC;
	var language = options.language || _formatLanguage();

	var url = _buildUrl(
		"/v1/geocode/" +
			latitude +
			"/" +
			longitude +
			"/forecast/daily/7day.json",
		{
			language: language,
			units: _unitsToQuery(units),
		}
	);

	printDebug("[pws-api.js] " + url);

	_httpGet(url, function (err, res, status, raw) {
		if (err || status !== 200) {
			callback(
				err || {
					type: status || "network",
					message: raw || "Request failed",
				},
				null
			);
			return;
		}

		var forecasts = res ? res["forecasts"] : [];
		var forecastArr = [];
		for (var period = 0; period < forecasts.length; period++) {
			var forecast = forecasts[period];
			var day = forecast["day"];
			var night = forecast["night"];
			var isDay = day !== undefined;
			var date = new Date(forecast["fcst_valid_local"]);

			var snowDesc = isDay
				? day["snow_phrase"] === ""
					? "No snow"
					: day["snow_phrase"]
				: night["snow_phrase"] === ""
				? "No snow"
				: night["snow_phrase"];
			var thunderDesc = isDay
				? day["thunder_enum_phrase"] !== null
					? day["thunder_enum_phrase"]
					: "N/A"
				: night["thunder_enum_phrase"] !== null
				? night["thunder_enum_phrase"]
				: "N/A";
			var shortDesc = isDay
				? day["phrase_12char"] !== ""
					? day["phrase_12char"]
					: day["phrase_32char"]
				: night["phrase_12char"] !== ""
				? night["phrase_12char"]
				: night["phrase_32char"];

			forecastArr.push({
				date: date,
				dayOfWeek: isDay ? forecast["dow"] : "Tonight",
				iconCode: isDay ? day["icon_code"] : night["icon_code"],
				high: isDay ? forecast["max_temp"] : night["hi"],
				low: forecast["min_temp"],
				feelsLike: isDay ? day["wc"] : night["wc"],
				shortDesc: shortDesc,
				longDesc: isDay ? day["narrative"] : night["narrative"],
				thunderDesc: thunderDesc,
				winDesc: isDay ? day["wind_phrase"] : night["wind_phrase"],
				uvDesc: isDay ? day["uv_desc"] : night["uv_desc"],
				snowDesc: snowDesc,
				golfDesc: isDay
					? day["golf_category"]
					: "Don't play golf at night.",
			});
		}

		var currDayHigh = forecastArr.length ? forecastArr[0].high : null;
		var currDayLow = forecastArr.length ? forecastArr[0].low : null;

		printDebug("[pws-api.js] Got new forecast data");
		callback(null, {
			forecast: forecastArr,
			currDayHigh: currDayHigh,
			currDayLow: currDayLow,
		});
	});
}

/**
 * Wrapper for hourly data fetching — selects V1 or V3 depending on
 * the `useLegacyAPI` flag in options.
 *
 * Signature:
 *   getHourlyData({ latitude, longitude, unitsChoice, useLegacyAPI, language }, cb)
 *
 * Callback: cb(err, { hourly: Array<hour>, maxValDict, rangeValDict })
 *
 * @param {Object} options
 * @param {number} options.latitude
 * @param {number} options.longitude
 * @param {number} [options.unitsChoice]
 * @param {boolean} [options.useLegacyAPI]
 * @param {string} [options.language]
 * @param {function(Object|null, Object|null)} callback
 */
function getHourlyData(optionsOrCallback, callback) {
	var options = optionsOrCallback || {};
	callback = callback || function () {};

	var useLegacy = options.useLegacyAPI || false;
	if (useLegacy) getHourlyDataV1(options, callback);
	else getHourlyDataV3(options, callback);
}

/**
 * V1 hourly forecast implementation.
 *
 * @param {Object} options
 * @param {number} options.latitude
 * @param {number} options.longitude
 * @param {number} [options.unitsChoice]
 * @param {string} [options.language]
 * @param {function(Object|null, Object|null)} callback
 */
function getHourlyDataV1(options, callback) {
	options = options || {};
	callback = callback || function () {};

	var latitude = options.latitude;
	var longitude = options.longitude;
	var units =
		options.unitsChoice !== undefined
			? options.unitsChoice
			: Utils.UNITS_SYSTEM.METRIC;
	var language = options.language || _formatLanguage();

	var url = _buildUrl(
		"/v1/geocode/" +
			latitude +
			"/" +
			longitude +
			"/forecast/hourly/24hour.json",
		{
			language: language,
			units: _unitsToQuery(units),
		}
	);

	printDebug("[pws-api.js] " + url);

	_httpGet(url, function (err, res, status, raw) {
		if (err || status !== 200) {
			callback(
				err || {
					type: status || "network",
					message: raw || "Request failed",
				},
				null
			);
			return;
		}

		var forecasts = res ? res["forecasts"] : [];
		var valueNames = Object.entries(Utils.hourlyModelDictV1);
		var hourlyArr = [];
		var localMax = {};
		for (var i = 0; i < valueNames.length; i++)
			localMax[valueNames[i][0]] = Number.NEGATIVE_INFINITY;

		for (
			var period = 0;
			period < forecasts.length && period !== 22 && period !== 23;
			period++
		) {
			var forecast = forecasts[period];
			var time = new Date(forecast["fcst_valid_local"]);
			var hourModel = { time: time };
			for (var prop = 0; prop < valueNames.length; prop++) {
				var modelName = valueNames[prop][0];
				var apiName = valueNames[prop][1];
				var val = Utils.toUserProp(forecast[apiName], modelName);
				hourModel[modelName] = val;
				if (
					typeof val === "number" &&
					!isNaN(val) &&
					val > localMax[modelName]
				)
					localMax[modelName] = val;
			}
			hourlyArr.push(hourModel);
		}

		var rangeDict = {};
		for (var pi = 0; pi < valueNames.length; pi++) {
			var mName = valueNames[pi][0];
			if (
				mName === "cloudCover" ||
				mName === "humidity" ||
				mName === "precipitationChance"
			) {
				rangeDict[mName] = 100;
			} else if (mName === "pressure") {
				rangeDict[mName] = _pressureRangeForUnits(
					units,
					options.presUnitsChoice
				);
			} else {
				rangeDict[mName] =
					localMax[mName] === Number.NEGATIVE_INFINITY
						? 0
						: localMax[mName];
			}
		}

		var sanitizedMax = {};
		for (var lm in localMax)
			sanitizedMax[lm] =
				localMax[lm] === Number.NEGATIVE_INFINITY ? 0 : localMax[lm];
		callback(null, {
			hourly: hourlyArr,
			maxValDict: sanitizedMax,
			rangeValDict: rangeDict,
		});
	});
}

/**
 * V3 hourly forecast implementation.
 *
 * @param {Object} options
 * @param {number} options.latitude
 * @param {number} options.longitude
 * @param {number} [options.unitsChoice]
 * @param {string} [options.language]
 * @param {function(Object|null, Object|null)} callback
 */
function getHourlyDataV3(options, callback) {
	options = options || {};
	callback = callback || function () {};

	var latitude = options.latitude;
	var longitude = options.longitude;
	var units =
		options.unitsChoice !== undefined
			? options.unitsChoice
			: Utils.UNITS_SYSTEM.METRIC;
	var language = options.language || _formatLanguage();

	var url = _buildUrl("/v3/wx/forecast/hourly/2day", {
		geocode: latitude + "," + longitude,
		language: language,
		units: _unitsToQuery(units),
		format: "json",
	});

	printDebug("[pws-api.js] " + url);

	_httpGet(url, function (err, res, status, raw) {
		if (err || status !== 200) {
			callback(
				err || {
					type: status || "network",
					message: raw || "Request failed",
				},
				null
			);
			return;
		}

		var valueNames = Object.entries(Utils.hourlyModelDictV3);
		var hourlyArr = [];
		var localMax = {};
		for (var i = 0; i < valueNames.length; i++)
			localMax[valueNames[i][0]] = Number.NEGATIVE_INFINITY;

		for (var period = 0; period < 22; period++) {
			var hourModel = { time: new Date(res["validTimeLocal"][period]) };
			for (var prop = 0; prop < valueNames.length; prop++) {
				var modelName = valueNames[prop][0];
				var apiName = valueNames[prop][1];
				var val = Utils.toUserProp(res[apiName][period], modelName);
				hourModel[modelName] = val;
				if (
					typeof val === "number" &&
					!isNaN(val) &&
					val > localMax[modelName]
				)
					localMax[modelName] = val;
			}
			hourlyArr.push(hourModel);
		}

		var rangeDict = {};
		for (var pi = 0; pi < valueNames.length; pi++) {
			var mName = valueNames[pi][0];
			if (
				mName === "cloudCover" ||
				mName === "humidity" ||
				mName === "precipitationChance"
			) {
				rangeDict[mName] = 100;
			} else if (mName === "pressure") {
				rangeDict[mName] = _pressureRangeForUnits(
					units,
					options.presUnitsChoice
				);
			} else {
				rangeDict[mName] =
					localMax[mName] === Number.NEGATIVE_INFINITY
						? 0
						: localMax[mName];
			}
		}

		var sanitizedMax2 = {};
		for (var lm2 in localMax)
			sanitizedMax2[lm2] =
				localMax[lm2] === Number.NEGATIVE_INFINITY ? 0 : localMax[lm2];
		callback(null, {
			hourly: hourlyArr,
			maxValDict: sanitizedMax2,
			rangeValDict: rangeDict,
		});
	});
}
