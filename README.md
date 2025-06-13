# DaVinci Resolve Timeline Version Updater

[![Python Version](https://img.shields.io/badge/python-3.6%2B-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![DaVinci Resolve](https://img.shields.io/badge/DaVinci%20Resolve-Studio-blueviolet.svg)](https://www.blackmagicdesign.com/products/davinciresolve)

A Python script for automatic version management of timelines in DaVinci Resolve Studio. This script enables renaming of timelines in the DaVinci Resolve Media Pool and automatically increments version numbers in timeline names.

## Features
- Automatic timeline versioning
- Flexible naming patterns with placeholders
- Support for various version formats
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
- `{date}`      - Current date in YYYY-MM-DD format
- `{version}`   - Version number from original name (e.g., "v001")
- `{version+1}` - Increment version number by 1
- `{version-1}` - Decrement version number by 1

### Examples
1. Increment version number:
   ```bash
   python3 timeline_version_up.py "{version+1}"
   ```
   Converts e.g., "Timeline_v001" to "Timeline_v002"

2. Add sequence number and date:
   ```bash
   python3 timeline_version_up.py "Scene_{n}_{date}"
   ```
   Creates e.g., "Scene_1_2024-03-20"

## How It Works
1. The script connects to DaVinci Resolve
2. Reads selected items from the Media Pool
3. For each selected item:
   - Checks if it's a timeline
   - Processes version operations
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

## Tips
- Test new naming patterns with a single item first
- Use logging output for troubleshooting
- Backup important timelines before renaming

## License
MIT License - See LICENSE file for details

## Contributing
Contributions are welcome! Please create a pull request or open an issue for suggestions.

## Known Issues
- Only works with DaVinci Resolve Studio (not the free version)
- Requires scripting to be enabled in DaVinci Resolve

## Changelog
### v1.0.0 (2024-03-20)
- Initial release
- Basic version management
- Placeholder system
- Logging integration

## Support
For problems or questions:
1. Check the documentation
2. Search for similar issues
3. Create a new issue with detailed error description
