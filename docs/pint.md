# print() Funktion - Vollständige Dokumentation

## Überblick

Die `print()` Funktion ist das Herzstück der Universal Helper Library für formatierte Terminal-Ausgaben. Sie kombiniert alle Funktionalitäten der ursprünglichen `output()` Funktion mit erweiterten Features für moderne Terminal-Anwendungen.

**Version:** 2.0.0  
**Datei:** `scripts/helper/print.sh`  
**Abhängigkeiten:** helper.sh, log.sh, show.sh

## Kernfunktionalitäten

### 1. Ausgabe-Routing
- **Konsolen-Ausgabe** mit ANSI-Farben und Cursor-Steuerung
- **Datei-Ausgabe** ohne ANSI-Codes für saubere Logs
- **Automatische Pfad-Erstellung** für Ausgabe-Dateien
- **Append/Overwrite-Modi** für flexible Datei-Handhabung

### 2. Cursor-Positionierung
- **Absolute Positionierung** mit Spalte und Zeile
- **Relative Bewegung** basierend auf aktueller Position
- **Cursor-Caching** für Performance-Optimierung
- **Bounds-Checking** (1-200 für Position/Zeile)

### 3. Text-Formatierung
- **Links-/Rechtsbündige Ausrichtung** mit intelligenter Positionsberechnung
- **Farb-Unterstützung** für alle Standard-Terminal-Farben
- **Status-Nachrichten** mit Symbolen (Success, Error, Warning, Info)
- **Rahmen-Elemente** für strukturierte Ausgaben

### 4. Array-Verarbeitung
- **Multi-Line Ausgaben** mit Buffer-Management
- **Delay-Funktionen** zwischen Zeilen
- **Maximale Zeilen-Begrenzung** mit automatischem Scrollen
- **Intelligente Ausrichtung** basierend auf längster Zeile

## Parameter-Referenz

### Positionierung

#### `-pos COLUMN [ROW]`
Absolute Cursor-Positionierung
```bash
print -pos 10 "Text at column 10"
print -pos 30 5 "Text at column 30, row 5"
```

#### `-rel +/-N`
Relative Cursor-Bewegung
```bash
print -rel +5 "5 positions right"
print -rel -3 "3 positions left"
```

#### Bewegungsoptionen
```bash
print -back 3      # 3 Zeichen zurück
print -up 2        # 2 Zeilen nach oben
print -delete      # Aktuelle Zeile löschen
print -override    # Zeile überschreiben (Cursor an Anfang)
```

### Datei-Ausgabe

#### `-file PATH`
Ausgabe in Datei umleiten
```bash
print -file "/var/log/app.log" "Log entry"
print -file "output.txt" -overwrite "New content"
```

#### Modi
- `-append` - An Datei anhängen (Standard)
- `-overwrite` - Datei überschreiben

### Array-Verarbeitung

#### `-array [OPTIONS] ITEMS...`
Erweiterte Array-Ausgabe mit Optionen
```bash
print -array "Item 1" "Item 2" "Item 3"
print -array -delay 0.5 -max 5 "Line1" "Line2" "Line3"
```

#### `-row ITEMS... [-- NEXT_PARAMS]`
Einfache zeilenweise Ausgabe
```bash
print -row "Item1" "Item2" -- --success "Done"
```

#### Array-Optionen
- `-delay TIME` - Verzögerung zwischen Zeilen (Sekunden)
- `-max LINES` - Maximale Anzahl sichtbarer Zeilen
- `--` - Trenner zwischen Array-Daten und nachfolgenden Parametern

### Ausrichtung

#### Links-/Rechtsbündig
```bash
print --left 10 "Left aligned at pos 10"
print --right 80 "Right aligned at pos 80"
print -l 15 "Short form left"
print -r 70 "Short form right"
```

### Formatierung

#### Status-Nachrichten
```bash
print --success "Operation completed"
print --error "Something went wrong"
print --warning "Please check this"
print --info "Information message"
```

#### Rahmen und Strukturen
```bash
print --header "Section Title"
print -header "Custom Header"
print -line "=" 50
print -msg "Framed message"
```

