import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kcmutils as KCM


KCM.SimpleKCM {
    // Properties
    property alias cfg_time_font_size: timeFontSize.value
    property alias cfg_month_font_size: monthFontSize.value
    property alias cfg_year_font_size: yearFontSize.value
    property alias cfg_day_font_size: dayFontSize.value
    property alias cfg_timeap_font_size: timeAPFontSize.value
    property alias cfg_sys_mon_text_font_size: sysMonTextFontSize.value
    property alias cfg_sys_mon_usage_font_size: sysMonUsageFontSize.value
    property alias cfg_audio_title_font_size: audioTitleFontSize.value
    property alias cfg_audio_artist_font_size: audioArtistFontSize.value
    property alias cfg_now_playing_font_size: nowPlayingFontSize.value
    property alias cfg_global_font_size: globalFontSize.value
    property alias cfg_audio_image_width: audioImageWidth.value

    property alias cfg_date_spacing: dateSpacing.value
    property alias cfg_audio_spacing: audioSpacing.value
    property alias cfg_sys_mon_spacing: sysMonSpacing.value

    property alias cfg_text_background_color: textBackgroundColor.color
    property alias cfg_color_one: colorOne.color
    property alias cfg_color_two: colorTwo.color
    property alias cfg_color_three: colorThree.color

    property alias cfg_proportional_font: proportionalFont.checked
    property alias cfg_enable_shadows: enableShadows.checked
    property alias cfg_show_sys_mon: showSysMon.checked
    property alias cfg_show_audio: showAudio.checked
    property alias cfg_enable_fill_animation: enableFillAnimation.checked
    property alias cfg_show_date: showDate.checked
    property alias cfg_enable_24_hour: enable24Hour.checked
    property alias cfg_use_system_colors: useSystemColors.checked
ColumnLayout {
    Title {
        text: i18n("Font Sizes")
    }
    BooleanField {
        id: proportionalFont
        text: i18n("Use proportional font")
    }
    NumberField {
        id: globalFontSize
        text: i18n("Global font size")
        enabled: proportionalFont.checked
    }
    NumberField {
        id: monthFontSize
        text: i18n("Month")
        enabled: !proportionalFont.checked
    }    
    NumberField {
        id: yearFontSize
        text: i18n("Year")
        enabled: !proportionalFont.checked
    }    
    NumberField {
        id: dayFontSize
        text: i18n("Day")
        enabled: !proportionalFont.checked
    }    
    NumberField {
        id: timeFontSize
        text: i18n("Time")
        enabled: !proportionalFont.checked
    }    
    NumberField {
        id: timeAPFontSize
        text: i18n("AM/PM")
        enabled: !proportionalFont.checked
    }    
    NumberField {
        id: sysMonTextFontSize
        text: i18n("System monitor title")
        enabled: !proportionalFont.checked
    }    
    NumberField {
        id: sysMonUsageFontSize
        text: i18n("System monitor usage")
        enabled: !proportionalFont.checked
    }    
    NumberField {
        id: audioTitleFontSize
        text: i18n("Music title")
        enabled: !proportionalFont.checked
    }    
    NumberField {
        id: audioArtistFontSize
        text: i18n("Music artist")
        enabled: !proportionalFont.checked
    }    
    NumberField {
        id: nowPlayingFontSize
        text: i18n("\"Now Playing\" text")
        enabled: !proportionalFont.checked
    }
    NumberField {
        id: audioImageWidth
        text: i18n("Music thumbnail width")
        enabled: !proportionalFont.checked
    }    
    
    Title {
        text: i18n("Spacing")
    }
    NumberField {
        id: dateSpacing
        text: i18n("Spacing between the month, day and year")
    }
    NumberField {
        id: sysMonSpacing
        text: i18n("Spacing between system monitor and time")
    }
    NumberField {
        id: audioSpacing
        text: i18n("Spacing between \"Now Playing\" and time")
    }
    
    Title {
        text: i18n("Colors")
    }
    BooleanField {
        id: useSystemColors 
        text: i18n("Use colors from the current color scheme")
    }
    ColorField {
        id: textBackgroundColor
        text: "Text Background Color"
    }
    ColorField {
        id: colorOne
        text: "Color 1"
    }
    ColorField {
        id: colorTwo
        text: "Color 2"
    }
    ColorField {
        id: colorThree
        text: "Color 3"
    }
    
    
    Title {
        text: i18n("Other")
    }
    BooleanField {
        id: enableShadows
        text: i18n("Enable shadows")
    }
    BooleanField {
        id: showDate
        text: i18n("Show Date")
    }
    BooleanField {
        id: showSysMon
        text: i18n("Show System Monitor")
    }
    BooleanField {
        id: showAudio
        text: i18n("Show \"Now Playing\"")
    }
    BooleanField {
        id: enableFillAnimation
        text: i18n("Show Fill Animation")
    }
    BooleanField {
        id: enable24Hour
        text: i18n("Use 24 hour clock")
    }
    
    
    
    // Tight Spacing
    Item {
        Layout.fillHeight: true
    }
}
}
