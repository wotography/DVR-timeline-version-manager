# DaVinci Resolve Timeline Version Manager

**Version:** v1.03 (2025-09-03)

A powerful Lua script for DaVinci Resolve that automates timeline versioning, naming, and organization. This tool helps editors maintain clean, organized project structures by automatically handling version increments, date stamps, and folder organization.

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Features](#features)
4. [User Interface](#user-interface)
5. [Usage Guide](#usage-guide)
6. [Examples](#examples)
7. [Troubleshooting](#troubleshooting)
8. [Technical Details](#technical-details)

## Overview

The Timeline Version Manager is designed to streamline the workflow of video editors who need to maintain multiple versions of their timelines. It can automatically:

- Increment version numbers in timeline names
- Add or replace dates in timeline names
- Duplicate timelines with new names
- Organize timelines into folders based on version or date
- Reformat timeline names for consistency
- Rename existing timelines

## Installation

### Prerequisites
- DaVinci Resolve (Studio version)
- Basic knowledge of DaVinci Resolve's Media Pool

### Installation Steps

1. **Download the Script**
   - Save `timeline_version_manager.lua` to your computer

2. **Access DaVinci Resolve Scripts**
   - Open DaVinci Resolve Studio
   - Go to **Workspace** → **Scripts** → **Open Scripts Folder**
   - This opens the scripts directory in your file explorer

3. **Install the Script**
   - Copy `timeline_version_manager.lua` to the scripts folder

4. **Run the Script**
   - In DaVinci Resolve, go to **Workspace** → **Scripts**
   - Find "timeline_version_manager" in the list
   - Click to run the script

## Features

### Main Features

#### 1. Operation Modes
- **Duplicate**: Creates a copy of the selected timeline with a new name
- **Duplicate + Move**: Creates a copy and moves it to a new folder
- **Rename only**: Renames the existing timeline (no duplication)

#### 2. Version Management
- **Version +1**: Automatically increments existing version numbers
- **Append version if missing**: Adds a version number to timelines without one
- **Multiple version formats**: Supports various version naming conventions

#### 3. Date Management
- **Add or replace current date**: Inserts today's date into timeline names
- **Multiple date formats**: Supports various date formats (YYYY-MM-DD, YYMMDD, etc.)
- **Smart date positioning**: Places dates in logical positions within names

#### 4. Name Formatting
- **Space formatting**: Converts underscores and dashes to spaces
- **Underscore formatting**: Converts spaces and dashes to underscores
- **Dash formatting**: Converts spaces and underscores to dashes

#### 5. Folder Organization
- **Version-based folders**: Creates folders named after version numbers
- **Date-based folders**: Creates folders named after dates
- **Combined folders**: Creates folders with both version and date

## User Interface

The script provides a clean, intuitive GUI with the following sections:

### Main Features Section
- **Operation Mode**: Choose between Duplicate, Duplicate + Move, or Rename
- **Version +1**: Checkbox to enable automatic version incrementing
- **Version Format**: Dropdown to select version naming convention
- **Add or replace with current date**: Checkbox to enable date management
- **Date Format**: Dropdown to select date format

### Settings Section
- **Folder Naming**: Choose folder naming scheme (when using Duplicate + Move)
- **Append version number if missing**: Checkbox to add version numbers to timelines without them
- **Version number**: Input field for the version number to append
- **Reformat name**: Checkbox to enable name formatting
- **Format options**: Dropdown to select formatting style

### Control Buttons
- **Run actions**: Executes the selected operations
- **Close**: Closes the script window

### Log Section
- **Real-time feedback**: Shows detailed information about each operation
- **Error reporting**: Displays any issues encountered during processing
- **Summary statistics**: Shows final results (processed, renamed, skipped, errors)
- **Save log to file**: Saves the log the a *.txt file to the user home folder > Documents/TimelineVersionManager/Logs. It lets you set a custom path, which are stored until the window is closed.

## Usage Guide

### Basic Workflow

1. **Prepare Your Project**
   - Open your DaVinci Resolve project
   - Navigate to the Media Pool
   - Select the timeline(s) you want to process

2. **Configure Settings**
   - Run the Timeline Version Manager script
   - Choose your desired operation mode
   - Configure version and date settings
   - Set up folder organization (if needed)

3. **Execute Operations**
   - Click "Run actions" to process your timelines
   - Monitor the log for real-time feedback
   - Review the results in your Media Pool

### Detailed Settings Explanation

#### Operation Mode

**Duplicate**
- Creates a copy of each selected timeline
- Original timeline remains unchanged
- New timeline gets the processed name
- Best for creating backup versions

**Duplicate + Move**
- Creates a copy of each selected timeline
- Moves the new timeline to a custom folder
- Folder is created based on your naming scheme
- Best for organizing versions by date or version number

**Rename only**
- Renames the existing timeline directly
- No duplication occurs
- Use with caution as this modifies the original
- Best for cleaning up existing timeline names

#### Version Management

**Version +1**
- Automatically finds existing version numbers in timeline names
- Increments them by 1
- Supports formats like: v1, v01, v001, V1, version1, Version1
- Example: "Timeline v1" → "Timeline v2"

**Version Format Options**
- `v1`, `v01`, `v001`: Lowercase 'v' with various digit padding
- `V1`, `V01`, `V001`: Uppercase 'V' with various digit padding
- `version1`, `version01`, `version001`: Full "version" prefix
- `Version1`, `Version01`, `Version001`: Capitalized "Version" prefix

**Append version if missing**
- Adds a version number to timelines that don't have one
- Uses the version number specified in the input field
- Example: "Timeline" → "Timeline v1" (if version number is set to 1)

#### Date Management

**Add or replace with current date**
- Inserts today's date into timeline names
- Replaces existing dates if found
- Places dates in same positions of original dates, or at the end if no date found

**Date Format Options**
- `YYMMDD`: Two-digit year, month, day (e.g., 250831)
- `YYYYMMDD`: Four-digit year, month, day (e.g., 20250831)
- `YYYY-MM-DD`: ISO format (e.g., 2025-08-31)
- `MM-DD-YYYY`: US format (e.g., 08-31-2025)
- `DD-MM-YYYY`: European format (e.g., 31-08-2025)

#### Folder Organization

**How it works**
- Only applies when "Duplicate + Move" is selected
- Creates folders in the parent directory of the original timeline
- Moves the new timeline to the created folder
- Uses existing folders if they already exist

**Folder Naming Schemes**
- **Version + Date**: Creates folders like "v1_2025-08-31", "V01_250831", "version001_31-08-2025", etc.
- **Version**: Creates folders like "v1", "V01", "version0001", etc.
- **Date**: Creates folders like "2025-08-31", "20250831", "31-08-2025", etc.

#### Name Formatting

**Reformat name**
- Cleans up timeline names for consistency
- Preserves dates and version numbers during formatting
- Applies the selected formatting style to the rest of the name

**Format Options**
- **Space**: Converts underscores and dashes to spaces
- **Underscore _**: Converts spaces and dashes to underscores
- **Dash -**: Converts spaces and underscores to dashes

## Examples

### Example 1: Basic Version Increment
**Input:** Timeline named "Project v1"
**Settings:**
- Operation Mode: Duplicate
- Version +1: ✓
- Version Format: v1
- Other settings: Default

**Result:** New timeline named "Project v2"

### Example 2: Version with Date
**Input:** Timeline named "Commercial Edit"
**Settings:**
- Operation Mode: Duplicate + Move
- Version +1: ✓
- Version Format: v01
- Add date: ✓
- Date Format: YYYY-MM-DD
- Folder Naming: Version + Date

**Result:** 
- New timeline named "Commercial Edit v01 2025-08-31"
- Moved to folder "v01_2025-08-31"

### Example 3: Clean Up Existing Names
**Input:** Timeline named "Project_v1_rough_cut_2025-08-31"
**Settings:**
- Operation Mode: Rename
- Version +1: ✓
- Version Format: v2
- Add date: ✓
- Date Format: YYYY-MM-DD
- Reformat name: ✓
- Format: Space

**Result:** Timeline renamed to "Project v2 rough cut 2025-08-31"

### Example 4: Add Version to Unversioned Timeline
**Input:** Timeline named "Final Edit"
**Settings:**
- Operation Mode: Duplicate
- Version +1: ✗
- Append version if missing: ✓
- Version number: 1
- Version Format: v1

**Result:** New timeline named "Final Edit v1"

## Troubleshooting

### Common Issues

**Script won't run**
- Ensure you're running the script from within DaVinci Resolve
- Check that the script file is in the correct scripts folder
- Restart DaVinci Resolve if needed

**No timelines processed**
- Make sure you have selected timeline(s) in the Media Pool
- Verify that the selected items are actually timelines (not clips or folders)
- Check the log for specific error messages

**Version numbers not incrementing**
- Ensure the timeline name contains a recognizable version pattern
- Check that "Version +1" is enabled
- Verify the version format matches your timeline naming convention

**Folders not created**
- Ensure "Duplicate + Move" is selected as the operation mode
- Check that at least one naming change is enabled (version, date, or append)
- Verify that the folder naming scheme is selected

**Date not appearing**
- Ensure "Add or replace with current date" is enabled
- Check that the date format is selected
- Verify the timeline name doesn't already contain a date in the same format

### Error Messages

**"No project open"**
- Open a DaVinci Resolve project before running the script

**"No timelines selected"**
- Select one or more timelines in the Media Pool before running the script

**"Could not find timeline object"**
- The timeline may have been moved or deleted after selection
- Try selecting the timeline again and re-running the script

**"Failed to duplicate/rename"**
- The timeline may be locked or in use
- Try closing any timelines that are currently open in the timeline viewer
- Check if you have sufficient permissions for the project
- Check if the same name already exists

## Technical Details

### Supported Version Patterns
The script recognizes these version patterns in timeline names:
- `v1`, `v01`, `v001`, `v10`, etc.
- `V1`, `V01`, `V001`, `V10`, etc.
- `version1`, `version01`, `version001`, etc.
- `Version1`, `Version01`, `Version001`, etc.

### Supported Date Patterns
The script recognizes these date patterns:
- `YYYY-MM-DD` (e.g., 2025-08-31)
- `YYYYMMDD` (e.g., 20250831)
- `YYMMDD` (e.g., 250831)
- `DD-MM-YYYY` (e.g., 31-08-2025)
- `MM-DD-YYYY` (e.g., 08-31-2025)

### Processing Order
1. Version increment (if enabled)
2. Date addition/replacement (if enabled)
3. Name formatting (if enabled)
4. Timeline duplication/renaming
5. Folder creation and moving (if enabled)

### Performance Considerations
- The script processes timelines sequentially
- Large numbers of timelines may take several seconds to process
- The log provides real-time feedback during processing
- Processing time is displayed at the end

### Compatibility
- **DaVinci Resolve Studio Version**: 17 and later
- **Operating Systems**: Windows, macOS, Linux
- **Script Language**: Lua
- **Dependencies**: DaVinci Resolve Studio Scripting API

## Support and Feedback

For issues, questions, or feature requests:
1. Check the troubleshooting section above
2. Review the log output for specific error messages
3. Ensure you're using the latest version of the script
4. Test with a simple example before processing important timelines

---

**Note:** Always backup your project before running scripts that modify timeline names or create duplicates. While this script is designed to be safe, it's good practice to have a backup of your work.
