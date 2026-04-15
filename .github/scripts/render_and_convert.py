#!/usr/bin/env python3
"""
Convert R to Rmd and Render to HTML - All in One
1. Find .R files, convert to .Rmd (skip if exists)
2. Find .Rmd files, render to .html (skip if exists)
"""
import os
import glob
import re

TEMPLATE_PATH = "templates.Rmd"
EXCLUDE_DIRS = {'.git', '.github', 'texts', '__pycache__', 'public'}

def get_template():
    """Read template"""
    if os.path.exists(TEMPLATE_PATH):
        with open(TEMPLATE_PATH, 'r', encoding='utf-8') as f:
            return f.read()
    return '''---
title: "{title}"
author: "Milaotou"
date: "`r Sys.Date()`"
output: html_document
---

```{r setup, include=FALSE}
 knitr::opts_chunk$set(echo = TRUE, fig.align = "center", fig.height = 8, fig.width = 10)
```

# {title}

'''

def clean_r_code(r_content):
    """Clean R code"""
    lines = r_content.split('\n')
    cleaned_lines = []

    for line in lines:
        if any(p in line for p in ['setwd(', 'rstudioapi', "rm(list=ls())", 'getActiveDocumentContext']):
            continue
        cleaned_lines.append(line)

    return '\n'.join(cleaned_lines)

def convert_r_to_rmd(r_file):
    """Convert .R to .Rmd"""
    rmd_file = os.path.splitext(r_file)[0] + '.Rmd'

    # Skip if exists
    if os.path.exists(rmd_file):
        print(f"  Skip (RMD exists): {rmd_file}")
        return False

    with open(r_file, 'r', encoding='utf-8') as f:
        r_content = f.read()

    folder_name = os.path.dirname(r_file)
    if folder_name == '.':
        folder_name = os.path.basename(os.getcwd())
    title = os.path.splitext(os.path.basename(r_file))[0]

    template = get_template()
    rmd_content = template.replace("{title}", title)
    cleaned_code = clean_r_code(r_content)

    # Check for ggplot (can use ggsave)
    has_ggplot = 'ggplot' in cleaned_code or 'geom_' in cleaned_code
    has_base_plot = 'plot(' in cleaned_code and 'ggplot' not in cleaned_code
    has_save = 'ggsave' in cleaned_code.lower() or 'pdf(' in cleaned_code.lower() or 'png(' in cleaned_code.lower()

    rmd_content += '\n```{r}\n' + cleaned_code.rstrip()

    if has_ggplot and not has_save:
        rmd_filename = title + ".png"
        rmd_content += f'\n\nggsave("{rmd_filename}", width = 8, height = 6, dpi = 300)'
    elif has_base_plot and not has_save:
        rmd_filename = title + ".png"
        rmd_content += f'\n\npng("{rmd_filename}", width = 1600, height = 1200)\ndev.off()'

    rmd_content += '\n```\n'

    rmd_content += '''
# Session info
```{r session-info}
sessioninfo::session_info()
```
'''

    with open(rmd_file, 'w', encoding='utf-8') as f:
        f.write(rmd_content)

    print(f"  Converted: {r_file} -> {rmd_file}")
    return True

def render_html(rmd_file):
    """Render .Rmd to .html"""
    import subprocess

    html_file = os.path.splitext(rmd_file)[0] + '.html'

    # Skip if exists
    if os.path.exists(html_file):
        print(f"  Skip (HTML exists): {html_file}")
        return False

    # Get directory and filename separately
    rmd_dir = os.path.dirname(rmd_file)
    rmd_name = os.path.basename(rmd_file)
    work_dir = rmd_dir if rmd_dir else '.'

    print(f"  Rendering: {rmd_name} in {work_dir}")

    # Run R from the file's directory
    try:
        result = subprocess.run(
            ['Rscript', '-e', f'rmarkdown::render("{rmd_name}")'],
            capture_output=True,
            cwd=work_dir
        )
        if result.returncode == 0:
            print(f"    -> OK")
            return True
        else:
            stderr = result.stderr.decode('utf-8', errors='replace') if result.stderr else 'Unknown error'
            print(f"    -> Failed: {stderr[:200]}")
            return False
    except Exception as e:
        print(f"    -> Error: {e}")
        return False

def find_r_files():
    """Find all .R files"""
    r_files = []
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in EXCLUDE_DIRS]
        for f in files:
            if f.endswith('.R'):
                r_files.append(os.path.join(root, f))
    return r_files

def find_rmd_files():
    """Find all .Rmd files"""
    rmd_files = []
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in EXCLUDE_DIRS]
        for f in files:
            if f.endswith('.Rmd') and f != 'templates.Rmd':
                rmd_files.append(os.path.join(root, f))
    return rmd_files

def main():
    print("=== Convert R to Rmd & Render HTML ===\n")

    # Step 1: Convert R to Rmd
    print("Step 1: Converting .R to .Rmd...")
    r_files = find_r_files()
    print(f"Found {len(r_files)} .R files")

    converted = 0
    for r_file in r_files:
        if convert_r_to_rmd(r_file):
            converted += 1

    print(f"Converted {converted}/{len(r_files)} files\n")

    # Step 2: Render Rmd to HTML
    print("Step 2: Rendering .Rmd to .html...")
    rmd_files = find_rmd_files()
    print(f"Found {len(rmd_files)} .Rmd files")

    rendered = 0
    for rmd_file in rmd_files:
        if render_html(rmd_file):
            rendered += 1

    print(f"Rendered {rendered}/{len(rmd_files)} files\n")
    print("=== Done! ===")

if __name__ == "__main__":
    main()