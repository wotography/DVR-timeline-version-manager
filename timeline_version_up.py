# VERSION: v0.2.3 (2025-06-14)

import sys
import os
import logging
import re
from datetime import datetime
from logging.handlers import RotatingFileHandler
from typing import Optional, List, Dict, Any, Union
import time

# --- Constants ---
REQUIRED_PLACEHOLDERS = ['{n}', '{original}', '{current_date}', '{version}', '{version+1}', '{version-1}']
VERSION_PATTERN = r'[vV](?:ersion)?(\d+)'
DATE_PATTERNS = [
    r'\d{4}-\d{2}-\d{2}',  # YYYY-MM-DD
    r'\d{2}-\d{2}-\d{4}',  # DD-MM-YYYY or MM-DD-YYYY
    r'\d{2}/\d{2}/\d{4}',  # DD/MM/YYYY or MM/DD/YYYY
    r'\d{4}/\d{2}/\d{2}'   # YYYY/MM/DD
]

# --- DaVinci Resolve Import ---
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

# --- Logging Configuration ---
def setup_logging(log_file: Optional[str] = None) -> None:
    """Sets up logging configuration with both console and file handlers."""
    # Create formatters
    console_formatter = logging.Formatter("%(levelname)s: %(message)s")
    file_formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    
    # Setup root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
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

# --- Utility Functions ---
def validate_pattern(pattern: str) -> bool:
    """Validates the input pattern for timeline renaming."""
    # Check for required placeholders
    has_required = any(ph in pattern for ph in REQUIRED_PLACEHOLDERS)
    if not has_required:
        logging.error(f"Pattern must contain at least one of: {', '.join(REQUIRED_PLACEHOLDERS)}")
        return False
    
    # Check for balanced braces
    if pattern.count('{') != pattern.count('}'):
        logging.error("Pattern has unbalanced braces")
        return False
    
    # Check for valid placeholder names
    valid_placeholders = set(REQUIRED_PLACEHOLDERS)
    found_placeholders = re.findall(r'\{([^}]+)\}', pattern)
    invalid_placeholders = [p for p in found_placeholders if '{' + p + '}' not in valid_placeholders]
    
    if invalid_placeholders:
        logging.error(f"Invalid placeholders found: {', '.join(invalid_placeholders)}")
        return False
    
    return True

def extract_version(original_name: str) -> Optional[int]:
    """Extracts version number from name (e.g., 'v001', 'V2', etc.)."""
    version_match = re.search(VERSION_PATTERN, original_name)
    if version_match:
        version = int(version_match.group(1))
        logging.debug(f"Extracted version {version} from {original_name}")
        return version
    logging.debug(f"No version number found in {original_name}")
    return None

def process_date(original_name: str) -> str:
    """Processes date in the name - removes existing date if present and adds current date."""
    # Remove any existing date
    name_without_date = original_name
    for pattern in DATE_PATTERNS:
        name_without_date = re.sub(pattern, '', name_without_date)
    
    # Clean up any resulting double spaces or dashes
    name_without_date = re.sub(r'\s+', ' ', name_without_date)
    name_without_date = re.sub(r'-+', '-', name_without_date)
    name_without_date = name_without_date.strip(' -')
    
    # Add current date
    current_date = datetime.now().strftime("%Y-%m-%d")
    return f"{name_without_date} {current_date}".strip()

def process_version(original_name: str, operation: str) -> Optional[str]:
    """Processes version number based on the requested operation."""
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
    new_name = re.sub(VERSION_PATTERN, f'v{new_version}', name_without_date)
    logging.debug(f"Version {operation}: {original_name} -> {new_name}")
    return new_name

# --- DaVinci Resolve Integration ---
def get_item_type(item: Any) -> str:
    """Determines the type of a MediaPoolItem from its properties."""
    try:
        properties = item.GetClipProperty()
        return properties.get('Type', 'Unknown')
    except (AttributeError, RuntimeError) as e:
        logging.error(f"Error accessing item properties: {e}")
        return 'Unknown'
    except Exception as e:
        logging.error(f"Unexpected error getting item type: {e}")
        return 'Unknown'

