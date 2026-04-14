#!/usr/bin/env python3
"""Generate searchable index for flat folder structure"""
import os
import json
from bs4 import BeautifulSoup

def find_html():
    chapters = []
    for folder in os.listdir('.'):
        if not os.path.isdir(folder) or folder.startswith('.'):
            continue
        for f in os.listdir(folder):
            if f.endswith('.html'):
                html_path = os.path.join(folder, f)
                rel = html_path
                # Find thumbnail
                thumb = None
                for ext in ['.png', '.jpg', '.jpeg']:
                    for t in [f.replace('.html', ext), f.replace('.html', '_plot' + ext)]:
                        if os.path.exists(os.path.join(folder, t)):
                            thumb = os.path.join(folder, t)
                            break
                # Extract text
                text = ""
                try:
                    soup = BeautifulSoup(open(html_path), 'html.parser')
                    text = soup.get_text(separator='\n', strip=True)
                except:
                    pass
                # Save text
                text_file = f"{folder}_{f.replace('.html', '.txt')}"
                with open(text_file, 'w') as tf:
                    tf.write(text)
                chapters.append({
                    "id": f"{folder}_{f.replace('.html', '')}",
                    "title": f,
                    "html": rel,
                    "text": text_file,
                    "folder": folder,
                    "thumb": thumb
                })
    return chapters

chapters = find_html()
with open('chapters.json', 'w') as f:
    json.dump(chapters, f, ensure_ascii=False, indent=2)
print(f"Generated {len(chapters)} entries")