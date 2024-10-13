FROM alpine:latest

# Paketinstallation (Beispiel: nur bash)
RUN apk add --no-cache bash ssmtp

# Arbeitsverzeichnis setzen
WORKDIR /app

# Dein Skript kopieren
COPY check_pdf_mail.sh /app

# Das Skript als Standardbefehl festlegen
CMD ["./check_pdf_mail.sh"]

