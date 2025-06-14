import sys
import os
import logging
import re
from datetime import datetime

# --- Logging Configuration ---
logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s"
)

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

def get_item_type(item):
    """Determines the type of a MediaPoolItem from its properties"""
    try:
        properties = item.GetClipProperty()
        return properties.get('Type', 'Unknown')
    except:
        return 'Unknown'

def find_timeline_by_name(project, name):
    """Finds a timeline by its name"""
    timeline_count = project.GetTimelineCount()
    for i in range(1, timeline_count + 1):
        timeline = project.GetTimelineByIndex(i)
        if timeline and timeline.GetName() == name:
            return timeline
    return None

def extract_version(original_name):
    """Extracts version number from name (e.g., 'v001', 'V2', etc.)"""
    # Matches patterns like v001, V2, version1, etc.
    version_match = re.search(r'[vV](?:ersion)?(\d+)', original_name)
    if version_match:
        version = int(version_match.group(1))
        logging.debug(f"Extracted version {version} from {original_name}")
        return version
    logging.debug(f"No version number found in {original_name}")
    return None

def process_version(original_name, operation):
    """Processes version number based on the requested operation"""
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

def rename_timeline(timeline, new_name):
    """Renames a timeline"""
    original_name = timeline.GetName()
    try:
        logging.info(f"Renaming timeline: {original_name}")
        result = timeline.SetName(new_name)
            
        if result:
            logging.info(f"Successfully renamed: '{original_name}' → '{new_name}'")
            return True
        else:
            logging.error(f"Failed to rename '{original_name}'")
            return False
            
    except Exception as e:
        logging.error(f"Error renaming '{original_name}': {e}")
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
    # Check command line arguments
    if len(sys.argv) != 2:
        logging.error("Usage: python3 timeline_version_up.py 'NewNamePattern'")
        sys.exit(1)
        
    pattern = sys.argv[1]
    logging.info(f"Using pattern: {pattern}")
    
    # Connect to Resolve
    resolve = dvr_script.scriptapp("Resolve")
    if resolve is None:
        logging.critical("Failed to connect to DaVinci Resolve")
        sys.exit(1)
        
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
            # Process version operations first
            version_name = original_name
            skip_item = False
            
            # Handle version operations
            version_operations = re.finditer(r"{version([+-]1)}", pattern)
            for match in version_operations:
                operation = match.group(1)
                version_result = process_version(version_name, operation)
                if version_result is None:
                    skip_item = True
                    skipped_count += 1
                    break
                version_name = version_result
                logging.info(f"Version operation {operation}: {original_name} -> {version_name}")
            
            if skip_item:
                continue
            
            # Get the base name without version and date
            base_name = re.sub(r'v\d+', '', original_name)
            base_name = re.sub(r'\d{4}-\d{2}-\d{2}', '', base_name)
            base_name = re.sub(r'_+', '_', base_name)
            base_name = base_name.strip(' _')
            
            # Get current date
            current_date = datetime.now().strftime("%Y-%m-%d")
            
            # Build the new name
            if pattern == "{version+1}_{current_date}":
                new_name = f"{version_name}_{current_date}"
            else:
                # Handle other patterns if needed
                new_name = pattern.format(
                    n=idx,
                    original=original_name,
                    current_date=current_date
                )
            
            # Clean up any double underscores or spaces
            new_name = re.sub(r'_+', '_', new_name)
            new_name = re.sub(r'\s+', ' ', new_name)
            new_name = new_name.strip(' _')
            
            logging.info(f"Final new name: {new_name}")
            
            # Find and rename timeline
            timeline = find_timeline_by_name(project, original_name)
            if timeline:
                if rename_timeline(timeline, new_name):
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

if __name__ == "__main__":
    main() 
