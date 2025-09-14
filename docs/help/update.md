# Update System - Standalone Update Management

## Übersicht

Das Update-System ermöglicht die sichere Aktualisierung des Helper-Frameworks ohne Git-Abhängigkeiten. Es lädt einzelne Dateien herunter, validiert sie mit Checksummen und erstellt automatische Backups mit Rollback-Funktionalität.

## Funktionsweise

Das System nutzt ein Manifest-basiertes Verfahren:
- Downloads über wget/curl von konfigurierbaren Repository-URLs
- SHA256-Checksummen zur Dateiversifizierung
- Automatische Backup-Erstellung vor Updates
- Rollback-Mechanismus bei Fehlern

## Verwendung

### Grundlegende Syntax
```bash
update [OPTION]
```

### Verfügbare Parameter

#### `--check` / `-c`
Prüft verfügbare Updates ohne Installation.

```bash
update --check
```

**Ausgabe:**
- Aktuelle Projektversion
- Liste verfügbarer Updates
- Neue Dateien und Versionsunterschiede

#### `--install` / `-i`
Führt vollständige Update-Installation durch.

```bash
update --install
```

**Ablauf:**
1. Backup-Erstellung
2. Manifest-Download
3. Datei-Downloads mit Validierung
4. Installation der Dateien
5. Cleanup alter Backups

#### `--download` / `-d`
Lädt Updates nur herunter, installiert nicht.

```bash
update --download
```

**Verwendung:**
- Test-Downloads vor Installation
- Offline-Vorbereitung
- Validierung vor Produktiv-Update

#### `--rollback` / `-r`
Stellt vorherige Version aus Backup wieder her.

```bash
update --rollback <backup-name>
```

**Backup auflisten:**
```bash
update --rollback
```

**Beispiel:**
```bash
update --rollback update-20250914-143022
```

#### `--force` / `-f`
Erzwingt Update trotz Download-Fehlern.

```bash
update --install --force
```

**Verwendung:**
- Partielle Updates bei Netzwerkproblemen
- Überspringen defekter Dateien
- Notfall-Updates

#### `--help` / `-h`
Zeigt Hilfe-Information an.

```bash
update --help
```

#### `--version` / `-V`
Zeigt Version des Update-Systems an.

```bash
update --version
```

### Standard-Verhalten

Ohne Parameter prüft das System automatisch auf verfügbare Updates:

```bash
update
```

Entspricht `update --check`

## Konfiguration

### Repository-Einstellungen

**Update-URLs:**
```bash
UPDATE_BASE_URL="https://raw.githubusercontent.com/Tabes/Helper/refs/heads/main"
UPDATE_BRANCH="main"
```

**Manifest-Dateien:**
```bash
UPDATE_MANIFEST="update-manifest.txt"
CHECKSUM_FILE="checksums.sha256"
```

### Download-Konfiguration

**Retry-Einstellungen:**
```bash
MAX_DOWNLOAD_RETRIES=3
DOWNLOAD_TIMEOUT=30
```

**Tool-Präferenzen:**
```bash
PREFERRED_DOWNLOAD_TOOL="curl"  # curl, wget, auto
DOWNLOAD_TOOLS_FALLBACK="true"
```

### Backup-Konfiguration

**Backup-Verhalten:**
```bash
BACKUP_RETENTION_DAYS=30
BACKUP_COMPRESSION="true"
MAX_BACKUP_COUNT=10
```

**Backup-Verzeichnisse:**
```bash
UPDATE_BACKUP_DIR="${BACKUP_DIR}/update-$(date +%Y%m%d-%H%M%S)"
UPDATE_TMP_DIR="${CACHE_DIR}/update-tmp"
```

## Manifest-Format

Das Update-Manifest definiert verfügbare Dateien:

```
# Kommentare beginnen mit #
datei_pfad|version|checksum|beschreibung

scripts/helper.sh|2.1.0|a1b2c3d4...|Haupt-Helper Skript
configs/project.conf|2.1.0|e5f6g7h8...|Projekt-Konfiguration
utilities/update.sh|1.0.5|-|Update-System
```

