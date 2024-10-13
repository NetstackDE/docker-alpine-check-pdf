#!/bin/bash

# Konfigurierbare Variablen
stammverzeichnis="/data/"
email_empfaenger="${EMAIL_EMPFAENGER}"

# SMTP-Variablen aus der Umgebung laden
smtp_server="${SMTP_SERVER}"
smtp_port="${SMTP_PORT}"
smtp_user="${SMTP_USER}"
smtp_passwort="${SMTP_PASSWORT}"
smtp_config_file="/etc/ssmtp/ssmtp.conf"

# Aktuelles Datum ermitteln
aktuelles_datum=$(date +%d-%m-%Y)

#SSMTP Service CONFIG erstellen 
# Funktion zum Erstellen der ssmtp.conf
function create_ssmtp_config() {
  cat > "$smtp_config_file" << EOF
root=$smtp_user
mailhub=$smtp_server:$smtp_port
AuthUser=$smtp_user
AuthPassword=$smtp_passwort
UseTLS=yes
EOF
}

# Funktion zum Senden einer E-Mail
function sende_email() {
  echo "Subject: Neue PDF-Datei erstellt" | ssmtp -t -v $email_empfaenger << EOF
Neue PDF-Datei erstellt im Verzeichnis $verzeichnis
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