#!/usr/bin/env python3
"""Generate searchable index - auto-detect categories"""
import os
import json
from bs4 import BeautifulSoup

# 创建texts目录
os.makedirs('texts', exist_ok=True)

def find_html():
    chapters = []
    categories = set()

    # 统计每个一级文件夹有多少子文件夹
    for top_folder in os.listdir('.'):
        if not os.path.isdir(top_folder) or top_folder.startswith('.'):
            continue

        subfolders = [d for d in os.listdir(top_folder)
                     if os.path.isdir(os.path.join(top_folder, d)) and not d.startswith('.')]

        if len(subfolders) >= 1:
            categories.add(top_folder)

    print(f"Categories (2+ subfolders): {categories}")

    # 处理每个文件夹
    for top_folder in os.listdir('.'):
        if not os.path.isdir(top_folder) or top_folder.startswith('.'):
            continue

        subfolders = [d for d in os.listdir(top_folder)
                     if os.path.isdir(os.path.join(top_folder, d)) and not d.startswith('.')]

        if len(subfolders) >= 1:
            for subfolder in subfolders:
                full_path = os.path.join(top_folder, subfolder)
                for f in os.listdir(full_path):
                    if f.endswith('.html'):
                        _add_chapter(chapters, top_folder, subfolder, os.path.join(full_path, f))
        else:
            for f in os.listdir(top_folder):
                if f.endswith('.html'):
                    _add_chapter(chapters, None, top_folder, os.path.join(top_folder, f))

    return chapters

def _add_chapter(chapters, category, folder_name, html_path):
    html_name = os.path.basename(html_path)
    folder_path = os.path.dirname(html_path)
    title_name = html_name.replace('.html', '')

    # 缩略图
    thumb = None
    for ext in ['.png', '.jpg', '.jpeg']:
        for t in [title_name + ext, title_name + '_plot' + ext]:
            if os.path.exists(os.path.join(folder_path, t)):
                thumb = os.path.join(folder_path, t).replace('\\', '/')
                break

    # 文本 - 保存到texts目录
    text = ""
    try:
        soup = BeautifulSoup(open(html_path, encoding='utf-8'), 'html.parser')
        text = soup.get_text(separator='\n', strip=True)
    except:
        pass

    text_file = f"texts/{title_name}.txt"
    with open(text_file, 'w', encoding='utf-8') as tf:
        tf.write(text)
    text_file_for_json = text_file.replace('\\', '/')

    # folder路径 - 父文件夹路径
    if category:
        folder = f"{category}/{folder_name}"
    else:
        folder = folder_name

    html_path_for_json = html_path.replace('\\', '/')
    entry = {
        "id": f"{folder_name}_{title_name}",
        "title": title_name,
        "html": html_path_for_json,
        "text": text_file_for_json,
        "folder": folder,
        "thumb": thumb
    }

    if category:
        entry["category"] = category

    chapters.append(entry)

chapters = find_html()
with open('chapters.json', 'w', encoding='utf-8') as f:
    json.dump(chapters, f, ensure_ascii=False, indent=2)

print(f"Generated {len(chapters)} chapters")