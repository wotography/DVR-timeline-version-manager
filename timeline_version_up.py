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
    version = extract_version(original_name)
    if version is None:
        logging.info(f"No version number found in {original_name}, skipping item")
        return None
    
    if operation == "+1":
        new_version = version + 1
    elif operation == "-1":
        new_version = version - 1
    else:
        logging.warning(f"Unknown operation {operation}, skipping item")
        return None
    
    # Replaces version number in original name while maintaining original format
    new_name = re.sub(r'[vV](?:ersion)?\d+', f'v{new_version}', original_name)
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
    
    # Get current date for {date} placeholder
    date_str = datetime.now().strftime("%Y-%m-%d")
    
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
            processed_pattern = pattern
            version_operations = re.finditer(r"{version([+-]1)}", pattern)
            skip_item = False
            
            for match in version_operations:
                operation = match.group(1)
                processed_name = process_version(original_name, operation)
                if processed_name is None:
                    skip_item = True
                    skipped_count += 1
                    break
                logging.info(f"Version operation {operation}: {original_name} -> {processed_name}")
                processed_pattern = processed_pattern.replace(match.group(0), processed_name)
            
            if skip_item:
                continue
            
            # Replace remaining placeholders
            new_name = processed_pattern.format(
                n=idx,
                original=original_name,
                date=date_str
            )
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
