#!/bin/bash

# Konfigurierbare Variablen
stammverzeichnis="/data/"
email_empfaenger="${EMAIL_EMPFAENGER}"

# SMTP-Variablen aus der Umgebung laden
smtp_server="${SMTP_SERVER}"
smtp_port="${SMTP_PORT}"
smtp_user="${SMTP_USER}"
smtp_passwort="${SMTP_PASSWORT}"

# Aktuelles Datum ermitteln
aktuelles_datum=$(date +%Y-%m-%d)

# Funktion zum Senden einer E-Mail
function sende_email() {
  echo "Subject: Neue PDF-Datei erstellt" | ssmtp -t -v $email_empfaenger << EOF
Neue PDF-Datei erstellt im Verzeichnis $verzeichnis
EOF
}

# Funktion zum Prüfen auf neue Dateien
function pruefe_dateien() {
  for verzeichnis in $(find "$stammverzeichnis" -maxdepth 1 -type d -name "$aktuelles_datum*"); do
    # Prüfe in jedem gefundenen Verzeichnis nach neuen PDF-Dateien
    for pdf_datei in $(find "$verzeichnis" -name "*.pdf"); do
      sende_email
      break  # Abbruch, wenn eine neue PDF gefunden wurde
    done
  done
}

# Hauptprogramm
while true; do
  pruefe_dateien
  sleep 300  # Wartezeit in Sekunden
done