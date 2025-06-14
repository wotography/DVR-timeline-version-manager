# VERSION: v0.2.0 (2025-06-14)

import sys
import os
import logging
import re
from datetime import datetime
from logging.handlers import RotatingFileHandler
from typing import Optional, List, Dict, Any

# --- Logging Configuration ---
def setup_logging(log_file: Optional[str] = None) -> None:
    """Sets up logging configuration with both console and file handlers.
    
    Args:
        log_file: Optional path to log file. If None, only console logging is used.
    """
    # Create formatters
    console_formatter = logging.Formatter("%(levelname)s: %(message)s")
    file_formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    
    # Setup root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
    
    # Clear any existing handlers
    root_logger.handlers = []
    
    # Add console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(console_formatter)
    root_logger.addHandler(console_handler)
    
    # Add file handler if log_file is provided
    if log_file:
        file_handler = RotatingFileHandler(
            log_file,
            maxBytes=1024*1024,  # 1MB
            backupCount=5
        )
        file_handler.setFormatter(file_formatter)
        root_logger.addHandler(file_handler)

def validate_pattern(pattern: str) -> bool:
    """Validates the input pattern for timeline renaming.
    
    Args:
        pattern: The pattern to validate
        
    Returns:
        bool: True if pattern is valid, False otherwise
    """
    # Check for required placeholders
    required_placeholders = ['{n}', '{original}', '{current_date}', '{version}', '{version+1}', '{version-1}']
    has_required = any(ph in pattern for ph in required_placeholders)
    
    if not has_required:
        logging.error("Pattern must contain at least one of: " + ", ".join(required_placeholders))
        return False
    
    # Check for balanced braces
    if pattern.count('{') != pattern.count('}'):
        logging.error("Pattern has unbalanced braces")
        return False
    
    # Check for valid placeholder names
    valid_placeholders = set(required_placeholders)
    found_placeholders = re.findall(r'\{([^}]+)\}', pattern)
    invalid_placeholders = [p for p in found_placeholders if '{' + p + '}' not in valid_placeholders]
    
    if invalid_placeholders:
        logging.error(f"Invalid placeholders found: {', '.join(invalid_placeholders)}")
        return False
    
    return True

# --- Import DaVinciResolveScript ---
try:
    import DaVinciResolveScript as dvr_script
except ImportError:
    # Standard paths for DaVinci Resolve Scripting API
    script_paths = [
        '/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules',  # macOS
        'C:\\ProgramData\\Blackmagic Design\\DaVinci Resolve\\Support\\Developer\\Scripting\\Modules',  # Windows
        '/opt/resolve/Developer/Scripting/Modules'  # Linux
    ]
    for path in script_paths:
        if path not in sys.path and os.path.exists(path):
            sys.path.append(path)
    try:
        import DaVinciResolveScript as dvr_script
    except ImportError:
        logging.critical("Could not import DaVinciResolveScript. Please ensure scripting is enabled and paths are correct.")
        sys.exit(1)

def get_item_type(item) -> str:
    """Determines the type of a MediaPoolItem from its properties.
    
    Args:
        item: A MediaPoolItem object from DaVinci Resolve
        
    Returns:
        str: The type of the item ('Timeline', 'Audio', 'Video', or 'Unknown')
        
    Raises:
        AttributeError: If the item doesn't have GetClipProperty method
        RuntimeError: If there's an error accessing the properties
    """
    try:
        properties = item.GetClipProperty()
        return properties.get('Type', 'Unknown')
    except AttributeError as e:
        logging.error(f"Invalid item object: {e}")
        return 'Unknown'
    except RuntimeError as e:
        logging.error(f"Error accessing item properties: {e}")
        return 'Unknown'
    except Exception as e:
        logging.error(f"Unexpected error getting item type: {e}")
        return 'Unknown'

def find_timeline_by_name(project, name):
    """Finds a timeline by its name"""
    timeline_count = project.GetTimelineCount()
    for i in range(1, timeline_count + 1):
        timeline = project.GetTimelineByIndex(i)
        if timeline and timeline.GetName() == name:
            return timeline
    return None

