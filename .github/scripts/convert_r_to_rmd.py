#!/usr/bin/env python3
"""
Optimized R to Rmd converter - V2
- Uses clean template (no setwd)
- Removes setwd/rstudioapi from R code
- Properly formats for Rmd rendering
"""

import os
import re

TEMPLATE_PATH = "templates.Rmd"
EXCLUDE_DIRS = {'.git', '.github', 'texts', '__pycache__', 'public'}

def get_template():
    """Read the template file"""
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
    """Clean R code - remove incompatible commands"""
    lines = r_content.split('\n')
    cleaned_lines = []

    for line in lines:
        stripped = line.strip()

        # Remove setwd, rstudioapi, rm(list=ls()) related lines
        if any(p in line for p in ['setwd(', 'rstudioapi', "rm(list=ls())", 'getActiveDocumentContext']):
            continue

        # Skip empty lines in removed sections
        if not stripped:
            cleaned_lines.append(line)
            continue

        cleaned_lines.append(line)

    return '\n'.join(cleaned_lines)

def convert_r_to_rmd(r_file_path):
    """Convert .R file to .Rmd"""
    with open(r_file_path, 'r', encoding='utf-8') as f:
        r_content = f.read()

    # Get folder name for title
    folder_name = os.path.dirname(r_file_path)
    if folder_name == '.':
        folder_name = os.path.basename(os.getcwd())
    title = os.path.splitext(os.path.basename(r_file_path))[0]

    # Get template and set title
    template = get_template()
    rmd_content = template.replace("{title}", folder_name + " - " + title)

    # Clean R code
    cleaned_code = clean_r_code(r_content)

    # Check for ggplot (can use ggsave)
    has_ggplot = 'ggplot' in cleaned_code or 'geom_' in cleaned_code

    # Check for base plot (needs different save method)
    has_base_plot = 'plot(' in cleaned_code and 'ggplot' not in cleaned_code

    # Check if already has save command
    has_save = 'ggsave' in cleaned_code.lower() or 'pdf(' in cleaned_code.lower() or 'png(' in cleaned_code.lower()

    # Add main code chunk
    rmd_content += '\n```{r}\n'
    rmd_content += cleaned_code.rstrip()

    # Add save command only for ggplot (not base R or scatterplot3d)
    if has_ggplot and not has_save:
        rmd_filename = title + ".png"
        rmd_content += f'\n\n# Save as PNG\nggsave("{rmd_filename}", width = 8, height = 6, dpi = 300)'
    elif has_base_plot and not has_save:
        rmd_filename = title + ".png"
        rmd_content += f'\n\n# Save as PNG\npng("{rmd_filename}", width = 1600, height = 1200)\ndev.off()'

    rmd_content += '\n```\n'

    # Add session info
    rmd_content += '''
# Session info
```{r session-info}
sessioninfo::session_info()
```
'''

    # Write output
    rmd_filename = os.path.splitext(r_file_path)[0] + ".Rmd"
    with open(rmd_filename, 'w', encoding='utf-8') as f:
        f.write(rmd_content)

    return rmd_filename

def find_r_files():
    """Find all .R files in folders, skip if .Rmd already exists"""
    r_files = []
    for folder in os.listdir('.'):
        if not os.path.isdir(folder) or folder.startswith('.') or folder in EXCLUDE_DIRS:
            continue
        folder_path = os.path.join('.', folder)
        for subfolder in os.listdir(folder_path):
            subfolder_path = os.path.join(folder_path, subfolder)
            if not os.path.isdir(subfolder_path) or subfolder.startswith('.'):
                continue
            # Find all .R files in subfolder
            for f in os.listdir(subfolder_path):
                if f.endswith('.R'):
                    r_file = os.path.join(subfolder_path, f)
                    rmd_file = os.path.splitext(r_file)[0] + '.Rmd'
                    # Skip if .Rmd already exists
                    if os.path.exists(rmd_file):
                        print(f"  Skip (RMD exists): {rmd_file}")
                        continue
                    r_files.append(r_file)
        # Also check root folder for .R files (no subfolder)
        for f in os.listdir(folder_path):
            if f.endswith('.R') and os.path.isfile(os.path.join(folder_path, f)):
                r_file = os.path.join(folder_path, f)
                rmd_file = os.path.splitext(r_file)[0] + '.Rmd'
                if os.path.exists(rmd_file):
                    print(f"  Skip (RMD exists): {rmd_file}")
                    continue
                r_files.append(r_file)
    return r_files

def main():
    print("=== R to Rmd Converter V2 ===")

    r_files = find_r_files()
    print(f"Found {len(r_files)} folders with .R files")

    for r_file in r_files:
        print(f"\nConverting: {r_file}")
        try:
            rmd_file = convert_r_to_rmd(r_file)
            print(f"  -> Created: {rmd_file}")
        except Exception as e:
            print(f"  -> Error: {e}")

    print("\nDone!")

if __name__ == "__main__":
    main()