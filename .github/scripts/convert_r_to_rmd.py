#!/usr/bin/env python3
"""
Convert .R scripts to .Rmd format using template
Usage: python .github/scripts/convert_r_to_rmd.py
"""

import os
import re

# Read template
TEMPLATE_PATH = "templates.Rmd"
OUTPUT_DIR = "."

def get_template():
    """Read the template file"""
    if os.path.exists(TEMPLATE_PATH):
        with open(TEMPLATE_PATH, 'r', encoding='utf-8') as f:
            return f.read()
    # Default template if not found
    return '''---
title: "{title}"
author: "Milaotou"
date: "`r Sys.Date()`"
output: html_document
---

# {title}

''' + '''
```{r setup, include=FALSE}
 knitr::opts_chunk$set(echo = TRUE, fig.align = "center", fig.height = 8, fig.width = 10)
```

''' + '''
```{r}
# Your code here

```

'''

def find_r_files():
    """Find all .R files in subdirectories"""
    r_files = []
    for root, dirs, files in os.walk('.'):
        # Skip certain directories
        if any(skip in root for skip in ['.git', '.github', 'texts', '__pycache__']):
            continue
        for f in files:
            if f.endswith('.R') and not f.startswith('-install_'):
                full_path = os.path.join(root, f)
                r_files.append(full_path)
    return r_files

def convert_r_to_rmd(r_file_path):
    """Convert .R file to .Rmd"""
    # Read R file
    with open(r_file_path, 'r', encoding='utf-8') as f:
        r_content = f.read()

    # Get folder/subfolder name for title
    rel_path = os.path.relpath(r_file_path, '.')
    folder_name = os.path.dirname(rel_path)

    # Extract title from folder name or filename
    title = os.path.splitext(os.path.basename(r_file_path))[0]

    # Get template
    template = get_template()

    # Replace title in template
    rmd_content = template.replace("{title}", title)

    # Split R code into chunks
    # Simple approach: wrap entire R code in one chunk
    # Better: try to identify sections

    # Process R content - wrap in code chunk
    code_section = "\n```{r}\n" + r_content.rstrip() + "\n\n```\n"

    # Check for data saving at the end and add ggsave if needed
    # Look for common plotting patterns
    has_plot = any(pattern in r_content for pattern in [
        'ggplot', 'plot(', 'boxplot', 'histogram', 'heatmap',
        'png(', 'pdf(', 'ggsave', 'dev.off'
    ])

    # Add save section if plotting detected
    if has_plot and 'ggsave' not in r_content.lower():
        # Find a suitable filename from the R code
        png_match = re.search(r'png\(["\']([^"\']+)', r_content)
        if png_match:
            img_name = png_match.group(1)
        else:
            img_name = f"{title}.png"

        save_section = f"\n# Save plot\nggsave(\"{img_name}\", width = 10, height = 8, dpi = 300)\n"
        code_section = code_section.rstrip() + "\n" + save_section + "\n```\n"

    # Append code to rmd content
    rmd_content += code_section

    # Add session info section
    rmd_content += '''
# Session info
```{r session-info}
sessioninfo::session_info()
```

'''

    # Write output .Rmd file
    rmd_filename = os.path.splitext(r_file_path)[0] + ".Rmd"
    with open(rmd_filename, 'w', encoding='utf-8') as f:
        f.write(rmd_content)

    return rmd_filename

def main():
    """Main function"""
    print("Finding .R files...")
    r_files = find_r_files()

    if not r_files:
        print("No .R files found!")
        return

    print(f"Found {len(r_files)} .R files")

    converted = []
    for r_file in r_files:
        print(f"Converting: {r_file}")
        try:
            rmd_file = convert_r_to_rmd(r_file)
            converted.append(rmd_file)
            print(f"  -> Created: {rmd_file}")
        except Exception as e:
            print(f"  -> Error: {e}")

    print(f"\nSuccessfully converted {len(converted)} files")

if __name__ == "__main__":
    main()