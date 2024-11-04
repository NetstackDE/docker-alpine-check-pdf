#!/bin/bash

# Configurable Variables
stammverzeichnis="/data/"
email_empfaenger="${EMAIL_EMPFAENGER}"
email_cc="${EMAIL_CC}"

# SMTP Variables from Environment
mailgun_apikey="${MAILGUN_APIKEY}"
mailgun_domain="${MAILGUN_DOMAIN}"
mailgun_tag="${MAILGUN_TAG}"
mail_from="${MAIL_FROM}"

# Get Current Date
aktuelles_datum=$(date +%d-%m-%Y)
flag_file="/tmp/email_sent_$aktuelles_datum.flag"  # Flag file to check if an email was already sent today
sent_files_log="/tmp/sent_pdfs_$aktuelles_datum.log"  # Log file to track which PDFs have been emailed today

# Function to Clean Up Old Log and Flag Files
function cleanup_old_logs() {
  echo "Cleaning up old .flag and .log files..."
  find /tmp -name 'email_sent_*.flag' ! -name "email_sent_$aktuelles_datum.flag" -type f -exec rm -f {} \;
  find /tmp -name 'sent_pdfs_*.log' ! -name "sent_pdfs_$aktuelles_datum.log" -type f -exec rm -f {} \;
}

# Function to Send an Email
function sende_email() {
  anhang="$1"  # Attachment file path
  dir="$2"     # Folder
  body="Neue PDF-Datei erstellt im Verzeichnis $dir"
  subject="Kopierreport $aktuelles_datum $(basename "$anhang")"
  echo "Sending email for file: $anhang"

  # Send email and save response
  response=$(curl --write-out "%{http_code}" --silent --output /dev/null --user "api:$mailgun_apikey" \
    "https://api.eu.mailgun.net/v3/$mailgun_domain/messages" \
    -F from="StudioMitte Kopierreport - <$mail_from>" \
    -F subject="$subject" \
    -F to="$email_empfaenger" \
    -F cc="$email_cc" \
    -F text="$body" \
    -F attachment="@$anhang" \
    -F o:tag="$mailgun_tag")

  # Check if the email was successfully sent
  if [[ "$response" -eq 200 ]]; then
    echo "Email successfully sent for $anhang to $email_empfaenger"
    echo "$anhang" >> "$sent_files_log"  # Log the sent file
    touch "$flag_file"  # Create flag file to indicate an email was sent today
  else
    echo "Failed to send email for $anhang. HTTP Status: $response"
  fi
}

# Function to Check for New Files and Send Emails
function pruefe_dateien() {
  # Check if we've already sent 10 files today
  sent_count=$(wc -l < "$sent_files_log" 2>/dev/null || echo 0)
  if [[ "$sent_count" -ge 10 ]]; then
    echo "10 emails have already been sent today. Skipping further emails."
    return
  fi

  echo "Starting folder search..."
  find "$stammverzeichnis" -maxdepth 10 -type d -name "$aktuelles_datum*" | while IFS= read -r verzeichnis; do
    echo "Searching for PDF files in: $verzeichnis"
    find "$verzeichnis" -name "*.pdf" | while IFS= read -r pdf_datei; do
      # Check if this file has already been sent today
      if grep -qxF "$pdf_datei" "$sent_files_log" 2>/dev/null; then
        echo "File $pdf_datei has already been sent today. Skipping."
        continue
      fi

      # Send email for this PDF
      sende_email "$pdf_datei" "$verzeichnis"

      # Update sent_count and check if we've reached the limit
      sent_count=$((sent_count + 1))
      if [[ "$sent_count" -ge 10 ]]; then
        echo "Reached daily limit of 10 emails. Stopping further emails."
        return  # Exit inner loop if limit is reached
      fi
    done
  done
}

# Check that all necessary environment variables are set
if [[ -z "$mailgun_apikey" || -z "$mailgun_domain" || -z "$mail_from" || -z "$email_empfaenger" ]]; then
  echo "Error: One or more required environment variables are missing."
  exit 1
fi

# Main Program
while true; do
  # Update current date (in case the day changes while the process runs)
  aktuelles_datum=$(date +%d-%m-%Y)
  flag_file="/tmp/email_sent_$aktuelles_datum.flag"
  sent_files_log="/tmp/sent_pdfs_$aktuelles_datum.log"

  # Clean up old logs and flags
  cleanup_old_logs

  # Perform daily file check
  pruefe_dateien
  
  # Wait time in seconds
  sleep 300
done
