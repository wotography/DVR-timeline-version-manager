# DaVinci Resolve Timeline Version Manager

[![DaVinci Resolve](https://img.shields.io/badge/DaVinci%20Resolve-Studio-blueviolet.svg)](https://www.blackmagicdesign.com/products/davinciresolve)
[![PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://www.paypal.com/donate/?hosted_button_id=QFD3FZ8V2RLY2)

A toolkit for automatic version management and batch renaming of timelines in DaVinci Resolve Studio. Comes with a graphical GUI (for use inside Resolve) and a legacy Python CLI script (for automated workflows).

![Screenshot](/images/DVR-timeline-version-manager.png?raw=true "Screenshot")

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Donate](#donate)
- [Installation](#installation)
- [Features](#features)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Changelog](#changelog)
- [License](#license)

## Overview
This repository provides a powerful tools for managing timeline versions in DaVinci Resolve Studio:

- **Lua GUI Script**: A graphical tool for batch versioning, renaming, and organizing timelines directly inside DaVinci Resolve Studio. It supports flexible version/date formats, automatic folder creation, and a range of customization options.

- **Legacy Python CLI Script**: A command-line tool for advanced users, automation, and scripting outside of Resolve.

> **Notice:** The Python script is no longer actively developed or maintained. Please use the GUI Plugin (`timeline_version_manager.lua`).

For more detailed python script-specific instructions see: [Python CLI Script Documentation](./python-legacy-script/README_py.md) (⚠️ legacy, not maintained).

## Prerequisites
- **DaVinci Resolve Studio** (the free version does not support scripting)
- **Scripting enabled** in Resolve Preferences (Preferences > System > General > External scripting using: Local)
- **Operating System:** macOS, Windows, or Linux (where Resolve Studio is supported)

## Donate
Thanks for using this script — I hope it helped with your work!  
If it saved you time or proved useful, please consider donating a coffee. Your support helps keep the project going.

[![PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://www.paypal.com/donate/?hosted_button_id=QFD3FZ8V2RLY2)

## Installation
### ⚠️ Disclaimer

This tool is provided **as is** and **without any warranty** of any kind.  
By using this script, you acknowledge that **you do so at your own risk**.  
I do **not accept any responsibility or liability** for data loss, project corruption, or any other issues that may arise from its use.

It is **strongly recommended** to create backups of your DaVinci Resolve projects before running the script.

Use responsibly, and only if you understand what the script does and how it affects your project.

### Lua GUI Script
1. Download the tool here: [timeline_version_manager.lua](https://raw.githubusercontent.com/wotography/DVR-timeline-version-manager/main/timeline_version_manager.lua) or check the latest release.
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
3. In DaVinci Resolve, open your project, **enable scripting** in Resolve Preferences (Preferences > System > General > External scripting using: Local)
4. The script will now appear in the **Workspace > Scripts** menu. You can also run it from the **Console** or **Script Editor** or assign a shortcut key to open the plugin inside Resolve.

## Features
- **Graphical User Interface (Lua)**: Easy-to-use controls for all options.
- **Batch Processing**: Rename and version multiple timelines at once.
- **Flexible Version Formats**: Supports v1, v01, v001, V1, V01, V001, version1, version01, version001, Version1, Version01, Version001.
- **Flexible Date Formats**: YYMMDD, YYYYMMDD, YYYY-MM-DD, MM-DD-YYYY, DD-MM-YYYY.
- **Automatic Folder Creation**: Move new timelines to folders named by version, date or version + date.
- **Custom Name Formatting**: Convert spaces to underscores, hyphens, or keep as-is.
- **Comprehensive Logging**: See a summary and detailed log of all actions (GUI or console).

## Usage
### Lua GUI Script
1. **Open DaVinci Resolve Studio** and load your project.
2. In the **Media Pool**, select one or more timelines you want to operate.
3. Go to **Workspace > Scripts** and run `timeline_version_manager.lua`.
4. The GUI will appear with options for versioning, date formatting, folder creation, and more.
5. Adjust the settings as needed:
   - **Version +1:** Increment version number in timeline names.
   - **Add/replace date:** Add or update the date in timeline names.
   - **Version and date formats:** Select from a wide range of formats.
   - **Append version if missing:** Add a version number if none is present.
   - **Operation Mode:** Duplicate only, rename or duplicate and move timelines to new folders based on your chosen folder naming scheme.
   - **Name formatting:** Choose between spaces, underscores, or hyphens.
6. Click **Run actions** to process the selected timelines. Progress and results will be shown in the log area or console.
7. Review the Media Pool for new/renamed timelines and folders.

## Troubleshooting
Always check the console log for errors first. Commen solutions and issues are:
- **Script Visibility**: Some users may experience issues with scripts not appearing in the menu. Ensure that the correct script folder is selected.
- **Plugin does not open**: The GUI may not appear if the script is run from the free version of DaVinci Resolve. Use DaVinci Resolve Studio instead. Make sure you are using the correct version.
- **Timeline Processing**: If no timelines are processed, check the Console or Log Messages for errors. This issue often occurs if timelines are not selected in the Media Pool before running the script.
- **Scripting API Errors**: Errors related to the scripting API can usually be resolved by ensuring that scripting is enabled in the Resolve Preferences.

### Known Issues
I am continuously working to improve the plugin. If you encounter any issues not listed here, please report them by opening an Issue with as much detail as possible.

**Identified Issues**: None

Your feedback is invaluable, please be patient as I work to resolve these issues and enhance the overall functionality of the plugin.

## Roadmap
### Planned Features
1. **Save Custom Default Settings**
   - Add button to save and load custom default settings
2. **Enhanced Version Naming Options**
   - Add new prefix options: "edit" or "Edit", "reel" or "Reel"
   - Add letter-based versioning: "A" through "G"
   - Example naming pattern: "edit A v1" or "Edit-B-v002"
3. **Visual Status Indicator**
   - Add a color-coded status indicator in the GUI:
     - Orange: Ready to start
     - Red: Error occurred
     - Green: Successfully completed
4. **Split current date functions to add and or replace dates.**

## Changelog
### v0.1.10 (2025-08-01)
- Fixed version format handling
- Added dropdown for operation mode selection (Duplicate/Duplicate+Move/Rename)
- Improved UI layout
### v0.1.9 (2025-07-28)
- updated default settings
### v0.1.8 (2025-06-20)
- **Refactoring & Performance**:
  - Major code refactoring for improved readability and maintainability.
  - Replaced complex `if/else` logic with more efficient table-driven approaches for better performance.
- **Bug Fixes**:
  - Fixed a critical bug where folder names were not created correctly when using the "Version + Date" naming scheme with certain name formatting options. The date format is now preserved.
  - Corrected an issue where timeline name formatting (e.g., converting separators to spaces) would incorrectly alter the date format within the timeline name itself.
  - Resolved an issue with the execution timer reporting incorrect durations. It now accurately measures real-world time.
- **Features**:
  - Added an execution timer to the log to show how long the script took to process the timelines.
### v0.1.1 (2024-06-19)
- Added support for version formats: Version1, Version01, Version001
- Improved folder creation logic for "Version + Date" mode
- Bugfixes and usability improvements
### v0.1.0
- Initial release: GUI for timeline versioning, date formatting, folder creation, and batch renaming

## License
GNU GPL 3 License - See LICENSE file for details