**Format-Erklärung:**
- **datei_pfad:** Relativer Pfad ab PROJECT_ROOT
- **version:** Versionsnummer der Datei
- **checksum:** SHA256-Prüfsumme (optional: "-")
- **beschreibung:** Kurze Beschreibung der Änderung

## Sicherheitsfeatures

### Backup-System

**Automatische Backups:**
- Vor jedem Update erstellt
- Zeitstempel-basierte Benennung
- Kritische Dateien (Configs, Scripts)
- Backup-Manifest mit Metadaten

**Backup-Struktur:**
```
backups/
└── update-20250914-143022/
    ├── backup-info.txt
    ├── configs/
    │   ├── project.conf
    │   └── helper.conf
    └── scripts/
        └── helper.sh
```

### Validierung

**Checksummen-Prüfung:**
- SHA256-Algorithmus
- Vor Installation validiert
- Fehlerhafte Dateien verworfen
- Optional (konfigurierbar)

**Download-Validierung:**
- Dateigröße-Prüfung
- Existenz-Verifikation
- Retry-Mechanismen
- Timeout-Schutz

### Rollback-Mechanismus

**Automatisches Rollback:**
- Bei Installations-Fehlern
- Bestätigung durch Benutzer
- Wiederherstellung aller Dateien
- Berechtigungen werden restauriert

**Manuelles Rollback:**
- Liste verfügbarer Backups
- Selektive Wiederherstellung
- Integritäts-Prüfung
- Status-Berichte

## Fehlerbehandlung

### Download-Fehler

**Retry-Strategie:**
1. Curl-Versuch mit Timeout
2. Wget-Fallback bei Curl-Fehler
3. Mehrfache Wiederholung
4. Exponential-Backoff

**Fehler-Arten:**
- Netzwerk-Timeouts
- HTTP-Fehler (404, 500)
- Checksummen-Mismatch
- Unvollständige Downloads

### Installations-Fehler

**Backup-Wiederherstellung:**
- Automatisch bei kritischen Fehlern
- Benutzer-Bestätigung bei Rollback
- Vollständige Systemwiederherstellung
- Log-Protokollierung

**Partial-Updates:**
- Mit `--force` Flag möglich
- Warnung bei fehlgeschlagenen Dateien
- Fortsetzung bei unkritischen Fehlern
- Detaillierte Fehler-Berichte

## Logging und Monitoring

### Log-Level

**Standard-Logging:**
```bash
UPDATE_LOG_LEVEL="INFO"
UPDATE_LOG_FILE="${LOG_DIR}/update.log"
```

**Debug-Modus:**
```bash
UPDATE_DEBUG_MODE="true"
DEBUG_PRESERVE_TEMP_FILES="true"
```

### Status-Berichte

**Update-Statistiken:**
- Download-Zeiten
- Erfolgs-/Fehlerquoten
- Backup-Größen
- Netzwerk-Performance

**Monitoring-Integration:**
```bash
COLLECT_UPDATE_STATS="true"
STATS_FILE="${LOG_DIR}/update-stats.json"
```

## Best Practices

### Vor Updates

1. **System prüfen:**
   ```bash
   update --check
   ```

2. **Backup verifizieren:**
   - Ausreichend Speicherplatz
   - Backup-Verzeichnis zugänglich
   - Vorherige Backups funktional

3. **Netzwerk testen:**
   - Repository-Erreichbarkeit
   - Download-Geschwindigkeit
   - Firewall-Konfiguration

### Während Updates

1. **Monitoring:**
   - Log-Ausgaben verfolgen
   - Fehler-Meldungen beachten
   - System-Performance überwachen

2. **Bei Problemen:**
   - Updates mit `--force` fortsetzen
   - Partial-Updates akzeptieren
   - Rollback vorbereiten

### Nach Updates

1. **Validierung:**
   - Funktionalität testen
   - Konfiguration prüfen
   - Log-Dateien auswerten

2. **Cleanup:**
   - Alte Backups löschen
   - Temporäre Dateien entfernen
   - Statistiken archivieren

