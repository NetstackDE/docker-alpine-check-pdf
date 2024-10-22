#!/bin/bash

# Konfigurierbare Variablen
stammverzeichnis="/data/"
email_empfaenger="${EMAIL_EMPFAENGER}"
email_cc="${EMAIL_CC}"

# SMTP-Variablen aus der Umgebung laden
mailgun_apikey="${MAILGUN_APIKEY}"
mailgun_domain="${MAILGUN_DOMAIN}"
mailgun_tag="${MAILGUN_TAG}"
mail_from="${MAIL_FROM}"

# Aktuelles Datum ermitteln
aktuelles_datum=$(date +%d-%m-%Y)
flag_file="/tmp/email_sent_$aktuelles_datum.flag"  # Flag file to check if an email was already sent today

# Funktion zum Bereinigen alter Flag-Dateien
function cleanup_old_flags() {
  echo "Bereinige alte .flag Dateien..."
  find /tmp -name 'email_sent_*.flag' ! -name "email_sent_$aktuelles_datum.flag" -type f -exec rm -f {} \;
}

# Funktion zum Senden einer E-Mail
function sende_email() {
  anhang=$1  # Accept the first argument as the attachment file path
  dir=$2     # Folder
  body="Neue PDF-Datei erstellt im Verzeichnis $dir"
  subject="Kopierreport $aktuelles_datum $(basename "$anhang")"
  echo "in function path: $anhang"
  
  # E-Mail versenden und Antwort speichern
  response=$(curl --write-out "%{http_code}" --silent --output /dev/null --user "api:$mailgun_apikey" \
    "https://api.eu.mailgun.net/v3/$mailgun_domain/messages" \
    -F from="StudioMitte Kopierreport - <$mail_from>" \
    -F subject="$subject" \
    -F to="$email_empfaenger" \
    -F cc="$email_cc" \
    -F text="$body" \
    -F attachment="@$anhang" \
    -F o:tag="$mailgun_tag")
  
  # Überprüfen, ob die E-Mail erfolgreich gesendet wurde
  if [[ "$response" -eq 200 ]]; then
    echo "E-Mail erfolgreich gesendet an $email_empfaenger"
    # Flag-Datei erstellen, um festzustellen, dass für den Tag bereits eine E-Mail gesendet wurde
    touch "$flag_file"
  else
    echo "Fehler beim Senden der E-Mail. HTTP Status: $response"
  fi
}

# Funktion zum Prüfen auf neue Dateien
function pruefe_dateien() {
  # Prüfen, ob bereits eine E-Mail für den heutigen Tag gesendet wurde
  if [ -f "$flag_file" ]; then
    echo "E-Mail wurde bereits für heute gesendet ($aktuelles_datum)."
    return  # Keine weiteren Aktionen ausführen
  fi
  
  echo "start folder search ..."
  for verzeichnis in $(find "$stammverzeichnis" -maxdepth 10 -type d -name "$aktuelles_datum*"); do
    # Prüfe in jedem gefundenen Verzeichnis nach neuen PDF-Dateien
    echo "start file search"
    for pdf_datei in $(find "$verzeichnis" -name "*.pdf"); do
      echo "find PDF file"
      echo "fullpath: $pdf_datei"
      sende_email "$pdf_datei" "$verzeichnis"
      return  # Nur eine E-Mail pro Tag senden und Funktion verlassen
    done
  done
}

# Überprüfen, ob alle notwendigen Variablen gesetzt sind
if [[ -z "$mailgun_apikey" || -z "$mailgun_domain" || -z "$mail_from" || -z "$email_empfaenger" ]]; then
  echo "Fehler: Eine oder mehrere notwendige Umgebungsvariablen fehlen."
  exit 1
fi

# Hauptprogramm
while true; do
  # Aktuelles Datum aktualisieren (für den Fall, dass der Tag wechselt, während der Prozess läuft)
  aktuelles_datum=$(date +%d-%m-%Y)
  flag_file="/tmp/email_sent_$aktuelles_datum.flag"

  # Bereinige alte Flag-Dateien vor dem Start
  cleanup_old_flags

  # Tägliche Prüfung durchführen
  pruefe_dateien
  
  # Wartezeit in Sekunden
  sleep 300
done
