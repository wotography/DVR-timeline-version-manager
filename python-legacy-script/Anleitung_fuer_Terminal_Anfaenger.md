# Anleitung für Terminal-AnfängerInnen: DaVinci Resolve Timeline Versionierung

Diese Anleitung hilft dir, das Timeline-Versionierungsskript für DaVinci Resolve mit dem Terminal zu nutzen – auch wenn du noch nie mit dem Terminal gearbeitet hast.

---

## Was ist das Terminal?
Das Terminal ist ein Programm, mit dem du deinem Computer direkt Befehle geben kannst. Es sieht aus wie ein schwarzes oder weißes Fenster mit Text. Keine Sorge: Mit dieser Anleitung kannst du nichts "kaputt machen"!

---

## Schritt 1: Terminal öffnen
**Mac:**
- Drücke `Cmd` + `Leertaste` (Spotlight-Suche)
- Tippe "Terminal" ein und drücke `Enter`

**Windows:**
- Drücke `Windows-Taste` + `R`, tippe `cmd` ein und drücke `Enter`

---

## Schritt 2: In den richtigen Ordner wechseln
Du musst dem Terminal sagen, in welchem Ordner das Skript liegt.

**Beispiel:**
Angenommen, das Skript liegt im Systemstandard Ordner `Downloads`:

**Mac:**
```
cd ~/Downloads/ResolveScript/DVR-timeline-version-increments
```
**Windows:**
```
cd %USERPROFILE%\Downloads\ResolveScript\DVR-timeline-version-increments
```

**Tipp:**
- Mit `cd` wechselst du den Ordner ("change directory").
- Mit `ls` (Mac) oder `dir` (Windows) kannst du dir die Dateien im aktuellen Ordner anzeigen lassen.

---

## Schritt 3: Python-Version prüfen
Gib ein:
```
python3 --version
```
Du solltest eine Zahl wie `Python 3.10.5` sehen. Ist die Version kleiner als 3.6, musst du Python aktualisieren (siehe Haupt-README).

---

## Schritt 4: Skript ausführen
Stelle sicher, dass DaVinci Resolve geöffnet ist und du ein Projekt mit ausgewählten Timelines hast.

Gib im Terminal ein (ersetze das Muster nach Wunsch):
```
python3 timeline_version_up.py "{version+1}_{current_date}"
```
- `{version+1}`: Erhöht die Versionsnummer automatisch
- `{current_date}`: Fügt das heutige Datum hinzu

**Beispiel:**
```
python3 timeline_version_up.py "{version+1}"
```

**Hinweis:**
- Während das Skript läuft, DaVinci Resolve nicht benutzen!
- Das Skript erstellt eine Logdatei mit allen Schritten im selben Ordner, diese kannst du mit dem Text Editor öffnen und nachvollziehen was das Skript gemacht hat.

---

## Schritt 5: Ergebnis prüfen
- Wechsle zurück zu DaVinci Resolve
- Schau im Media Pool nach den neuen Timeline-Versionen und Ordnern

---

## Häufige Fragen
- **Fehler: "command not found"?**
  - Prüfe, ob du `python3` richtig geschrieben hast.
- **Skript findet DaVinci Resolve nicht?**
  - Stelle sicher, dass Resolve läuft und Scripting aktiviert ist (siehe Haupt-README).
- **Ordner stimmt nicht?**
  - Mit `pwd` (Mac) oder `cd` (Windows) siehst du, wo du gerade bist.

---

## Nützliche Terminal-Befehle
- `cd ORDNERNAME` – In einen Ordner wechseln
- `ls` (Mac) / `dir` (Windows) – Dateien anzeigen
- `pwd` (Mac) – Zeigt den aktuellen Ordner an
- `exit` – Terminal schließen

---

Viel Erfolg! Bei Fragen hilft die Haupt-README oder du fragst jemanden, der sich mit dem Terminal auskennt. :) 