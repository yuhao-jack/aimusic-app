#!/usr/bin/env python3
"""
音浪AI UI Refactoring Script
Replaces old color references with new AppTheme constants across all page files.
"""
import os
import re

PROJECT_ROOT = "/Users/yuhao/.openclaw/jarvis-workspace/aimusic-app/frontend"
MODULES_DIR = os.path.join(PROJECT_ROOT, "lib", "modules")
THEME_FILE = os.path.join(PROJECT_ROOT, "lib", "theme", "app_theme.dart")

# Files to process
PAGE_FILES = []
for root, dirs, files in os.walk(MODULES_DIR):
    for f in files:
        if f.endswith("_page.dart"):
            PAGE_FILES.append(os.path.join(root, f))
        elif f.endswith("_controller.dart"):
            PAGE_FILES.append(os.path.join(root, f))

# Also include the theme file
PAGE_FILES.append(THEME_FILE)
PAGE_FILES.append(os.path.join(PROJECT_ROOT, "lib", "theme", "theme_config.dart"))

def make_replacements(content, filepath):
    """Apply all UI replacements to the content."""
    
    # 1. Replace Colors.white (but NOT Colors.white10/12/24/30/38/54/60/70/87 or withOpacity/withAlpha)
    # Pattern: Colors.white (followed by a non-word char that isn't a digit)
    content = re.sub(
        r'Colors\.white(?![\w])',
        'AppTheme.textWhite',
        content
    )
    # But revert false positives: AppTheme.textWhite10 etc don't exist
    # Fix AppTheme.textWhite.withOpacity -> keep original
    content = re.sub(
        r'AppTheme\.textWhite\.withOpacity',
        'Colors.white.withOpacity',
        content
    )
    content = re.sub(
        r'AppTheme\.textWhite\.withValues',
        'Colors.white.withValues',
        content
    )
    
    # 2. Colors.white30/white60 etc should stay as Colors (no AppTheme equivalent)
    content = re.sub(
        r'AppTheme\.textWhite(\d+)',
        r'Colors.white\1',
        content
    )
    
    # 3. Fix AppTheme.textWhite30 back to Colors.white30
    content = re.sub(
        r'AppTheme\.textWhite(1[024]|2[04]|3[08]|5[48]|6[04]|7[08]|87)',
        r'Colors.white\1',
        content
    )
    
    # 4. Replace Colors.whiteText -> shouldn't happen but just in case
    content = re.sub(
        r'Colors\.whiteText',
        'AppTheme.textWhite',
        content
    )
    
    # 5. Replace old purple hex
    content = content.replace('Color(0xFF6366F1)', 'AppTheme.brandPurple')
    
    # 6. Replace old pink hex (but only when it's a standalone color ref, not in a gradient list)
    content = content.replace('Color(0xFFF472B6)', 'AppTheme.brandPink')
    
    # 7. Replace grey[500] etc with AppTheme equivalents
    content = re.sub(
        r'Colors\.grey\[500\]',
        'AppTheme.textDarkGray',
        content
    )
    content = re.sub(
        r'Colors\.grey\[400\]',
        'AppTheme.textMediumGray',
        content
    )
    content = re.sub(
        r'Colors\.grey',
        'AppTheme.textDarkGray',
        content
    )
    # Fix any over-fixes
    content = re.sub(
        r'AppTheme\.textDarkGray\[500\]',
        'AppTheme.textDarkGray',
        content
    )
    content = re.sub(
        r'AppTheme\.textDarkGray\[400\]',
        'AppTheme.textMediumGray',
        content
    )
    
    # 8. Replace black54/black38/black87 with AppTheme equivalents where appropriate
    content = content.replace('Colors.black54', 'AppTheme.textLightGray')
    content = content.replace('Colors.black38', 'AppTheme.textMuted')
    content = content.replace('Colors.black87', 'AppTheme.textWhite')
    
    # 9. Fix nearBlack references for scaffold backgrounds -> surface1 (deepest)
    # But not all nearBlack usages should change (e.g., gradient colors, gradient stops)
    # We'll handle this on a per-file basis
    
    # 10. Replace darkSurface references to surface3 (card surfaces)
    content = content.replace('AppTheme.darkSurface', 'AppTheme.surface3')
    
    # 11. Replace midDark references to surface3 (interactive zones)
    content = content.replace('AppTheme.midDark', 'AppTheme.surface3')
    
    # 12. Replace darkCardElevated to surfaceElevated 
    content = content.replace('AppTheme.darkCardElevated', 'AppTheme.surfaceElevated')
    
    # 13. Fix old DarkGray references to new naming
    # textDarkGray -> textMuted (more descriptive)
    # Actually, let's keep textDarkGray as-is since it IS defined and used throughout
    # textLightGray -> textTertiary? Let's check the DESIGN.md colors
    # DESIGN says: textWhite, textSilver, textTertiary(#8E8E93), textMuted(#6B7280)
    # But AppTheme.textLightGray = 0xFF9CA3AF, AppTheme.textDarkGray = 0xFF4B5563
    # These don't exactly match the design spec values. Let's keep them as-is.
    
    return content


def process_file(filepath):
    """Process a single file with replacements."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    content = make_replacements(content, filepath)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False


def main():
    modified = []
    
    for filepath in sorted(PAGE_FILES):
        if not os.path.exists(filepath):
            print(f"  SKIP (not found): {filepath}")
            continue
        
        relative = os.path.relpath(filepath, PROJECT_ROOT)
        if process_file(filepath):
            modified.append(relative)
            print(f"  MODIFIED: {relative}")
    
    print(f"\nTotal modified files: {len(modified)}")
    for m in modified:
        print(f"  - {m}")


if __name__ == "__main__":
    main()
