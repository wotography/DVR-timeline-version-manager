# DaVinci Resolve Timeline Version Updater

[![Python Version](https://img.shields.io/badge/python-3.6%2B-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![DaVinci Resolve](https://img.shields.io/badge/DaVinci%20Resolve-Studio-blueviolet.svg)](https://www.blackmagicdesign.com/products/davinciresolve)

A Python script for automatic version management of timelines in DaVinci Resolve Studio. This script enables renaming of timelines in the DaVinci Resolve Media Pool and automatically increments version numbers in timeline names.

## Features
- Automatic timeline versioning
- Flexible naming patterns with placeholders
- Support for various version formats
- Intelligent date handling (removes existing dates)
- Detailed logging for troubleshooting

## Prerequisites
- DaVinci Resolve Studio (with scripting enabled)
- Python 3.6 or higher
- DaVinciResolveScript module

## Installation

1. Ensure DaVinci Resolve Studio is installed with scripting enabled
2. Python 3.6 or higher must be installed
3. Copy the script to any folder
4. Ensure the DaVinciResolveScript module path is correctly configured

The script automatically searches for the DaVinciResolveScript module in standard paths:
- macOS: `/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules`
- Windows: `C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\Developer\Scripting\Modules`
- Linux: `/opt/resolve/Developer/Scripting/Modules`

## Usage
```bash
python3 timeline_version_up.py "NewNamePattern"
```

### Available Placeholders
- `{n}`         - Sequential number
- `{original}`  - Original timeline name
- `{current_date}` - Current date in YYYY-MM-DD format (removes any existing date)
- `{version}`   - Version number from original name (e.g., "v001")
- `{version+1}` - Increment version number by 1
- `{version-1}` - Decrement version number by 1

### Supported Date Formats
The script can detect and remove the following date formats from timeline names:
- YYYY-MM-DD (e.g., 2025-03-21)
- DD-MM-YYYY (e.g., 21-03-2025)
- MM-DD-YYYY (e.g., 03-21-2025)
- YYYY/MM/DD (e.g., 2025/03/21)
- DD/MM/YYYY (e.g., 21/03/2025)
- MM/DD/YYYY (e.g., 03/21/2025)

When using the `{current_date}` placeholder, the script will:
1. Remove any existing date in any of the supported formats
2. Add the current date in YYYY-MM-DD format
3. Clean up any resulting double underscores or spaces

### Examples
1. Increment version number and add current date:
   ```bash
   python3 timeline_version_up.py "{version+1}_{current_date}"
   ```
   Converts e.g., "Timeline_v001_2025-03-20" to "Timeline_v002_2025-03-21"
   Also works with other date formats:
   - "Timeline_v001_20-03-2025" → "Timeline_v002_2025-03-21"
   - "Timeline_v001_03/20/2025" → "Timeline_v002_2025-03-21"

2. Add sequence number and current date:
   ```bash
   python3 timeline_version_up.py "Scene_{n}_{current_date}"
   ```
   Creates e.g., "Scene_1_2025-03-21"

## How It Works
1. The script connects to DaVinci Resolve
2. Reads selected items from the Media Pool
3. For each selected item:
   - Checks if it's a timeline
   - Processes version operations (removes existing dates)
   - Replaces placeholders
   - Renames the timeline

## Error Handling
- All actions and errors are logged
- Detailed error messages are provided
- A summary of processed items is displayed at the end

## Logging
The script uses Python's logging system with the following levels:
- INFO: Normal operations and success messages
- WARNING: Non-critical issues
- ERROR: Processing errors
- CRITICAL: Severe errors (e.g., no connection to Resolve)

## Limitations
- Works only with timelines (other media types are skipped)
- Requires DaVinci Resolve Studio with scripting enabled
- Version numbers must be in format "v001", "V2", or "version1"
- Date formats must match one of the supported patterns

## Tips
- Test new naming patterns with a single item first
- Use logging output for troubleshooting
- Backup important timelines before renaming
- The script automatically removes existing dates when using {current_date}
- When using dates, stick to the supported formats for best results

## License
MIT License - See LICENSE file for details

## Contributing
Contributions are welcome! Please create a pull request or open an issue for suggestions.

## Known Issues
- Only works with DaVinci Resolve Studio (not the free version)
- Requires scripting to be enabled in DaVinci Resolve

## Support
For problems or questions:
1. Check the documentation
2. Search for similar issues
3. Create a new issue with detailed error description

## Changelog
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
