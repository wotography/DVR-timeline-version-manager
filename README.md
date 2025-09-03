# DaVinci Resolve Timeline Version Manager

[![DaVinci Resolve](https://img.shields.io/badge/DaVinci%20Resolve-Studio-blueviolet.svg)](https://www.blackmagicdesign.com/products/davinciresolve)
[![PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://www.paypal.com/donate/?hosted_button_id=QFD3FZ8V2RLY2)
[![Download](https://img.shields.io/badge/Download-Script-green.svg)](https://github.com/wotography/DVR-timeline-version-manager/releases)

A toolkit for automatic version management and batch renaming of timelines in DaVinci Resolve Studio. Comes with a graphical interface (for use inside Resolve) and a legacy Python CLI script (for automated workflows).

![Screenshot](/images/DVR-timeline-version-manager.png?raw=false "Screenshot")

## Quick Start

### What it does
The Timeline Version Manager automates timeline versioning, naming, and organization in DaVinci Resolve Studio. It can:
- Increment version numbers in timeline names
- Add or replace dates in timeline names  
- Duplicate timelines with new names
- Organize timelines into folders based on version or date
- Reformat timeline names for consistency
- Rename existing timelines

### Quick Installation
1. Download [timeline_version_manager.lua](https://github.com/wotography/DVR-timeline-version-manager/releases)
2. Place it in your DaVinci Resolve scripts folder:
   - **macOS**: `/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Edit`
   - **Windows**: `C:\ProgramData\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Edit`
   - **Linux**: `/opt/resolve/Fusion/Scripts/Edit` or `/home/resolve/Fusion/Scripts/Edit`
3. Enable scripting in Resolve Preferences (Preferences > System > General > External scripting using "Local")
4. Run from **Workspace > Scripts** menu

### Quick Usage
1. Select timeline(s) in Media Pool
2. Run the script from **Workspace > Scripts**
3. Choose an operation mode (Duplicate, Duplicate + Move, or Rename only)
4. Configure version/date settings
5. Click "Run actions"

## 📖 Detailed Documentation

For comprehensive instructions, examples, and troubleshooting, see the **[User Documentation](User-documentation.md)**.

## Prerequisites
- **DaVinci Resolve Studio** (the free version does not support scripting)
- **Scripting enabled** in Resolve Preferences (Preferences > System > General > External scripting using: Local)
- **Operating System:** macOS, Windows, or Linux (where Resolve Studio is supported)

## Legacy Python Script

This repository also includes a **Legacy Python CLI Script** for advanced users and automation workflows.

> **Notice:** The Python script is no longer actively developed or maintained.

For more detailed Python script–specific instructions, see: [Python CLI Script Documentation](./python-legacy-script/README_py.md) (⚠️ legacy, not maintained).

## Donate
Thanks for using this script — I hope it helped with your work!  
If it saved you time or proved useful, please consider donating a coffee. Your support helps keep the project going.

[![PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://www.paypal.com/donate/?hosted_button_id=QFD3FZ8V2RLY2)

## ⚠️ Disclaimer

This tool is provided **as is** and **without any warranty** of any kind.  
By using this script, you acknowledge that **you do so at your own risk**.  
I do **not accept any responsibility or liability** for data loss, project corruption, or any other issues that may arise from its use.

It is **strongly recommended** to create backups of your DaVinci Resolve projects before running the script.

Use responsibly, and only if you understand what the script does and how it affects your project.

### Known Issues
I am continuously working to improve the plugin. If you encounter any issues not listed here, please report them by opening an Issue with as much detail as possible.

**Identified Issues**:
- none

Your feedback is invaluable. Please be patient as I work to resolve these issues and enhance the overall functionality of the plugin.

## Roadmap
### Planned Features
**Save Custom Default Settings**
- Add button to save and load custom default settings

**Enhanced Version Naming Options**
- Add new prefix options: "edit" or "Edit", "reel" or "Reel"
- Add letter-based versioning: "A" through "G"
- Example naming pattern: "edit A v1" or "Edit-B-v002"

**Visual Status Indicator**
- Add a color-coded status indicator in the GUI:
  - Orange: Ready to start
  - Red: Error occurred
  - Green: Successfully completed

**Split current date functions to add and/or replace dates.**

## Changelog
### v1.02 & v1.03 (2025-09-03)
- **New Features**:
  - New option to save logs to a file for easier review. Default path: "User/Documents/TimelineVersionManager/Logs". A custom path can be set.
- **Other**:
  - Improved log output: more detail and clearer messages for each operation, improved skipped-items logging, and a better final summary.
  - Bumped version number for simpler upgrade logic.
  - Fixed: The window only closed by clicking the "Close" button. Now it also closes when using the window close x.
### v0.1.12 (2025-08-31)
- **New Features**:
  - Added version format adjustment in rename mode: Automatically converts existing version formats to match the selected version format dropdown without changing the version number
  - Added date format adjustment in rename mode: Automatically converts existing date formats to match the selected date format dropdown without changing the actual date
  - Both format adjustments work independently of other checkbox settings when operation mode is set to "Rename"
- **Bug Fixes**:
  - Fixed date replacement logic: Dates now replace in their original position instead of being moved to the end
  - Improved log message clarity: "No changes needed" now shows "Skipping item" for better user feedback
- **UI Improvements**:
  - Reorganized UI layout: Moved operation mode selection to the main features section for better workflow
  - Renamed "Minus" to "Dash".
### v0.1.11 (2025-08-04)
- Fixed issue with Version+1 checkbox
### v0.1.10 (2025-08-01)
- Fixed version format handling
- Added dropdown for operation mode selection (Duplicate/Duplicate+Move/Rename only)
- Improved UI layout
### v0.1.9 (2025-07-28)
- Updated default settings
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