def find_timeline_by_name(project: Any, name: str) -> Optional[Any]:
    """Finds a timeline by its name."""
    timeline_count = project.GetTimelineCount()
    for i in range(1, timeline_count + 1):
        timeline = project.GetTimelineByIndex(i)
        if timeline and timeline.GetName() == name:
            return timeline
    return None

def find_parent_folder_recursive(folder: Any, target_name: str) -> Optional[Any]:
    """Recursively search for a folder's parent."""
    subfolders = folder.GetSubFolderList()
    for subfolder in subfolders:
        if subfolder.GetName() == target_name:
            return folder
        # Recursively search in this subfolder
        parent = find_parent_folder_recursive(subfolder, target_name)
        if parent:
            return parent
    return None

def create_version_folder(media_pool: Any, current_folder: Any, original_name: str, new_name: str) -> Optional[Any]:
    """Creates a new folder for the versioned timeline."""
    try:
        # Get the root folder
        root_folder = media_pool.GetRootFolder()
        logging.info(f"Root folder name: {root_folder.GetName()}")
        
        # Extract version number from the new name
        version_match = re.search(VERSION_PATTERN, new_name)
        if not version_match:
            logging.error(f"Could not extract version number from new name: {new_name}")
            return None
            
        # Create folder name using the version number
        folder_name = f"v{version_match.group(1)}"
        logging.info(f"Creating folder: {folder_name}")
        
        # Get current folder name
        current_folder_name = current_folder.GetName()
        logging.info(f"Looking for parent of folder: {current_folder_name}")
        
        # Find parent folder recursively
        parent_folder = find_parent_folder_recursive(root_folder, current_folder_name)
        
        if not parent_folder:
            logging.error("Could not find parent folder")
            return None
            
        logging.info(f"Found parent folder: {parent_folder.GetName()}")
            
        # Check if folder already exists in parent
        subfolders = parent_folder.GetSubFolderList()
        for folder in subfolders:
            if folder.GetName() == folder_name:
                logging.info(f"Using existing folder: {folder_name}")
                return folder
        
        # Create the folder in parent
        new_folder = media_pool.AddSubFolder(parent_folder, folder_name)
        if new_folder:
            logging.info(f"Created new folder: {folder_name}")
            return new_folder
        else:
            logging.error(f"Failed to create folder: {folder_name}")
            return None
            
    except Exception as e:
        logging.error(f"Error creating version folder: {e}")
        return None

def rename_timeline(timeline: Any, new_name: str, should_duplicate: bool = False, media_pool: Optional[Any] = None) -> bool:
    """Renames a timeline and optionally duplicates it."""
    original_name = timeline.GetName()
    try:
        if should_duplicate:
            logging.info(f"Duplicating timeline: {original_name}")
            duplicated_timeline = timeline.DuplicateTimeline(new_name)
            if duplicated_timeline:
                logging.info(f"Successfully duplicated and renamed: '{original_name}' → '{new_name}'")
                
                # If we have a media pool, create a version folder and move the timeline
                if media_pool:
                    # Get the current folder
                    current_folder = media_pool.GetCurrentFolder()
                    if current_folder:
                        # Create a new version folder using the new name
                        version_folder = create_version_folder(media_pool, current_folder, original_name, new_name)
                        if version_folder:
                            # Wait a moment for the timeline to be fully created in the MediaPool
                            time.sleep(1)  # Give Resolve time to process the duplication
                            
                            # Try to get the MediaPoolItem directly from the timeline first
                            timeline_clip = duplicated_timeline.GetMediaPoolItem()
                            
                            # If that fails, try to find it in the current folder
                            if not timeline_clip:
                                clips = current_folder.GetClipList()
                                for clip in clips:
                                    if clip.GetName() == new_name:
                                        timeline_clip = clip
                                        break
                            
                            if timeline_clip:
                                # Move the timeline to the new folder
                                result = media_pool.MoveClips([timeline_clip], version_folder)
                                if result:
                                    logging.info(f"Moved timeline to folder: {version_folder.GetName()}")
                                else:
                                    logging.warning("Failed to move timeline to version folder, but duplication was successful")
                            else:
                                logging.warning(f"Could not find duplicated timeline in MediaPool: {new_name}")
                
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

def main() -> None:
    """Main function to handle timeline versioning."""
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
                    if rename_timeline(timeline, new_name, should_duplicate, mp):
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
