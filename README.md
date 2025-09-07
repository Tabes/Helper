# Universal Helper Functions - Bootstrap Installer

## Übersicht

Die `start.sh` ist ein Bootstrap-Installationsskript für das Universal Helper Framework. Es automatisiert die vollständige Installation und Konfiguration des Helper-Systems auf frischen Debian-Systemen.

## Features

- **Automatische Systemprüfung** - Erkennt Debian-Version und prüft Voraussetzungen
- **Abhängigkeiten-Management** - Installiert fehlende Pakete automatisch
- **Flexible Installation** - Unterstützt User- und System-weite Installation
- **Git-Integration** - Klont Framework direkt vom Repository
- **Fallback-Mechanismen** - Alternative Download-Methoden bei Problemen
- **System-Integration** - Richtet globale Commands und Bash-Completion ein

## Voraussetzungen

- Debian-basiertes System (empfohlen: aktuellste Version)
- Internetverbindung
- SSH-Zugang mit bekanntem root-Passwort
- Git-Repository mit dem Helper-Framework

## Installation

### Quick Start

```
bash
# Download start.sh
wget https://raw.githubusercontent.com/Tabes/helper/main/start.sh

# Ausführbar machen
chmod +x start.sh

# Interaktive Installation starten
./start.sh
```

# Installation mit Parametern

## Eigener Installationspfad
./start.sh --path ~/my-helper

## System-weite Installation (als root)
sudo ./start.sh --system

## Mit eigenem Repository
./start.sh --repo https://github.com/MYUSER/helper.git --branch develop

## Verbose-Modus für Debugging
./start.sh --verbose


# Optionen

OptionKurzBeschreibung--path PATH-pInstallations-Verzeichnis (Standard: ~/helper)--repo URL-rGit-Repository URL--branch NAME-bGit-Branch (Standard: main)--system-sSystem-weite Installation in /opt/helper--verbose-vAusführliche Ausgabe für Debugging--help-hZeigt Hilfe an


Workflow
Die Installation durchläuft folgende Schritte:

Interaktive Konfiguration (optional)

Abfrage von Installationspfad, Repository und Branch


System-Check

Prüfung der Debian-Version
Kontrolle essentieller Commands (git, curl, wget, sudo)
Test der Internetverbindung
Prüfung der Benutzerrechte


Abhängigkeiten installieren

Automatische Installation fehlender Pakete
Fallback zu manueller Installation bei fehlendem sudo


Framework Download

Git clone als primäre Methode
Wget als Fallback-Option
Automatisches Setzen der Berechtigungen


Struktur erstellen

Anlegen der Verzeichnisstruktur
Generierung der project.conf


System-Integration

Installation globaler Commands
Bash-Completion Setup
Integration in .bashrc



Nach der Installation
Nach erfolgreicher Installation:

Shell neu starten oder .bashrc neu laden:

source ~/.bashrc

Erweiterte Nutzung
Die setup Funktion kann auch einzeln aufgerufen werden:

# Nur System-Check
setup --check

# Nur Abhängigkeiten installieren
setup --dependencies

# Nur Framework downloaden
setup --download

# Nur Verzeichnisstruktur erstellen
setup --structure

# Nur System-Integration
setup --configure

# Komplette Installation
setup --complete


Fehlerbehebung
Bei Problemen:

Verbose-Modus aktivieren: ./start.sh --verbose
Log-Ausgaben prüfen
Manuelle Installation der Abhängigkeiten:

bash
sudo apt-get install git curl wget rsync


Lizenz
MIT License - siehe LICENSE Datei im Repository
Support
Bei Fragen oder Problemen: Issues im GitHub-Repository erstellen