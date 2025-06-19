# DaVinci Resolve Timeline Version Updater

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![DaVinci Resolve](https://img.shields.io/badge/DaVinci%20Resolve-Studio-blueviolet.svg)](https://www.blackmagicdesign.com/products/davinciresolve)

A toolkit for automatic version management and batch renaming of timelines in DaVinci Resolve Studio. Supports both a graphical Lua GUI script (for use inside Resolve) and a legacy Python CLI script (for automated workflows).

---

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Features](#features)
- [Troubleshooting](#troubleshooting)
- [Changelog](#changelog)
- [License](#license)

---

## Instructions for Python legacy CLI version
For more detailed python script-specific instructions see: [Python CLI Script Documentation](./python-legacy-script/README_py.md) (⚠️ legacy, not maintained).

---

## Overview
This repository provides two powerful tools for managing timeline versions in DaVinci Resolve Studio:

- **Lua GUI Script**: A graphical tool for batch versioning, renaming, and organizing timelines directly inside DaVinci Resolve Studio.
- **Python CLI Script**: A command-line tool for advanced users, automation, and scripting outside of Resolve.

Both tools support flexible version/date formats, automatic folder creation, and a range of customization options.

> **Notice:** The Python script is no longer actively developed or maintained. For new projects and ongoing support, please use the Lua GUI script (`timeline_version_up.lua`).

---

## Prerequisites
- **DaVinci Resolve Studio** (the free version does not support scripting)
- **Scripting enabled** in Resolve Preferences (Preferences > System > General > External scripting using: Local)
- **Operating System:** macOS, Windows, or Linux (where Resolve Studio is supported)
- For Python script: **Python 3.6+** and the `DaVinciResolveScript` module which usually comes with Resolve.

---

## Donate
Thanks for using this script — I hope it helped with your work!  
If it saved you time or proved useful, consider donating a coffee.  
Your support helps keep the project going.

[![PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://www.paypal.com/donate/?hosted_button_id=QFD3FZ8V2RLY2)

---

## Installation

### Lua GUI Script
1. Download or copy [timeline_version_up.lua](https://raw.githubusercontent.com/wotography/DVR-timeline-version-increments/main/timeline_version_up.lua).
2. Place the file inside the Scripting Paths:
   - **macOS**:
     ```
     /Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Edit
     ```
   - **Windows**:
     ```
     C:\ProgramData\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Edit
     ```
   - **Linux**:
     ```
     /opt/resolve/Fusion/Scripts/Edit
     ```
     or
     ```
     /home/resolve/Fusion/Scripts/Edit
     ```
     depending on installation
3. In DaVinci Resolve, open your project.
4. The script will now appear in the **Workspace > Scripts** menu. You can also run it from the **Console** or **Script Editor** inside Resolve.

---

## Usage

### Lua GUI Script
1. **Open DaVinci Resolve Studio** and load your project.
2. In the **Media Pool**, select one or more timelines you want to version up or rename.
3. Go to **Workspace > Scripts** and run `timeline_version_up.lua`.
4. The GUI will appear with options for versioning, date formatting, folder creation, and more.
5. Adjust the settings as needed:
   - **Version +1:** Increment version number in timeline names.
   - **Add/replace date:** Add or update the date in timeline names.
   - **Append version if missing:** Add a version if none is present.
   - **Create and move to new folders:** Duplicate timelines and move them to new folders based on your chosen scheme.
   - **Name formatting:** Choose between spaces, underscores, or minuses.
   - **Version and date formats:** Select from a wide range of formats.
6. Click **Start renaming** to process the selected timelines. Progress and results will be shown in the log area.
7. Review the Media Pool for new/renamed timelines and folders.

---

## Features
- **Graphical User Interface (Lua)**: Easy-to-use controls for all options.
- **Batch Processing**: Rename and version multiple timelines at once.
- **Flexible Version Formats**: Supports v1, v01, v001, V1, V01, V001, version1, version01, version001, Version1, Version01, Version001.
- **Flexible Date Formats**: YYMMDD, YYYYMMDD, YYYY-MM-DD, MM-DD-YYYY, DD-MM-YYYY.
- **Automatic Folder Creation**: Move new timelines to folders named by version, date, or both ("Version + Date").
- **Custom Name Formatting**: Convert spaces to underscores, minuses, or keep as-is.
- **Comprehensive Logging**: See a summary and detailed log of all actions (GUI or log file).

---

## Troubleshooting
- **Script not visible in menu?** Make sure the right script folder.
- **No timelines processed?** Check the Console or the Log Messages. Probably you forgot to select timelines in the Media Pool before running the script.
- **No GUI appears?** Ensure you are running the Lua script from within DaVinci Resolve Studio, not the free version.
- **Errors about scripting API?** Check that scripting is enabled in Resolve Preferences.
- **Still having issues?** Open an Issue, add as much information as possible.

---

## Changelog

### Lua Script
#### v0.1.1 (2024-06-19)
- Added support for version formats: Version1, Version01, Version001
- Improved folder creation logic for "Version + Date" mode
- Bugfixes and usability improvements

#### v0.1.0
- Initial release: GUI for timeline versioning, date formatting, folder creation, and batch renaming

---

## License
MIT License - See LICENSE file for details 
 