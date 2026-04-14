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

    # Check for plotting
    has_plot = any(p in cleaned_code for p in ['ggplot', 'plot(', 'geom_', 'ggsave'])

    # Add main code chunk
    rmd_content += '\n```{r}\n'
    rmd_content += cleaned_code.rstrip()

    # Add ggsave if has plot but no save command
    if has_plot and 'ggsave' not in cleaned_code.lower():
        rmd_filename = title + ".png"
        rmd_content += f'\n\n# Save as PNG\nggsave("{rmd_filename}", width = 8, height = 6, dpi = 300)'

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
    """Find .R files in folders"""
    r_files = []
    for folder in os.listdir('.'):
        if not os.path.isdir(folder) or folder.startswith('.'):
            continue
        r_file = os.path.join(folder, folder + ".R")
        if os.path.exists(r_file):
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