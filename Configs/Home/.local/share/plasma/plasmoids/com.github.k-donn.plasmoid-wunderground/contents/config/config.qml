/*
 * Copyright 2025  Kevin Donnelly
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
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Station")
        icon: "flag"
        source: "config/ConfigStation.qml"
    }
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "config/ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Units")
        icon: "configure"
        source: "config/ConfigUnits.qml"
    }
    ConfigCategory {
        name: i18n("Debug")
        icon: "preferences-other"
        source: "config/ConfigDebug.qml"
    }
}