def extract_version(original_name: str) -> int | None:
    """Extracts version number from name (e.g., 'v001', 'V2', etc.)
    
    Args:
        original_name: The name to extract version from
        
    Returns:
        int | None: The version number if found, None otherwise
    """
    # Matches patterns like v001, V2, version1, etc.
    version_match = re.search(r'[vV](?:ersion)?(\d+)', original_name)
    if version_match:
        version = int(version_match.group(1))
        logging.debug(f"Extracted version {version} from {original_name}")
        return version
    logging.debug(f"No version number found in {original_name}")
    return None

def process_version(original_name: str, operation: str) -> str | None:
    """Processes version number based on the requested operation.
    
    Args:
        original_name: The original name containing the version
        operation: The operation to perform ('+1' or '-1')
        
    Returns:
        str | None: The new name with updated version, or None if processing failed
    """
    # First remove any existing date
    name_without_date = re.sub(r'\d{4}-\d{2}-\d{2}', '', original_name)
    name_without_date = re.sub(r'_+', '_', name_without_date)
    name_without_date = name_without_date.strip(' _')
    
    # Then process version
    version = extract_version(name_without_date)
    if version is None:
        logging.info(f"No version number found in {name_without_date}, skipping item")
        return None
    
    if operation == "+1":
        new_version = version + 1
    elif operation == "-1":
        new_version = version - 1
    else:
        logging.warning(f"Unknown operation {operation}, skipping item")
        return None
    
    # Replaces version number in original name while maintaining original format
    new_name = re.sub(r'[vV](?:ersion)?\d+', f'v{new_version}', name_without_date)
    logging.debug(f"Version {operation}: {original_name} -> {new_name}")
    return new_name

def rename_timeline(timeline, new_name: str, should_duplicate: bool = False) -> bool:
    """Renames a timeline and optionally duplicates it.
    
    Args:
        timeline: The timeline to rename
        new_name: The new name for the timeline
        should_duplicate: Whether to duplicate the timeline before renaming
        
    Returns:
        bool: True if operation was successful, False otherwise
    """
    original_name = timeline.GetName()
    try:
        if should_duplicate:
            logging.info(f"Duplicating timeline: {original_name}")
            duplicated_timeline = timeline.DuplicateTimeline(new_name)
            if duplicated_timeline:
                logging.info(f"Successfully duplicated and renamed: '{original_name}' → '{new_name}'")
                return True
            else:
                logging.error(f"Failed to duplicate timeline '{original_name}'")
                return False
        else:
            logging.info(f"Renaming timeline: {original_name}")
            result = timeline.SetName(new_name)
            
            if result:
                logging.info(f"Successfully renamed: '{original_name}' → '{new_name}'")
                return True
            else:
                logging.error(f"Failed to rename '{original_name}'")
                return False
            
    except Exception as e:
        logging.error(f"Error processing timeline '{original_name}': {e}")
        return False

def process_date(original_name):
    """Processes date in the name - removes existing date if present and adds current date"""
    # Common date patterns (YYYY-MM-DD, DD-MM-YYYY, MM-DD-YYYY, etc.)
    date_patterns = [
        r'\d{4}-\d{2}-\d{2}',  # YYYY-MM-DD
        r'\d{2}-\d{2}-\d{4}',  # DD-MM-YYYY or MM-DD-YYYY
        r'\d{2}/\d{2}/\d{4}',  # DD/MM/YYYY or MM/DD/YYYY
        r'\d{4}/\d{2}/\d{2}'   # YYYY/MM/DD
    ]
    
    # Remove any existing date
    name_without_date = original_name
    for pattern in date_patterns:
        name_without_date = re.sub(pattern, '', name_without_date)
    
    # Clean up any resulting double spaces or dashes
    name_without_date = re.sub(r'\s+', ' ', name_without_date)
    name_without_date = re.sub(r'-+', '-', name_without_date)
    name_without_date = name_without_date.strip(' -')
    
    # Add current date
    current_date = datetime.now().strftime("%Y-%m-%d")
    return f"{name_without_date} {current_date}".strip()