#### Zeilen und Abstände
```bash
print --cr 2           # 2 Zeilenumbrüche
print -cr 3            # 3 Zeilenumbrüche
print --no-nl "Text"   # Ohne abschließenden Zeilenumbruch
```

### Debug-Tools

#### Positionierungshilfen
```bash
print -ruler     # Positions-Lineal mit Markierungen
print -ruler2    # Fein-Lineal mit Zahlen
print -scale     # Skalierung mit 10er-Schritten
print -demo      # Vollständige Demo aller Features
```

#### Debug-Informationen
```bash
print -debug              # Debug-Modus aktivieren
print -debug true         # Debug-Info anzeigen
print -reset              # Output-Buffer zurücksetzen
```

### Farben

#### Standard-Farben
```bash
print NC "Normal color"     # Normal/Reset
print RD "Red text"         # Rot
print GN "Green text"       # Grün
print YE "Yellow text"      # Gelb
print BU "Blue text"        # Blau
print CY "Cyan text"        # Cyan
print WH "White text"       # Weiß
print MG "Magenta text"     # Magenta
```

### Spezial-Parameter

#### Text-Ausgabe
```bash
print -txt "Pure text"     # Text ohne Positionierung
print -t "Short form"      # Kurze Form
```

#### Version und Hilfe
```bash
print --version "Header" "1.0" "commit-hash"
print --help              # Hilfe anzeigen
```

## Subfunctions Referenz

### Interne Funktionen (alphabetisch)

#### `_create_file_path()`
Erstellt Verzeichnispfad für Ausgabe-Datei und prüft Schreibberechtigungen.

#### `_format_and_output_line()`
Formatiert und gibt eine einzelne Zeile mit Positionierung aus.

#### `_get_cursor_position()`
Ermittelt aktuelle Cursor-Position mit Caching für Performance.

#### `_handle_positioning()`
Verwaltet Cursor-Positionierung und Ausrichtung mit Validierung.

#### `_invalid_operation()`
Behandelt ungültige Operationen mit standardisierten Fehlermeldungen.

#### `_output_router()`
Routet Ausgabe zu Konsole oder Datei mit optimierter Behandlung.

#### `_process_array()`
Verarbeitet Array-Ausgaben mit erweiterten Buffer-Management.

#### `_process_debug_tools()`
Behandelt Debug- und Ruler-Anzeige-Funktionen.

#### `_process_movement()`
Behandelt Cursor-Bewegungskommandos mit Validierung.

#### `_reset_output_buffer()`
Setzt Ausgabe-Arrays und Variablen zurück.

#### `_validate_parameters()`
Validiert Parameter-Typen und -Bereiche zentral.

## Verwendungsbeispiele

### Grundlegende Ausgabe
```bash
# Einfacher Text
print "Hello World"

# Mit Farbe
print GN "Success message"

# Position und Farbe
print -pos 20 RD "Red text at position 20"
```

### Erweiterte Positionierung
```bash
# Verschiedene Ausrichtungen
print -pos 10 --left "Left aligned"
print -pos 70 --right "Right aligned"

# Relative Bewegung
print "Start" -rel +5 "5 positions right"
```

### Datei-Ausgabe
```bash
# In Log-Datei schreiben
print -file "/var/log/app.log" "$(date): Application started"

# Strukturierte Logs
print -file "debug.log" -header "Debug Session"
print -file "debug.log" --info "Debug information"
```

### Array-Ausgaben
```bash
# Einfache Liste
print -array "Item 1" "Item 2" "Item 3"

# Mit Optionen
print -array -delay 0.3 -max 5 \
    "Processing file 1..." \
    "Processing file 2..." \
    "Processing file 3..."

# Gemischte Parameter
print -row "Step 1" "Step 2" "Step 3" -- --success "All steps completed"
```

### Strukturierte Ausgaben
```bash
# Header und Inhalt
print --header "System Status"
print --info "CPU Usage: 45%"
print --info "Memory: 2.1GB/8GB"
print --success "All systems operational"

# Rahmen und Linien
print -line "=" 60
print -msg "Important Notice"
print -line "-" 60
```

### Debug und Entwicklung
```bash
# Positionierung testen
print -ruler
print -scale
print -pos 25 "Test position 25"

# Debug-Informationen
print -debug true
print -pos 40 "Debug this position"
```

