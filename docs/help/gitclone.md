# Git Workflow Manager (gitclone.sh)

## Beschreibung

Der Git Workflow Manager ist ein umfassendes Tool für die Verwaltung von Git-Repositories mit erweiterten Funktionen für Klonen, Synchronisation und Versionskontrolle.

## Verwendung

```bash
./gitclone.sh [OPTION] [PARAMETER]
```

oder als Bibliothek:
```bash
source gitclone.sh
gitclone [OPTION] [PARAMETER]
```

## Optionen

### Repository-Operationen

| Option | Kurz | Parameter | Beschreibung |
|--------|------|-----------|--------------|
| `--check` | `-c` | `[repo_dir] [branch]` | Prüft Repository gegen Remote |
| `--clone` | | `[url] [target] [branch]` | Klont Repository |
| `--init` | `-i` | `[repo_dir]` | Initialisiert Git-Repository |

### Synchronisation

| Option | Kurz | Parameter | Beschreibung |
|--------|------|-----------|--------------|
| `--pull` | | `[branch]` | Holt Änderungen vom Remote |
| `--push` | | `[tags]` | Pusht Änderungen zum Remote |
| `--sync` | `-s` | `[push_after]` | Vollständige Synchronisation |

### Allgemein

| Option | Kurz | Parameter | Beschreibung |
|--------|------|-----------|--------------|
| `--help` | `-h` | | Zeigt diese Hilfe an |
| `--version` | `-V` | | Zeigt Versionsinformationen |

## Beispiele

### Repository klonen
```bash
# Klont das Standard-Repository
gitclone --clone

# Klont spezifisches Repository
gitclone --clone "https://github.com/user/repo.git" "/opt/myproject" "main"
```

### Repository prüfen
```bash
# Prüft Standard-Repository
gitclone --check

# Prüft spezifisches Repository und Branch
gitclone --check "/opt/project" "develop"
```

### Synchronisation
```bash
# Holt nur Änderungen
gitclone --pull

# Pushed nur Änderungen
gitclone --push

# Pushed mit Tags
gitclone --push true

# Vollständige Synchronisation
gitclone --sync

# Synchronisation ohne Push
gitclone --sync false
```

### Repository initialisieren
```bash
# Initialisiert im Standard-Verzeichnis
gitclone --init

# Initialisiert in spezifischem Verzeichnis
gitclone --init "/opt/newproject"
```

## Konfiguration

Das Tool verwendet Konfigurationsvariablen aus `project.conf`:

### Git-Einstellungen
- `REPO_URL` - Standard-Repository-URL
- `REPO_BRANCH` - Standard-Branch (normalerweise "main")
- `REPO_REMOTE_NAME` - Remote-Name (normalerweise "origin")
- `PROJECT_ROOT` - Standard-Projektverzeichnis

### Benutzer-Einstellungen
- `GIT_USER_NAME` - Git-Benutzername
- `GIT_USER_EMAIL` - Git-E-Mail-Adresse

## Return-Codes

| Code | Bedeutung |
|------|-----------|
| `0` | Erfolg oder Updates verfügbar |
| `1` | Repository aktuell oder allgemeiner Fehler |
| `3` | Repository nicht erreichbar oder ungültig |

## Logging

Alle Operationen werden vollständig protokolliert:

- **Startup-Logging**: Jeder Funktionsaufruf mit Parametern
- **Operations-Logging**: Detaillierte Schritte jeder Operation  
- **Error-Logging**: Fehler und Warnungen mit Kontext
- **Success-Logging**: Erfolgreiche Abschlüsse mit Details

### Log-Format
```
[Timestamp] [Script] [Level] [Function] [Parameters] [Comment] [Additional]
```

## Abhängigkeiten

### Externe Befehle
- `git` - Git-Versionskontrolle
- Standard Unix-Tools (`mkdir`, `cd`, etc.)

### Helper-Funktionen
- `print` - Formatierte Ausgaben
- `log` - Erweiterte Protokollierung
- `show` - Interaktive Elemente
- `validate_directory` - Verzeichnis-Validierung
- `check_target_directory` - Zielverzeichnis-Prüfung
- `ask_yes_no` - Interaktive Bestätigung
- `safe_delete` - Sichere Löschfunktion

## Workflow-Beispiele

### Neues Projekt einrichten
```bash
# 1. Repository klonen
gitclone --clone "https://github.com/user/project.git" "/opt/myproject"

# 2. Repository prüfen
gitclone --check "/opt/myproject"
```

### Tägliche Entwicklung
```bash
# Morgens: Aktuelle Änderungen holen
gitclone --pull

# Abends: Änderungen hochladen
gitclone --push

# Oder: Vollständige Synchronisation
gitclone --sync
```

### Repository-Wartung
```bash
# Status prüfen
gitclone --check

# Forced Update bei Konflikten
gitclone --clone  # Überschreibt lokale Änderungen
```

## Fehlerbehebung

### Häufige Probleme

**"Not a git repository"**
```bash
# Repository initialisieren
gitclone --init [verzeichnis]
```

**"Cannot reach remote repository"**
- Internetverbindung prüfen
- Repository-URL in `project.conf` überprüfen
- SSH-Schlüssel oder Zugangsdaten prüfen

**"Failed to clone repository"**
- Zielverzeichnis-Berechtigungen prüfen
- Freien Speicherplatz prüfen
- Repository-URL und Branch prüfen

### Debug-Modus
Für detaillierte Ausgaben:
```bash
# Log-Level auf DEBUG setzen
export LOG_LEVEL="DEBUG"
gitclone [option]
```

## Integration

### Als Bibliothek verwenden
```bash
#!/bin/bash
source "/opt/helper/utilities/gitclone.sh"

# Funktionen direkt aufrufen
gitclone --sync
```

### In anderen Skripten
```bash
# Automatisches Update-System
if gitclone --check; then
    echo "Updates verfügbar"
    gitclone --pull
fi
```

---

**Version**: 1.0.0  
**Autor**: Mawage (Development Team)  
**Lizenz**: MIT