def main():
    # Setup logging
    log_file = os.path.join(os.path.dirname(__file__), 'timeline_version_up.log')
    setup_logging(log_file)
    
    # Check command line arguments
    if len(sys.argv) != 2:
        logging.error("Usage: python3 timeline_version_up.py 'NewNamePattern'")
        sys.exit(1)
        
    pattern = sys.argv[1]
    logging.info(f"Using pattern: {pattern}")
    
    # Validate pattern
    if not validate_pattern(pattern):
        sys.exit(1)
    
    # Connect to Resolve
    resolve = dvr_script.scriptapp("Resolve")
    if resolve is None:
        logging.critical("Failed to connect to DaVinci Resolve")
        sys.exit(1)
        
    try:
        # Get project and media pool
        project = resolve.GetProjectManager().GetCurrentProject()
        if not project:
            logging.critical("No project open")
            sys.exit(1)
            
        mp = project.GetMediaPool()
        if not mp:
            logging.critical("Failed to get MediaPool")
            sys.exit(1)
            
        # Get selected items
        selected_items = mp.GetSelectedClips()
        if not selected_items:
            logging.error("No items selected")
            sys.exit(1)
            
        logging.info(f"Found {len(selected_items)} selected items")
        
        # Rename each item
        success_count = 0
        skipped_count = 0
        for idx, item in enumerate(selected_items, 1):
            item_type = get_item_type(item)
            if item_type != 'Timeline':
                logging.warning(f"Item {idx} is not a timeline (Type: {item_type}), skipping")
                skipped_count += 1
                continue

            original_name = item.GetName()
            try:
                # Get current date
                current_date = datetime.now().strftime("%Y-%m-%d")
                
                # Handle version operations first
                if pattern == "{version+1}":
                    new_name = process_version(original_name, "+1")
                    if new_name is None:
                        skipped_count += 1
                        continue
                    # For version+1, we want to duplicate the timeline
                    should_duplicate = True
                else:
                    # Process the pattern
                    processed_pattern = pattern
                    should_duplicate = False
                    
                    # Handle version operations in the pattern
                    version_match = re.search(r"{version([+-]1)}", processed_pattern)
                    if version_match:
                        operation = version_match.group(1)
                        version_result = process_version(original_name, operation)
                        if version_result is None:
                            skipped_count += 1
                            continue
                        processed_pattern = processed_pattern.replace(version_match.group(0), version_result)
                        # Only duplicate if it's version+1
                        should_duplicate = operation == "+1"
                    
                    # Handle other placeholders
                    try:
                        new_name = processed_pattern.format(
                            n=idx,
                            original=original_name,
                            current_date=current_date
                        )
                    except KeyError as e:
                        logging.error(f"Error processing pattern: {e}")
                        skipped_count += 1
                        continue
                
                # Clean up any double underscores or spaces
                new_name = re.sub(r'_+', '_', new_name)
                new_name = re.sub(r'\s+', ' ', new_name)
                new_name = new_name.strip(' _')
                
                logging.info(f"Final new name: {new_name}")
                
                # Find and rename timeline
                timeline = find_timeline_by_name(project, original_name)
                if timeline:
                    if rename_timeline(timeline, new_name, should_duplicate):
                        success_count += 1
                else:
                    logging.error(f"Could not find timeline '{original_name}'")
                    
            except Exception as e:
                logging.error(f"Error processing item {idx} ('{original_name}'): {e}")
        
        # Print summary
        logging.info(f"\nProcessed {len(selected_items)} items:")
        logging.info(f"- Renamed: {success_count}")
        logging.info(f"- Skipped: {skipped_count}")
        logging.info(f"- Failed: {len(selected_items) - success_count - skipped_count}")
        
    finally:
        # Cleanup
        if resolve:
            try:
                resolve = None
            except:
                pass

if __name__ == "__main__":
    main() 