## Performance-Optimierungen

### Cursor-Caching
Die Funktion cached die Cursor-Position um Terminal-Queries zu reduzieren:
- Erste Abfrage wird gespeichert
- Nachfolgende Operationen nutzen Cache
- Reset mit `-reset` Parameter

### Buffer-Management
Array-Ausgaben nutzen intelligentes Buffer-Management:
- Sliding Window für große Arrays
- Automatisches Scrollen bei Überlauf
- Memory-effiziente Verarbeitung

### Error-Handling
Umfassende Fehlerbehandlung für:
- Ungültige Parameter (Zahlen, Bereiche)
- Datei-/Verzeichnis-Zugriffsrechte
- Terminal-Kompatibilität
- Resource-Limits

## Integration ins Framework

### Als Library verwenden
```bash
# In anderen Skripten
source "scripts/helper/print.sh"
print --success "Print functions loaded"
```

### Direkter Aufruf
```bash
# Als Script
./print.sh --demo
./print.sh --test
./print.sh -pos 10 "Direct call"
```

### Mit Helper-Framework
```bash
# Über helper.sh
helper print --success "Via framework"
```

## Kompatibilität

### Terminal-Unterstützung
- **ANSI-kompatible Terminals** (xterm, gnome-terminal, etc.)
- **SSH-Sessions** mit Terminal-Emulation
- **Screen/Tmux** Sessions
- **Fallbacks** für nicht-unterstützte Features

### Dateisystem
- **Automatische Pfad-Erstellung** für Log-Dateien
- **Berechtigungsprüfung** vor Schreibzugriff
- **Graceful Fallbacks** bei Zugriffsproblemen

### Abhängigkeiten
- **bash 4.0+** für erweiterte Array-Features
- **tput** für Cursor-Operationen
- **bc** für Floating-Point-Berechnungen (optional)

## Migration von output()

### Parameter-Mapping
```bash
# Alt: output() Syntax
output 10 "Text"                # → print -pos 10 "Text"
output -r 80 "Right"           # → print -pos 80 --right "Right"
output -f file.txt "Log"       # → print -file file.txt "Log"
output -row "A" "B" "C"        # → print -array "A" "B" "C"

# Neue Features (nur in print())
print -demo                     # Debug-Demo
print --success "Done"          # Status-Nachrichten
print -array -delay 0.5 "A"    # Array mit Delay
```

### Rückwärtskompatibilität
Die meisten output() Parameter funktionieren direkt in print(), neue Features erweitern die Funktionalität ohne Breaking Changes.

## Troubleshooting

### Häufige Probleme

#### Position außerhalb Bildschirm
```bash
# Problem: Position > Terminal-Breite
print -pos 120 "Text"

# Lösung: Bounds werden automatisch begrenzt (max 200)
# Alternative: Relative Positionierung nutzen
```

#### Datei-Schreibfehler
```bash
# Problem: Keine Berechtigung
print -file "/root/log.txt" "Entry"

# Lösung: Prüfung der Verzeichnis-Berechtigung
# Error wird automatisch gemeldet
```

#### Cursor-Position-Fehler
```bash
# Problem: Terminal unterstützt keine Cursor-Queries
# Lösung: Automatischer Fallback auf 1,1
# Cache mit -reset zurücksetzen
```

### Debug-Strategien
```bash
# 1. Debug-Modus aktivieren
print -debug true

# 2. Positionierung visualisieren
print -ruler
print -scale

# 3. Test-Suite ausführen
./print.sh --test
```

## Weiterführende Themen

### Erweiterungen
Die print() Funktion kann durch weitere Subfunctions erweitert werden:
- Zusätzliche Formatierungsoptionen
- Terminal-spezifische Optimierungen
- Integration weiterer Output-Formate

### Best Practices
- Nutze Status-Nachrichten für User-Feedback
- Verwende Datei-Ausgabe für Logs
- Teste Positionierung mit Debug-Tools
- Optimiere Performance mit Cursor-Caching

### Framework-Integration
- Konsistente Error-Handling mit anderen Modulen
- Einheitliche Logging-Integration
- Shared Configuration über project.conf