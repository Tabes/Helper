# Dokumentation: Universal Helper Functions (`helper.sh`)

**Version:** 2.1.0
**Autor:** Mawage (Development Team)
**Lizenz:** MIT

## Inhaltsverzeichnis

- [Dokumentation: Universal Helper Functions (`helper.sh`)](#dokumentation-universal-helper-functions-helpersh)
  - [Inhaltsverzeichnis](#inhaltsverzeichnis)
  - [1. Einleitung](#1-einleitung)
  - [2. Grundlegende Nutzung](#2-grundlegende-nutzung)
    - [Direkte Ausführung](#direkte-ausführung)
    - [Einbindung (Sourcing)](#einbindung-sourcing)
  - [3. Konfiguration](#3-konfiguration)
  - [4. Kernfunktionen](#4-kernfunktionen)
    - [4.1 `print` - Formatierte Ausgabe](#41-print---formatierte-ausgabe)
    - [4.2 `log` - Protokollierung](#42-log---protokollierung)
    - [4.3 `show` - Interaktive Anzeigen](#43-show---interaktive-anzeigen)
    - [4.4 `show_help` - Dynamische Hilfe](#44-show_help---dynamische-hilfe)
    - [4.5 `cmd` - Systemintegration](#45-cmd---systemintegration)
    - [4.6 `secure` - Berechtigungsverwaltung](#46-secure---berechtigungsverwaltung)
  - [5. Globale Variablen \& Anpassung](#5-globale-variablen--anpassung)
    - [Farben](#farben)
    - [Symbole](#symbole)
    - [Layout](#layout)

---

## 1. Einleitung

Die `helper.sh` ist das Kernmodul des Universal Helper Frameworks. Sie ist eine umfangreiche und modular aufgebaute Bibliothek von Hilfsfunktionen für die Bash-Programmierung. Sie dient als universelles Toolkit, um wiederkehrende Aufgaben wie formatierte Ausgaben, Protokollierung, interaktive Anzeigen, Systemintegration und Berechtigungsmanagement zu standardisieren und zu vereinfachen.

Das Design zielt auf hohe Konfigurierbarkeit, Erweiterbarkeit und Benutzerfreundlichkeit ab, indem es eine konsistente API für komplexe Operationen bereitstellt.

---

## 2. Grundlegende Nutzung

Das Skript kann auf zwei Arten verwendet werden: direkt ausgeführt oder in andere Skripte eingebunden (gesourct).

### Direkte Ausführung

Wenn das Skript direkt ausgeführt wird, startet es die `main`-Funktion. Ohne Argumente zeigt es eine Standard-Hilfeseite an.

```bash
./scripts/helper.sh
./scripts/helper.sh --help
./scripts/helper.sh --version
```

### Einbindung (Sourcing)

Dies ist der primäre Anwendungsfall. Durch das Sourcing des Skripts werden alle enthaltenen Funktionen in der aktuellen Shell-Sitzung oder in Ihrem eigenen Skript verfügbar gemacht.

**Beispiel für die Einbindung in ein eigenes Skript:**

```bash
#!/bin/bash

# Pfad zur helper.sh anpassen
source /pfad/zu/deinem/projekt/scripts/helper.sh

# Jetzt können die Funktionen genutzt werden
print --header "Mein Super-Skript"
log --info "Das Skript wurde gestartet."

# ... weiterer Code ...

log --info "Das Skript wurde beendet."
```

---

## 3. Konfiguration
3.1 Management (`load_config`)

Diese Funktion wird automatisch beim Start des Skripts (sowohl bei direkter Ausführung als auch beim Sourcing) aufgerufen. Sie ist das Herzstück der Konfiguration und führt folgende Schritte aus:

1.  **Projektverzeichnis finden:** Ermittelt dynamisch das Wurzelverzeichnis des Projekts.
2.  **Konfigurationen laden:** Sucht und lädt `project.conf` und alle weiteren `.conf`-Dateien aus dem `configs/`-Verzeichnis.
3.  **Skripte einbinden:** Lädt automatisch alle weiteren Hilfsskripte aus den Verzeichnissen `scripts/helper/` und `scripts/`.

> **Hinweis:** Skripte, deren Dateiname mit einem Unterstrich (`_`) beginnt, werden ignoriert. Dies erlaubt es, "private" oder unfertige Skripte im Verzeichnis zu belassen, ohne dass sie geladen werden.

3.2 Verzeichnisstruktur
3.3 Konfigurationsdateien

---

## 4. Kernfunktionen

Die Bibliothek ist in logische Funktionsblöcke unterteilt.

### 4.1 `print` - Formatierte Ausgabe

Diese Funktion ersetzt `echo` und `printf` durch eine einzige, vielseitige Schnittstelle für alle Terminal-Ausgaben.

**Syntax:** `print [OPTIONEN] [TEXT]...`

| Option                 | Beschreibung                                                                                             |
| ---------------------- | -------------------------------------------------------------------------------------------------------- |
| `--success <MSG>`      | Gibt eine Erfolgsmeldung in Grün mit einem ✓-Symbol aus.                                                 |
| `--error <MSG>`        | Gibt eine Fehlermeldung in Rot mit einem ✗-Symbol aus (auf `stderr`).                                    |
| `--warning <MSG>`      | Gibt eine Warnung in Gelb mit einem ⚠-Symbol aus.                                                        |
| `--info <MSG>`         | Gibt eine Info-Nachricht in Cyan mit einem ℹ-Symbol aus.                                                 |
| `--header <TITEL>`     | Zeigt einen prominenten, von Rauten umgebenen Header an.                                                  |
| `--line [CHAR]`        | Druckt eine horizontale Trennlinie. Das Zeichen (Standard: `#`) kann optional angegeben werden.         |
| `--left|-l <POS> <TXT>`| Richtet den Text `TXT` linksbündig an der Spaltenposition `POS` aus.                                      |
| `--right|-r <POS> <TXT>`| Richtet den Text `TXT` rechtsbündig an der Spaltenposition `POS` aus.                                     |
| `--cr [N]`             | Druckt `N` neue Zeilen (Standard: 1).                                                                    |
| `--no-nl|-n`           | Unterdrückt den automatischen Zeilenumbruch am Ende der Ausgabe.                                         |
| `<FARBE>`              | Setzt die Farbe für den nachfolgenden Text (z.B. `RD`, `GN`, `BU`). Siehe [Globale Variablen](#farben). |

**Beispiele:**

```bash
# Einfache Statusmeldungen
print --success "Operation erfolgreich abgeschlossen."
print --error "Datei nicht gefunden: /etc/hosts"

# Formatierte Ausgabe
print --header "System-Update"
print -l 4 "Paket:" -l 35 "nginx"
print -l 4 "Status:" -l 35 GN "Installiert"

# Ausgabe ohne Zeilenumbruch
print --no-nl "Prüfe System..."
sleep 2
print GN "OK"
```

### 4.2 `log` - Protokollierung

Eine umfassende Funktion zur Erstellung und Verwaltung von Log-Dateien.

**Syntax:** `log [OPERATION] [OPTIONEN]`

| Operation                    | Beschreibung                                                                                     |
| ---------------------------- | ------------------------------------------------------------------------------------------------ |
| `--init [FILE] [LEVEL]`      | **Initialisiert eine Log-Datei** mit einem ausführlichen Header. Erstellt Verzeichnisse bei Bedarf.    |
| `--info <MSG>`               | Schreibt eine Nachricht mit dem Level `INFO`.                                                    |
| `--error <MSG>`              | Schreibt eine Nachricht mit dem Level `ERROR`.                                                   |
| `--warning <MSG>`            | Schreibt eine Nachricht mit dem Level `WARNING`.                                                 |
| `--debug <MSG>`              | Schreibt eine Nachricht mit dem Level `DEBUG`.                                                   |
| `--rotate [FILE]`            | Führt eine Log-Rotation durch, falls die in der Konfiguration definierte Größe überschritten ist. |
| `--tail [FILE] [LINES]`      | Zeigt die letzten `LINES` (Standard: 20) der Log-Datei farblich formatiert an.                    |
| `--search <PATTERN> [FILE]`  | Durchsucht die Log-Datei nach einem `PATTERN` und gibt die Treffer farblich hervor.              |
| `--clear [FILE]`             | Leert die angegebene Log-Datei.                                                                  |

**Konfigurationsvariablen (`project.conf` oder `helper.conf`):**

* `LOG_DIR`: Standardverzeichnis für Log-Dateien.
* `LOG_LEVEL`: Log-Level (z.B. `INFO`, `DEBUG`).
* `CENTRAL_LOG`: Pfad zu einer zentralen Log-Datei, in die zusätzlich geschrieben wird.
* `LOG_ROTATION`: `true` oder `false`, um die Rotation zu aktivieren/deaktivieren.
* `LOG_MAX_SIZE`: Maximale Größe vor der Rotation (z.B. `10M`).
* `LOG_MAX_FILES`: Maximale Anzahl an rotierten Log-Dateien.

**Beispiel:**

```bash
# Logging initialisieren
log --init "/var/log/myapp.log" "DEBUG"

# Log-Einträge schreiben
log --info "Anwendung gestartet."
log --debug "Datenbankverbindung wird aufgebaut."
log --error "Verbindung fehlgeschlagen!"

# Log-Datei analysieren
log --tail "/var/log/myapp.log" 50
```

### 4.3 `show` - Interaktive Anzeigen

Diese Funktion stellt Elemente zur Interaktion mit dem Benutzer und zur visuellen Darstellung von Prozessen bereit.

**Syntax:** `show [OPERATION] [OPTIONEN]`

| Operation                    | Beschreibung                                                                                                     |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `--menu <TITEL> <OPTS...>`   | Erstellt ein einfaches, nummeriertes Menü mit dem Titel `TITEL` und den Optionen `OPTS`. Gibt die Auswahl zurück. |
| `--spinner <PID> [DELAY]`    | Zeigt einen ASCII-Spinner an, solange der Prozess mit der Prozess-ID `PID` läuft.                                   |
| `--progress <CUR> <TOTAL>`   | Stellt einen textbasierten Fortschrittsbalken dar (`CUR` = aktueller Wert, `TOTAL` = Gesamtwert).                    |
| `--version`                  | Zeigt formatierte Versionsinformationen des Skripts an.                                                          |
| `--doc <DATEI>`              | Zeigt eine Dokumentationsdatei mit grundlegender Markdown-Formatierung an.                                       |

**Beispiele:**

```bash
# Interaktives Menü
choice=$(show --menu "Aktion wählen" "Update starten" "Logs anzeigen" "System neustarten")
case "$choice" in
    1) echo "Update wird gestartet...";;
    2) echo "Logs werden angezeigt...";;
    3) echo "System wird neu gestartet...";;
    *) echo "Abbruch.";;
esac

# Spinner für einen Hintergrundprozess
(sleep 5) &
pid=$!
print --no-nl "Lade Daten..."
show --spinner $pid
print --success "Fertig."

# Fortschrittsbalken
for i in {1..100}; do
    show --progress $i 100 "Daten werden verarbeitet"
    sleep 0.05
done
```

### 4.4 `show_help` - Dynamische Hilfe

Eine leistungsstarke Funktion, die Hilfe-Texte aus Markdown-Dateien (`.md`) parst und formatiert im Terminal anzeigt.

**Syntax:** `show_help <FUNKTIONSNAME>`

`show_help` wird typischerweise innerhalb anderer Funktionen aufgerufen, um deren Hilfe anzuzeigen. Es erwartet, dass für die Funktion `<FUNKTIONSNAME>` eine Datei namens `<FUNKTIONSNAME>.md` im durch die Variable `HELP_FILE_DIR` definierten Verzeichnis existiert.

Die Funktion interpretiert grundlegendes Markdown:
* `#`, `##`, `###` für Überschriften.
* `-` für Aufzählungspunkte.
* Text, der von Tabs (`\t`) getrennt ist, wird an den in der `POS`-Array-Variable definierten Spalten ausgerichtet.
* Formatierungen wie `**bold**`, `*italic*`, `<u>underline</u>`.

**Beispiel für eine `log.md` Datei:**

```markdown
# Hilfe: log

Die `log` Funktion ist für die Protokollierung zuständig.

## Operationen

- --init [FILE] [LEVEL]	Initialisiert eine neue Log-Datei.
- --info <MSG>	Schreibt eine Info-Nachricht.
- --error <MSG>	Schreibt eine Fehlermeldung.

## Konfiguration

Folgende Variablen steuern das Verhalten:

- `LOG_DIR`	Standardverzeichnis für Logs.
- `LOG_LEVEL`	Minimales Level für Einträge.
```

### 4.5 `cmd` - Systemintegration

Diese Funktion dient dazu, Ihr Skript tief in das Betriebssystem zu integrieren, indem es als globaler Befehl verfügbar gemacht wird.

**Syntax:** `cmd [OPERATION] [NAME] [SKRIPT_PFAD]`

| Operation          | Beschreibung                                                                                                                                                             |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `--wrapper` oder `-w` | Erstellt ein Wrapper-Skript in `/usr/local/bin` oder `~/.local/bin`, das den Aufruf an Ihr Hauptskript weiterleitet. Dadurch wird Ihr Skript als globaler Befehl verfügbar. |
| `--alias` oder `-a`   | Fügt einen Alias in `~/.bash_aliases` hinzu.                                                                                                                               |
| `--completion` oder `-c`| Erstellt eine dynamische Bash-Vervollständigungsdatei in `/etc/bash_completion.d` oder `~/.bash_completion.d`. Sie analysiert Ihr Skript und schlägt Funktionen/Optionen vor. |
| `--all`            | Führt `--wrapper` und `--completion` gleichzeitig aus.                                                                                                                   |
| `--remove` oder `-r`  | Entfernt alle durch diese Funktion erstellten Integrationen (Wrapper, Completion, Alias).                                                                               |

**Beispiel:**

```bash
# Ihr Skript "mytool.sh" als Befehl "mytool" systemweit installieren
./mytool.sh cmd --all "mytool" "$(pwd)/mytool.sh"

# Danach können Sie von überall aufrufen:
# > mytool <funktion>
# > mytool <tab><tab>  -> zeigt verfügbare Funktionen an

# Deinstallation
./mytool.sh cmd --remove "mytool"
```

### 4.6 `secure` - Berechtigungsverwaltung

Eine Funktion zur Verwaltung von Dateisystemberechtigungen für Benutzer, um sicherheitsrelevante Operationen zu vereinfachen, ohne pauschal `sudo` zu verwenden.

**Syntax:** `secure [OPERATION] [PFAD] [BENUTZER]`

| Operation   | Beschreibung                                                                                                                                        |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--acl`     | Verwendet Access Control Lists (ACLs), um einem Benutzer Lese-/Schreib-/Ausführungsrechte (`rwx`) auf einen Pfad und alle Unterordner zu geben.      |
| `--group`   | Erstellt eine neue Unix-Gruppe, fügt den Benutzer hinzu und weist der Gruppe die Besitzrechte am Pfad zu.                                           |
| `--sudo`    | Erstellt eine `sudoers`-Datei, die dem Benutzer erlaubt, bestimmte Befehle (z.B. `rsync`, `cp`) ohne Passwort auszuführen. **(Mit Vorsicht verwenden!)** |
| `--check`   | Analysiert und zeigt die aktuellen Berechtigungen eines Benutzers für einen bestimmten Pfad an.                                                      |
| `--wizard`  | Startet einen interaktiven Assistenten, der durch die verschiedenen Setup-Methoden führt.                                                           |
| `--remove`  | Versucht, die durch diese Funktion gesetzten erweiterten Berechtigungen (ACLs, sudoers-Datei) wieder zu entfernen.                                   |

**Beispiel:**

```bash
# Dem Benutzer 'webdev' vollen Zugriff auf das Web-Verzeichnis /var/www/html geben
secure --acl /var/www/html webdev

# Aktuelle Rechte prüfen
secure --check /var/www/html webdev

# Interaktiver Modus
secure --wizard /var/www/html webdev
```

---

## 5. Globale Variablen & Anpassung

Das Verhalten und Aussehen der Helper-Funktionen kann durch globale Variablen angepasst werden, die typischerweise in `project.conf` oder einer anderen `.conf`-Datei im `configs/`-Verzeichnis gesetzt werden.

### Farben

Die folgenden Variablen können gesetzt werden, um die Standardfarben zu ändern.

* `COLOR_NC` (No Color)
* `COLOR_RD` (Red)
* `COLOR_GN` (Green)
* `COLOR_YE` (Yellow)
* `COLOR_BU` (Blue)
* `COLOR_CY` (Cyan)
* `COLOR_WH` (White)
* `COLOR_MG` (Magenta)

### Symbole

Die Symbole für Statusmeldungen können ebenfalls überschrieben werden.

* `SYMBOL_SUCCESS` (Standard: `✓`)
* `SYMBOL_ERROR` (Standard: `✗`)
* `SYMBOL_WARNING` (Standard: `⚠`)
* `SYMBOL_INFO` (Standard: `ℹ`)

### Layout

* `POS=(...)`: Ein Array von Zahlen, das die Spaltenpositionen für tabellarische Ausgaben in `show_help` definiert.
    * Beispiel: `POS=(4 25 50)` setzt die erste Spalte auf Position 4, die zweite auf 25 und die dritte auf 50.