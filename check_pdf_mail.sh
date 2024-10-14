#!/bin/bash

# Konfigurierbare Variablen
stammverzeichnis="/data/"
email_empfaenger="${EMAIL_EMPFAENGER}"

# SMTP-Variablen aus der Umgebung laden
smtp_server="${SMTP_SERVER}"
smtp_port="${SMTP_PORT}"
smtp_user="${SMTP_USER}"
smtp_auth="on"
smtp_passwort="${SMTP_PASSWORT}"
config_file="/etc/msmtprc"

# Funktion zum Erstellen der msmtp-Konfigurationsdatei
create_msmtp_config() {
  cat > "$config_file" << EOF
account studiomitte
# SMTP-Server und Port
host $smtp_server
port $smtp_port

# Authentifizierung
auth $smtp_auth
user $smtp_user
password $smtp_password

# TLS
tls on
EOF
}

# Überprüfen, ob die Datei bereits existiert und warnen
if [ -f "$config_file" ]; then
  echo "Warnung: Die Datei '$config_file' existiert bereits. Sie wird überschrieben."
fi

# Konfigurationsdatei erstellen
create_msmtp_config

echo "msmtp-Konfigurationsdatei '$config_file' erfolgreich erstellt."

# Aktuelles Datum ermitteln
aktuelles_datum=$(date +%d-%m-%Y)

# Funktion zum Senden einer E-Mail
function sende_email() {
  body="Neue PDF-Datei erstellt im Verzeichnis $verzeichnis";
  subject="Kopierreport $aktuelles_datum $pdf_datei";
  # E-Mail versenden
  msmtp -v -t << EOF
Subject: $subject
From: $smtp_user
To: $email_empfaenger

$body
EOF
}

# Funktion zum Prüfen auf neue Dateien
function pruefe_dateien() {
  echo "start folder search ...";
  for verzeichnis in $(find "$stammverzeichnis" -maxdepth 10 -type d -name "$aktuelles_datum*"); do
    # Prüfe in jedem gefundenen Verzeichnis nach neuen PDF-Dateien
    echo "start file search";
    for pdf_datei in $(find "$verzeichnis" -name "*.pdf"); do
      echo "find PDF file";
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