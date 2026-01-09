#!/bin/bash

locales_arr=("${LANGUAGE//:/}")
first_locale="${locales_arr[0]:0:2}"

function window_title() {
    case "$first_locale" in
        "ru")
            printf "Создание новой папки";;
        "be")
            printf "Стварэнне новай тэчкi";;
        "sr")
            printf "Стварање нове мапе";;
        "uk")
            printf "Створення нової папки";;
        "nl")
            printf "Nieuwe map aanmaken";;
        "de")
            printf "Neuen Ordner erstellen";;
        "fr")
            printf "Créer un nouveau dossier";;
        "it")
            printf "Crea una nuova cartella";;
        "es")
            printf "Crear nueva carpeta";;
        *)
            printf "Create new folder";;
    esac
}

function window_message() {
    case "$first_locale" in
        "ru")
            printf "Укажите имя новой папки";;
        "be")
            printf "Пакажыце iмя новай тэчкi";;
        "sr")
            printf "Наведите име нове мапе";;
        "uk")
            printf "Вкажiть iм'я нової папки";;
        "nl")
            printf "Geef de nieuwe map een naam";;
        "de")
            printf "Neuen Ordner benennen";;
        "fr")
            printf "Définir le nom du nouveau dossier";;
        "it")
            printf "Imposta il nome della nuova cartella";;
        "es")
            printf "Establecer el nombre de la carpeta nueva";;
        *)
            printf "Set new folder name";;
    esac
}

function def_name() {
    case "$first_locale" in
        "ru")
            printf "Новая папка";;
        "be")
            printf "Новая тэчка";;
        "sr")
            printf "Нова мапа";;
        "uk")
            printf "Нова папка";;
        "nl")
            printf "Nieuwe map";;
        "de")
            printf "Neuer Ordner";;
        "fr")
            printf "Nouveau dossier";;
        "it")
            printf "Nuova cartella";;
        "es")
            printf "Nueva carpeta";;
        *)
            printf "New folder";;
    esac
}
