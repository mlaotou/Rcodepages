#!/usr/bin/env python3
"""
Render Rmd to HTML - local rendering
Skips existing HTML files
"""
import os
import glob

def find_rmd_files():
    """Find all .Rmd files"""
    rmd_files = []
    for root, dirs, files in os.walk('.'):
        # Exclude hidden and special directories
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['texts', '__pycache__']]
        for f in files:
            if f.endswith('.Rmd') and f != 'templates.Rmd':
                rmd_files.append(os.path.join(root, f))
    return rmd_files

def render_html(rmd_file):
    """Render Rmd to HTML using R"""
    import subprocess

    html_file = os.path.splitext(rmd_file)[0] + '.html'

    # Skip if HTML exists
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

    if result == 0:
        print(f"    -> {html_file}")
        return True
    else:
        print(f"    -> Failed!")
        return False

def main():
    print("=== Rmd to HTML Renderer ===")

    rmd_files = find_rmd_files()
    print(f"Found {len(rmd_files)} .Rmd files\n")

    rendered = 0
    for rmd_file in rmd_files:
        if render_html(rmd_file):
            rendered += 1

    print(f"\nDone! Rendered {rendered}/{len(rmd_files)} files")

if __name__ == "__main__":
    main()