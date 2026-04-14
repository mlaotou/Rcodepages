#!/usr/bin/env python3
"""
Generate searchable index for Rcodepages
Adapted from FigureYa to work with directory structure:
01基础图/点线图/泳道图/泳道图.html
"""

import os
import re
import json
from bs4 import BeautifulSoup

PUBLISH_DIR = "."  # Output to root directory

def extract_category_number(folder_name):
    """Extract number from folder like '01基础图' -> 1"""
    m = re.match(r'(\d+)', folder_name)
    return int(m.group(1)) if m else 999999

def find_thumbnail(folder_path, html_filename):
    """Find thumbnail image in the same folder"""
    base_name = os.path.splitext(html_filename)[0]

    # Common image extensions
    img_extensions = ['.png', '.jpg', '.jpeg', '.webp', '.pdf']

    for ext in img_extensions:
        # Try same name with different extension
        for img_ext in img_extensions:
            thumb_candidates = [
                f"{base_name}.{img_ext.lstrip('.')}",
                f"{base_name}_plot.{img_ext.lstrip('.')}",
                f"{base_name}_output.{img_ext.lstrip('.')}",
            ]
            for thumb in thumb_candidates:
                thumb_path = os.path.join(folder_path, thumb)
                if os.path.isfile(thumb_path):
                    return thumb_path

    # If no match, look for any image file in folder
    for root, dirs, files in os.walk(folder_path):
        for f in files:
            if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
                return os.path.join(root, f)
        break  # Only check immediate folder

    return None

def strip_outputs_and_images(raw_html):
    """Remove images and output blocks from HTML, extract plain text"""
    soup = BeautifulSoup(raw_html, "html.parser")
    for img in soup.find_all("img"):
        img.decompose()
    for pre in soup.find_all("pre"):
        code = pre.find("code")
        if code and code.text.lstrip().startswith("##"):
            pre.decompose()
    for div in soup.find_all("div", class_=lambda x: x and any("output" in c for c in x)):
        div.decompose()
    for pre in soup.find_all("pre"):
        parent = pre.parent
        while parent:
            if parent.has_attr("class") and any("output" in c for c in parent["class"]):
                pre.decompose()
                break
            parent = parent.parent
    return soup.get_text(separator="\n", strip=True)

def get_html_files(base_path, branch_label, chapters_meta):
    """Traverse folders and extract HTML file information"""

    # First, find all top-level categories (e.g., 01基础图, 02热图)
    categories = [f for f in os.listdir(base_path)
                if os.path.isdir(os.path.join(base_path, f))
                and not f.startswith('.')
                and not f.startswith('texts')]

    # Sort by category number
    categories_sorted = sorted(categories, key=extract_category_number)

    for category in categories_sorted:
        category_path = os.path.join(base_path, category)

        # Find all subdirectories in this category
        subdirs = [f for f in os.listdir(category_path)
                  if os.path.isdir(os.path.join(category_path, f))
                  and not f.startswith('.')]

        for subdir in subdirs:
            subdir_path = os.path.join(category_path, subdir)
            html_files = [f for f in os.listdir(subdir_path) if f.endswith('.html')]

            if not html_files:
                continue

            # Sort HTML files
            html_files_sorted = sorted(html_files)

            for fname in html_files_sorted:
                html_path = os.path.join(subdir_path, fname)
                rel_path = os.path.relpath(html_path, PUBLISH_DIR)

                # Create chapter ID
                folder_name = f"{category}/{subdir}"
                chap_id = f"{branch_label}_{folder_name}_{fname}".replace(" ", "_").replace(".html", "").replace("/", "_")

                # Find thumbnail
                thumb_rel = None
                thumb_abs = find_thumbnail(subdir_path, fname)
                if thumb_abs and os.path.isfile(thumb_abs):
                    thumb_rel = os.path.relpath(thumb_abs, PUBLISH_DIR)

                # Extract text content
                with open(html_path, encoding='utf-8') as f:
                    raw_html = f.read()
                    text = strip_outputs_and_images(raw_html)

                # Create texts directory
                texts_dir = os.path.join(PUBLISH_DIR, "texts")
                os.makedirs(texts_dir, exist_ok=True)
                text_path = os.path.join("texts", f"{chap_id}.txt")
                abs_text_path = os.path.join(PUBLISH_DIR, text_path)

                with open(abs_text_path, "w", encoding="utf-8") as tf:
                    tf.write(text)

                chapters_meta.append({
                    "id": chap_id,
                    "title": f"{folder_name}/{fname}",
                    "html": rel_path,
                    "text": text_path,
                    "folder": folder_name,
                    "thumb": thumb_rel
                })

# --- Main Logic ---
chapters_meta = []
get_html_files(".", "main", chapters_meta)

# Write chapters.json
with open(os.path.join(PUBLISH_DIR, "chapters.json"), "w", encoding="utf-8") as jf:
    json.dump(chapters_meta, jf, ensure_ascii=False, indent=2)

print(f"Successfully generated index for {len(chapters_meta)} HTML files")
print("- chapters.json: Chapter metadata")
print("- texts/: Text content directory (for full-text search)")