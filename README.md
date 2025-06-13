# DVR-timeline-version-increments
Script to increment timeline versions in DaVinci Resolve.

## Übersicht
Das Skript `timeline_version_up.py` ist ein Hilfswerkzeug für DaVinci Resolve, das die automatische Umbenennung von Timelines im Media Pool ermöglicht. Es unterstützt verschiedene Platzhalter und Muster für die Namensgebung und kann Versionsnummern automatisch inkrementieren.

## Voraussetzungen
- DaVinci Resolve Studio (mit aktiviertem Scripting)
- Python 3.x
- DaVinciResolveScript Modul

## Installation
1. Stellen Sie sicher, dass das Scripting in DaVinci Resolve aktiviert ist
2. Das Skript sucht automatisch nach dem DaVinciResolveScript Modul in den Standard-Pfaden:
   - macOS: `/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules`
   - Windows: `C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\Developer\Scripting\Modules`
   - Linux: `/opt/resolve/Developer/Scripting/Modules`

## Verwendung
```bash
python3 timeline_version_up.py "NeuerNameMuster"
```

### Verfügbare Platzhalter
- `{n}`         - Fortlaufende Nummer
- `{original}`  - Originaler Timeline-Name
- `{date}`      - Aktuelles Datum im Format YYYY-MM-DD
- `{version}`   - Versionsnummer aus dem Original-Namen (z.B. "v001")
- `{version+1}` - Versionsnummer um 1 erhöhen
- `{version-1}` - Versionsnummer um 1 verringern

### Beispiele
1. Versionsnummer erhöhen:
   ```bash
   python3 timeline_version_up.py "{version+1}"
   ```
   Wandelt z.B. "Timeline_v001" in "Timeline_v002" um

2. Sequenznummer und Datum hinzufügen:
   ```bash
   python3 timeline_version_up.py "Scene_{n}_{date}"
   ```
   Erzeugt z.B. "Scene_1_2024-03-20"

## Funktionsweise
1. Das Skript verbindet sich mit DaVinci Resolve
2. Es liest die ausgewählten Elemente im Media Pool
3. Für jedes ausgewählte Element:
   - Prüft, ob es sich um eine Timeline handelt
   - Verarbeitet die Versionsoperationen
   - Ersetzt die Platzhalter
   - Benennt die Timeline um

## Fehlerbehandlung
- Das Skript protokolliert alle Aktionen und Fehler
- Bei Problemen werden detaillierte Fehlermeldungen ausgegeben
- Eine Zusammenfassung der verarbeiteten Elemente wird am Ende angezeigt

## Logging
Das Skript verwendet das Python-Logging-System mit folgenden Log-Levels:
- INFO: Normale Operationen und Erfolgsmeldungen
- WARNING: Nicht-kritische Probleme
- ERROR: Fehler bei der Verarbeitung
- CRITICAL: Schwerwiegende Fehler (z.B. keine Verbindung zu Resolve)

## Einschränkungen
- Funktioniert nur mit Timelines (andere Medientypen werden übersprungen)
- Erfordert DaVinci Resolve Studio mit aktiviertem Scripting
- Versionsnummern müssen im Format "v001", "V2" oder "version1" vorliegen

## Tipps
- Testen Sie neue Namensmuster zunächst mit einem einzelnen Element
- Verwenden Sie die Logging-Ausgaben zur Fehlersuche
- Sichern Sie wichtige Timelines vor der Umbenennung