## Wartung

### Backup-Verwaltung

**Automatische Bereinigung:**
```bash
AUTO_CLEANUP_OLD_BACKUPS="true"
BACKUP_RETENTION_DAYS=30
```

**Manuelle Bereinigung:**
```bash
find ${BACKUP_DIR} -name "update-*" -mtime +30 -delete
```

### Repository-Wartung

**Manifest-Aktualisierung:**
1. Neue Dateien in Manifest aufnehmen
2. Checksummen generieren
3. Versionsnummern aktualisieren
4. Repository synchronisieren

**Checksummen generieren:**
```bash
find . -name "*.sh" -o -name "*.conf" | \
  xargs sha256sum > checksums.sha256
```

## Troubleshooting

### Häufige Probleme

**"Failed to download manifest"**
- Repository-URL prüfen
- Netzwerk-Verbindung testen
- Proxy-Einstellungen überprüfen
- DNS-Auflösung validieren

**"Checksum verification failed"**
- Erneuten Download versuchen
- Manifest-Integrität prüfen
- `--force` Flag verwenden
- Repository-Status überprüfen

**"Backup creation failed"**
- Speicherplatz überprüfen
- Berechtigungen validieren
- Verzeichnis-Struktur reparieren
- Disk-Errors untersuchen

### Debug-Modus

**Aktivierung:**
```bash
UPDATE_DEBUG_MODE="true"
DEBUG_PRESERVE_TEMP_FILES="true"
DEBUG_VERBOSE_CURL="true"
```

**Debug-Ausgabe:**
- Detaillierte Download-Logs
- Temporäre Dateien bleiben erhalten
- Ausführliche Fehler-Meldungen
- Netzwerk-Trace-Informationen

### Notfall-Recovery

**Bei Total-Ausfall:**
1. Letztes funktionales Backup identifizieren
2. Komplettes Rollback durchführen
3. System-Integrität validieren
4. Schritt-für-Schritt neu updaten

**Recovery-Kommandos:**
```bash
# Verfügbare Backups auflisten
update --rollback

# Rollback auf letztes Backup
update --rollback update-$(date +%Y%m%d -d "1 day ago")*

# System-Check nach Recovery
update --check
```

## Integration

### Cron-Jobs

**Automatische Update-Checks:**
```bash
# Täglich um 02:00 Uhr prüfen
0 2 * * * /opt/helper/utilities/update.sh --check

# Wöchentlich automatisch updaten
0 3 * * 0 /opt/helper/utilities/update.sh --install
```

### Monitoring-Integration

**Nagios/Icinga:**
```bash
#!/bin/bash
update --check >/dev/null 2>&1
case $? in
    0) echo "OK - Updates available" ; exit 0 ;;
    1) echo "OK - System up to date" ; exit 0 ;;
    *) echo "CRITICAL - Update check failed" ; exit 2 ;;
esac
```

### CI/CD-Pipeline

**Automatisierte Tests:**
```bash
# Test-Update im CI
update --download
update --install --force
./test-suite.sh
update --rollback latest
```

## Erweiterte Konfiguration

Alle Einstellungen sind in `configs/update.conf` konfigurierbar und durch lokale Überschreibung (`configs/update-local.conf`) anpassbar.

### Performance-Tuning

**Parallel-Downloads:**
```bash
PARALLEL_DOWNLOADS="true"
MAX_PARALLEL_JOBS=3
DOWNLOAD_QUEUE_SIZE=10
```

**Caching:**
```bash
CACHE_MANIFESTS="true"
CACHE_CHECKSUMS="true"
CACHE_DURATION="3600"
```

### Sicherheits-Optionen

**SSL-Validierung:**
```bash
VERIFY_SSL_CERTIFICATES="true"
REQUIRE_HTTPS="true"
ALLOW_INSECURE_DOWNLOADS="false"
```

**Sandbox-Modus:**
```bash
SANDBOX_UPDATES="false"
CHROOT_UPDATE_DIR=""
UPDATE_USER=""
```