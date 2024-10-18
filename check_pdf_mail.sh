#!/bin/bash

# Konfigurierbare Variablen
stammverzeichnis="/data/"
email_empfaenger="${EMAIL_EMPFAENGER}"

# SMTP-Variablen aus der Umgebung laden
mailgun_apikey="${MAILGUN_APIKEY}"
mailgun_domain="${MAILGUN_DOMAIN}"
mailgun_tag="${MAILGUN_TAG}"
mail_from="${MAIL_FROM}"

# Aktuelles Datum ermitteln
aktuelles_datum=$(date +%d-%m-%Y)

# Funktion zum Senden einer E-Mail
function sende_email() {
  anhang=$1  # Accept the first argument as the attachment file path
  dir=$2 # Folder
  body="Neue PDF-Datei erstellt im Verzeichnis $dir"
  subject="Kopierreport $aktuelles_datum $anhang"
  echo "in function path: $anhang";
  # E-Mail versenden
  curl --user "api:$mailgun_apikey" \
    "https://api.eu.mailgun.net/v3/$mailgun_domain/messages" \
    -F from="StudioMitte Kopierreport - <$mail_from>" \
    -F subject="$subject" \
    -F to="$email_empfaenger" \
    -F message="$body" \
    -F attachment="@$anhang" \
    -F o:tag="$mailgun_tag"
}

# Funktion zum Prüfen auf neue Dateien
function pruefe_dateien() {
  echo "start folder search ...";
  for verzeichnis in $(find "$stammverzeichnis" -maxdepth 10 -type d -name "$aktuelles_datum*"); do
    # Prüfe in jedem gefundenen Verzeichnis nach neuen PDF-Dateien
    echo "start file search";
    for pdf_datei in $(find "$verzeichnis" -name "*.pdf"); do
      echo "find PDF file";
      echo "fullpath: $pdf_datei"
      sende_email "$pdf_datei" "$verzeichnis"
      break  # Abbruch, wenn eine neue PDF gefunden wurde
    done
  done
}

# Hauptprogramm
while true; do
  pruefe_dateien
  sleep 300  # Wartezeit in Sekunden
done