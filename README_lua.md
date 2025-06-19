# DaVinci Resolve Timeline Version Updater (Lua GUI)

> **Recommended:** This is the actively maintained and recommended version for timeline versioning in DaVinci Resolve Studio. Use this Lua GUI script for the best experience and ongoing support.

## What is this?
This script adds a graphical user interface (GUI) to DaVinci Resolve Studio for batch versioning, renaming, and organizing timelines in the Media Pool. It is designed for editors who want a fast, safe, and flexible way to manage timeline versions—no coding required!

## Prerequisites
- **DaVinci Resolve Studio** (the free version does not support scripting)
- **Scripting enabled** in Resolve Preferences (Preferences > System > General > External scripting using: Local)
- **Operating System:** macOS, Windows, or Linux (where Resolve Studio is supported)

## Installation
1. Download or copy `timeline_version_up.lua`.
2. Place the file inside the Scripting Paths:
MacOS: '/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Edit'
Windows: 'C:\ProgramData\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Edit'
Linux: '/opt/resolve/Fusion/Scripts/Edit/' or '/home/resolve/Fusion/Scripts/Edit' depending on installation
3. In DaVinci Resolve, open your project.
4. The script will now appear in the **Workspace > Scripts** menu. You can also run it from the **Console** or **Script Editor** inside Resolve.

## How to Use (Step-by-Step)
1. **Open DaVinci Resolve Studio** and load your project.
2. In the **Media Pool**, select one or more timelines you want to version up or rename.
3. Go to **Workspace > Scripts** and run `timeline_version_up.lua`.
4. The GUI will appear with options for versioning, date formatting, folder creation, and more.
5. Adjust the settings as needed:
   - **Version +1:** Increment the version number in timeline names.
   - **Add/replace date:** Add or update the date in timeline names.
   - **Append version if missing:** Add a version if none is present.
   - **Create and move to new folders:** Duplicate timelines and move them to new folders based on your chosen scheme.
   - **Name formatting:** Choose between spaces, underscores, or minuses.
   - **Version and date formats:** Select from a wide range of formats.
6. Click **Start renaming** to process the selected timelines. Progress and results will be shown in the log area.
7. Review the Media Pool for new/renamed timelines and folders.

## Features
- **Easy-to-use GUI**: No scripting knowledge required.
- **Batch Processing**: Rename and version multiple timelines at once.
- **Flexible Version Formats**: v1, v01, v001, V1, V01, V001, version1, version01, version001, Version1, Version01, Version001.
- **Flexible Date Formats**: YYMMDD, YYYYMMDD, YYYY-MM-DD, MM-DD-YYYY, DD-MM-YYYY.
- **Automatic Folder Creation**: Move new timelines to folders named by version, date, or both ("Version + Date").
- **Custom Name Formatting**: Convert spaces to underscores, minuses, or keep as-is.
- **Comprehensive Logging**: See a summary and detailed log of all actions in the GUI.

## Troubleshooting
- **Script not visible in menu?** Make sure the script folder is added in Workspace > Scripts > Add Script Location.
- **No timelines processed?** Select timelines in the Media Pool before running the script.
- **No GUI appears?** Ensure you are running the script from within DaVinci Resolve Studio, not the free version.
- **Errors about scripting API?** Check that scripting is enabled in Resolve Preferences.
- **Still having issues?** Try restarting Resolve and ensure you are using the latest Studio version.

## Changelog Lua Script
### v0.1.1 (2024-06-19)
- Added support for version formats: Version1, Version01, Version001
- Improved folder creation logic for "Version + Date" mode
- Bugfixes and usability improvements

### v0.1.0
- Initial release: GUI for timeline versioning, date formatting, folder creation, and batch renaming 