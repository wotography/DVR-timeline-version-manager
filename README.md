# DaVinci Resolve Timeline Version Updater

[![Python Version](https://img.shields.io/badge/python-3.6%2B-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![DaVinci Resolve](https://img.shields.io/badge/DaVinci%20Resolve-Studio-blueviolet.svg)](https://www.blackmagicdesign.com/products/davinciresolve)

A Python script for automatic version management of timelines in DaVinci Resolve Studio. This script enables renaming of timelines in the DaVinci Resolve Media Pool and automatically increments version numbers in timeline names.

## Quick Start
1. [Install Python](#step-1-install-python)
2. [Enable Scripting in DaVinci Resolve](#step-2-enable-scripting-in-davinci-resolve)
3. [Run the Script](#step-4-run-the-script)

## Features
### Core Functionality
- Automatic timeline versioning and duplication
- Flexible naming patterns with placeholders
- Support for various version formats
- Intelligent date handling

### Organization
- Automatic version folder creation and management
- Recursive folder hierarchy navigation
- Maintains project folder structure

### Technical Features
- Advanced logging with rotation and file output
- Pattern validation and error checking
- Type-safe implementation with Python type hints
- Resource cleanup and proper error handling
- Detailed operation summaries

### System Integration
- Improved DaVinciResolveScript import handling
- Global module availability
- Enhanced error handling for imports

## Prerequisites
- DaVinci Resolve Studio (with scripting enabled)
- Python 3.6 or higher
- DaVinciResolveScript module

## Tested Systems
This script was tested on macOS 15.5 with DVR Studio version 19.1.4 BUILD 11.
Please report your system specs if you successfully run the script to help others verify compatibility.

## Installation

1. Ensure DaVinci Resolve Studio is installed with scripting enabled
2. Python 3.6 or higher must be installed
3. Copy the script to any folder
4. Ensure the DaVinciResolveScript module path is correctly configured

The script automatically searches for the DaVinciResolveScript module in standard paths:
- macOS: `/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules`
- Windows: `C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\Developer\Scripting\Modules`
- Linux: `/opt/resolve/Developer/Scripting/Modules`

## How to Use - Step by Step Guide

### Step 1: Install Python
#### On Mac:
1. Visit the official Python website: https://www.python.org/downloads/
2. Click the "Download Python" button (get the latest version, 3.6 or higher)
3. Open the downloaded .pkg installer
4. Follow the installation wizard:
   - Click "Continue" through the introduction
   - Accept the license agreement
   - Click "Install" (you may need to enter your password)
   - Wait for the installation to complete
5. Verify the installation by opening Terminal (you can find it using Spotlight search - press `Cmd + Space` and type "Terminal") and typing:
   ```bash
   python3 --version
   ```
   You should see the Python version number displayed

#### On Windows:
1. Visit the official Python website: https://www.python.org/downloads/
2. Click the "Download Python" button (get the latest version, 3.6 or higher)
3. Run the downloaded .exe installer
4. Important: Check the box that says "Add Python to PATH" during installation
5. Click "Install Now" and wait for the installation to complete
6. Verify the installation by opening Command Prompt (press `Windows + R`, type "cmd" and press Enter) and typing:
   ```bash
   python --version
   ```
   You should see the Python version number displayed

### Step 2: Enable Scripting in DaVinci Resolve
1. Open DaVinci Resolve Studio
2. Go to `DaVinci Resolve` > `Preferences` (on Mac) or `File` > `Preferences` (on Windows)
3. Click on `System` in the top
4. Select `General` in the sidebar menu
5. Set the dropdown for `External scripting using` to `Local` to enable scripting from your local Machine
6. Click `Save` and restart DaVinci Resolve

### Step 3: Prepare Your Project
1. Open your DaVinci Resolve project
2. In the Media Pool, select the timelines you want to version up or modify
3. Make sure you have a backup of your project

### Step 4: Run the Script
#### On Mac:
1. Open Terminal
2. Navigate to the folder containing the script using the `cd` command:
   ```bash
   cd /path/to/script/folder
   ```
3. Run the script with your desired naming pattern:
   ```bash
   python3 timeline_version_up.py "{version+1}_{current_date}"
   ```
4. Observe in Resolve whats happening. Don't use Resolve while the script is running.

#### On Windows:
1. Open Command Prompt
2. Navigate to the folder containing the script:
   ```bash
   cd C:\path\to\script\folder
   ```
3. Run the script with your desired naming pattern:
   ```bash
   python timeline_version_up.py "{version+1}_{current_date}"
   ```
4. Observe in Resolve whats happening. Don't use Resolve while the script is running.

### Step 5: Verify the Results
1. Return to DaVinci Resolve
2. Check the Media Pool for:
   - The new version of your timeline
   - The new version folder (if using {version+1})
   - The updated timeline name with the new version number and date

## Usage Guide

### Available Placeholders
- `{n}`         - Sequential number
- `{original}`  - Original timeline name
- `{current_date}` - Current date in YYYY-MM-DD format (removes any existing date)
- `{version+1}` - Increment version number by 1 and duplicate the timeline
- `{version-1}` - Decrement version number by 1

### Common Patterns to Try
1. Simple version increment:
   ```bash
   python3 timeline_version_up.py "{version+1}"
   ```

2. Add current date:
   ```bash
   python3 timeline_version_up.py "{current_date}"
   ```

3. Combine version and date:
   ```bash
   python3 timeline_version_up.py "{version+1}_{current_date}"
   ```

### Supported Date Formats
The script can detect and remove the following date formats from timeline names:
- YYYY-MM-DD (e.g., 2025-03-21)
- DD-MM-YYYY (e.g., 21-03-2025)
- MM-DD-YYYY (e.g., 03-21-2025)
- YYYY/MM/DD (e.g., 2025/03/21)
- DD/MM/YYYY (e.g., 21/03/2025)
- MM/DD/YYYY (e.g., 03/21/2025)

## Technical Details

### How It Works
1. The script connects to DaVinci Resolve
2. Validates the input pattern
3. Reads selected items from the Media Pool
4. For each selected item:
   - Checks if it's a timeline
   - Processes version operations (removes existing dates)
   - Replaces placeholders
   - Duplicates the timeline if needed
   - Creates a version folder at the same level
   - Moves the duplicated timeline to the version folder
5. Provides a detailed summary of operations

### Error Handling
- Specific exception handling for different error types
- Detailed error messages with context
- Proper resource cleanup in all cases
- Operation summaries with success/failure counts
- Pattern validation before processing
- Type checking and validation
- Detailed logging of folder operations
- Graceful handling of folder hierarchy navigation
- Improved import error handling
- Global module availability checks

### Logging System
- Console output for immediate feedback
- Rotating file logs (1MB size limit, 5 backup files)
- Different formatters for console and file output
- Multiple log levels:
  - INFO: Normal operations and success messages
  - WARNING: Non-critical issues
  - ERROR: Processing errors
  - CRITICAL: Severe errors (e.g., no connection to Resolve)
- Timestamp and context information in file logs
- Detailed folder operation logging
- Hierarchy navigation tracking
- Import status logging

## Troubleshooting
If you encounter any issues:
1. Check that DaVinci Resolve is running
2. Verify that scripting is enabled in preferences
3. Make sure you have selected a timeline in the Media Pool
4. Check the log file in the script's folder for detailed error messages

## Tips
- Test new naming patterns with a single item first
- Check the log file for detailed operation history
- Backup important timelines before renaming
- The script automatically removes existing dates when using {current_date}
- When using dates, stick to the supported formats for best results
- Monitor the log file for troubleshooting
- Check folder hierarchy in the log file if version folders aren't created as expected
- Ensure DaVinciResolveScript module is properly installed and accessible

## Limitations
- Works only with timelines (other media types are skipped)
- Requires DaVinci Resolve Studio with scripting enabled
- Version numbers must be in format "v001", "V2", or "version1"
- Date formats must match one of the supported patterns

## Support
For problems or questions:
1. Check the documentation
2. Search for similar issues
3. Create a new issue with detailed error description
4. Check the log file for detailed error information

## Donate
Thanks for using this script — I hope it helped with your work!  
If it saved you time or proved useful, consider donating a coffee.  
Your support helps keep the project going.

[![PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://www.paypal.com/donate/?hosted_button_id=QFD3FZ8V2RLY2)

## License
MIT License - See LICENSE file for details

## Contributing
Contributions are welcome! Please create a pull request or open an issue for suggestions.

## Roadmap
The following features are on the list to implement:
- Add current date to new created folders
- Add option for `version+1` without new folder creation
- Create new Timelines with Name Pattern and numbering

## Known Issues
- Only works with DaVinci Resolve Studio (not the free version)
- Requires scripting to be enabled in DaVinci Resolve

## Changelog
### v0.2.4 (2025-06-18)
- Replaced two characters for better compatibility
- Added python compatibilty checks
- Added UTF8 type encoding

### v0.2.3 (2025-06-14)
- Improved DaVinciResolveScript import handling
- Moved import to module level for global availability
- Enhanced error handling for imports
- Added import status logging
- Updated documentation with import instructions

### v0.2.2 (2025-06-14)
- Added recursive folder hierarchy navigation
- Improved version folder creation logic
- Enhanced folder operation logging
- Added detailed folder hierarchy tracking
- Fixed parent folder detection
- Improved error handling for folder operations

### v0.2.1 (2025-06-14)
- Added automatic version folder creation
- Added timeline movement to version folders
- Improved folder naming logic
- Enhanced error handling for folder operations
- Added folder management documentation

### v0.2.0 (2025-06-14)
- Added automatic timeline duplication with version+1
- Improved error handling for timeline operations
- Added type hints for timeline functions
- Enhanced logging for timeline operations
- Added pattern validation
- Improved error handling with specific exceptions
- Added rotating file logging
- Added type hints and improved documentation
- Added resource cleanup
- Added operation summaries

### v0.1.0 (2025-06-14)
- Added intelligent date handling
- Improved version processing
- Fixed name duplication issues
- Updated placeholder system
- Added support for multiple date formats
- Initial release
- Basic version management
- Placeholder system
- Logging integration
