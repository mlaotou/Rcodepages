#!/usr/bin/env python3
"""
Generate file_list.json for folder downloads
Creates a JSON with folder names as keys and file lists as values
"""

import os
import json
import re

PUBLISH_DIR = "."
EXCLUDE_DIRS = {'.git', '.github', 'texts', '__pycache__', 'public', 'scripts'}
EXCLUDE_FILES = {'.gitignore', 'README.md'}

def extract_category_number(folder_name):
    """Extract number from folder like '01基础图' -> 1"""
    m = re.match(r'(\d+)', folder_name)
    return int(m.group(1)) if m else 999999

def get_all_files(base_path, folder_name):
    """Get all files in a directory recursively"""
    folder_path = os.path.join(base_path, folder_name)
    files = []

    if not os.path.exists(folder_path):
        return files

    for root, dirs, filenames in os.walk(folder_path):
        # Skip hidden directories
        dirs[:] = [d for d in dirs if not d.startswith('.')]

        for filename in filenames:
            if filename.startswith('.'):
                continue

            full_path = os.path.join(root, filename)
            rel_path = os.path.relpath(full_path, base_path).replace('\\', '/')

            size = os.path.getsize(full_path)
            files.append({
                "name": rel_path,
                "size": size
            })

    return sorted(files, key=lambda x: x['name'])

def generate_file_list():
    """Generate file_list.json"""
    file_list = {}

    # Find all folders
    all_folders = [f for f in os.listdir(PUBLISH_DIR)
                if os.path.isdir(os.path.join(PUBLISH_DIR, f))
                and f not in EXCLUDE_DIRS
                and not f.startswith('.')]

    all_folders_sorted = sorted(all_folders, key=extract_category_number)

    for folder in all_folders_sorted:
        folder_path = os.path.join(PUBLISH_DIR, folder)

        # Check if folder has subdirectories
        subdirs = [f for f in os.listdir(folder_path)
                  if os.path.isdir(os.path.join(folder_path, f))
                  and not f.startswith('.')]

        if len(subdirs) >= 2:
            # Has subdirs - it's a category, process each subfolder
            for subdir in subdirs:
                folder_name = f"{folder}/{subdir}"
                files = get_all_files(PUBLISH_DIR, folder_name)
                if files:
                    file_list[folder_name] = files
        else:
            # No subdirs or only 1 subdir - treat as single folder
            files = get_all_files(PUBLISH_DIR, folder)
            if files:
                file_list[folder] = files

    # Write file_list.json
    output_path = os.path.join(PUBLISH_DIR, "file_list.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(file_list, f, ensure_ascii=False, indent=2)

    print(f"Generated file_list.json with {len(file_list)} folders")

if __name__ == "__main__":
    generate_file_list()