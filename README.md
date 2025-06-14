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
- Advanced logging with rotation and file output
- Pattern validation and error checking
- Type-safe implementation with Python type hints
- Resource cleanup and proper error handling
- Detailed operation summaries
- Automatic timeline duplication with version+1

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
- `{version+1}` - Increment version number by 1 and duplicate the timeline
- `{version-1}` - Decrement version number by 1

### Pattern Validation
The script validates patterns before processing:
- Checks for required placeholders
- Validates balanced braces
- Verifies placeholder names
- Ensures proper pattern syntax

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

### Timeline Duplication
When using the `{version+1}` placeholder, the script will:
1. Create a duplicate of the selected timeline
2. Rename the duplicate with the incremented version number
3. Keep the original timeline unchanged

This is useful for:
- Creating new versions while preserving the original
- Maintaining a version history
- Working on multiple versions simultaneously

### Examples
1. Increment version number, duplicate timeline, and add current date:
   ```bash
   python3 timeline_version_up.py "{version+1}_{current_date}"
   ```
   Creates a duplicate timeline with incremented version number and current date:
   - Original: "Timeline_v001_2025-03-20"
   - New: "Timeline_v002_2025-03-21"

2. Simple version increment with duplication:
   ```bash
   python3 timeline_version_up.py "{version+1}"
   ```
   Creates a duplicate timeline with incremented version number:
   - Original: "Timeline_v001"
   - New: "Timeline_v002"

## How It Works
1. The script connects to DaVinci Resolve
2. Validates the input pattern
3. Reads selected items from the Media Pool
4. For each selected item:
   - Checks if it's a timeline
   - Processes version operations (removes existing dates)
   - Replaces placeholders
   - Renames the timeline
5. Provides a detailed summary of operations

## Error Handling
- Specific exception handling for different error types
- Detailed error messages with context
- Proper resource cleanup in all cases
- Operation summaries with success/failure counts
- Pattern validation before processing
- Type checking and validation

## Logging
The script uses an advanced logging system with:
- Console output for immediate feedback
- Rotating file logs (1MB size limit, 5 backup files)
- Different formatters for console and file output
- Multiple log levels:
  - INFO: Normal operations and success messages
  - WARNING: Non-critical issues
  - ERROR: Processing errors
  - CRITICAL: Severe errors (e.g., no connection to Resolve)
- Timestamp and context information in file logs

## Limitations
- Works only with timelines (other media types are skipped)
- Requires DaVinci Resolve Studio with scripting enabled
- Version numbers must be in format "v001", "V2", or "version1"
- Date formats must match one of the supported patterns

## Tips
- Test new naming patterns with a single item first
- Check the log file for detailed operation history
- Backup important timelines before renaming
- The script automatically removes existing dates when using {current_date}
- When using dates, stick to the supported formats for best results
- Monitor the log file for troubleshooting

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
4. Check the log file for detailed error information

## Changelog
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
