# EXPORTS CONSOLIDATION GUIDE

## 🎯 Goal Achieved

All general-purpose environment exports are now consolidated in `exports.bash` for cleaner organization. Tool-specific exports (git, docker, pkg_aliases) remain in their respective files.

---

## 📋 Summary of Changes

### ✅ What's NOW in exports.bash (Consolidated)

All general environment variables in one place:

1. **LESS/PAGER** - Man page colors and pager settings
2. **LOCALE** - LANG, LC_ALL, LC_CTYPE, LC_COLLATE
3. **PATH** - All path additions consolidated (bin, local, snap, coffee, go)
4. **EDITOR/VISUAL** - Default editor settings
5. **TMUX_TMPDIR** - Tmux temp directory
6. **HISTORY** - HISTCONTROL, HISTIGNORE, HISTSIZE, HISTFILESIZE, HISTTIMEFORMAT
7. **TLDR** - TLDR client color settings
8. **USER DIRECTORIES** - DOTFILES_DIR, DOTFILES_REPO, CUSTOM_TMP, LOG_DIR (from variables.bash)
9. **UNAME SHORTCUTS** - uname_s, uname_n, uname_r, etc. (from variables.bash)

### ✅ What STAYS in Other Files (Tool-Specific)

**pkg_aliases.bash:**
- `ENABLE_SHORT_ALIASES` - Package alias configuration
- `SUDOCMD` - Sudo command detection
- `DISTROBASE` - Distribution detection
- `export -f` statements - Function exports

**git.bash:**
- No exports (all git aliases/functions, no env vars)

**docker.bash:**
- No exports (all docker aliases/functions, no env vars)

**colorcodes.bash:**
- No exports (defines color variables but doesn't export them)

### ❌ What's REMOVED (Duplicates)

**env.bash:**
- ❌ Removed: `export HISTIGNORE=...` (line 26) - Now in exports.bash

**variables.bash:**
- ❌ Removed: All exports (lines 29-42) - Moved to exports.bash
- ℹ️ File is now optional and can be deleted

**_bashrc:**
- ❌ Remove: `export PATH=$PATH:/home/patrick/go/bin` (line 381) - Already in exports.bash

---

## 📦 Files to Replace

### 1. exports.bash (CRITICAL - Must Replace)
```bash
# Backup wrong file
mv ~/dotfiles/.bashrc.d/exports.bash ~/dotfiles/.bashrc.d/exports.bash.WRONG.backup

# Install consolidated version
cp exports_CONSOLIDATED.bash ~/dotfiles/.bashrc.d/exports.bash
```

### 2. env.bash (Remove Duplicate)
```bash
# Backup current
cp ~/dotfiles/.bashrc.d/env.bash ~/dotfiles/.bashrc.d/env.bash.backup

# Install cleaned version
cp env_cleaned.bash ~/dotfiles/.bashrc.d/env.bash
```

### 3. variables.bash (Optional - Now Empty)
```bash
# Option A: Replace with simplified version
cp variables_cleaned.bash ~/dotfiles/.bashrc.d/variables.bash

# Option B: Delete entirely (recommended)
rm ~/dotfiles/.bashrc.d/variables.bash
# (Remember to remove from .bashrc loading list if deleted)
```

### 4. _bashrc (Remove Duplicate PATH)
```bash
# Edit ~/.bashrc and DELETE line 381:
# export PATH=$PATH:/home/patrick/go/bin

# This is already in exports.bash, so it's a duplicate
sed -i '/^export PATH=\$PATH:\/home\/patrick\/go\/bin$/d' ~/.bashrc
```

---

## 🔍 Verification After Changes

### Test 1: Check exports are loaded
```bash
source ~/.bashrc

# Test general exports
echo $EDITOR          # Should show: vim
echo $HISTSIZE        # Should show: 100000
echo $DOTFILES_DIR    # Should show: /home/patrick/dotfiles
echo $LANG            # Should show: en_US.UTF-8
echo $uname_s         # Should show: Linux

# Test PATH
echo $PATH | grep -o "$HOME/bin"        # Should find it
echo $PATH | grep -o "$HOME/go/bin"     # Should find it
```

### Test 2: Check aliases work
```bash
ll                    # Should work
gs                    # Git status (should work)
install htop          # Package alias (should work)
```

### Test 3: Check in TMUX
```bash
tmux
# Create new pane (Ctrl+b ")

# Prompt should show (colored)
# Aliases should work
ll
gs
install

# Exports should be inherited
echo $EDITOR
echo $DOTFILES_DIR
```

---

## 📊 Before vs After Structure

### BEFORE (Scattered Exports)

```
exports.bash (WRONG - was a .bashrc copy!)
  ❌ Prompt setup
  ❌ TMUX guard
  ❌ Everything...

env.bash
  ✓ Shell options
  ❌ HISTIGNORE export (duplicate)

variables.bash (interactive guard)
  ❌ DOTFILES_DIR, DOTFILES_REPO
  ❌ CUSTOM_TMP, LOG_DIR
  ❌ uname_* variables

_bashrc
  ❌ PATH=/home/patrick/go/bin (duplicate)

Result: Exports scattered, duplicates, broken loading
```

### AFTER (Clean Organization)

```
exports.bash (FIXED!)
  ✅ LESS/PAGER settings
  ✅ Locale settings
  ✅ PATH (consolidated)
  ✅ EDITOR/VISUAL
  ✅ TMUX_TMPDIR
  ✅ History settings
  ✅ TLDR settings
  ✅ User directories
  ✅ Uname shortcuts
  ❌ NO prompt setup (in .bashrc)
  ❌ NO TMUX guard (in .bashrc)

env.bash
  ✅ Shell options only
  ❌ No exports

variables.bash
  ✅ Optional/empty (can delete)
  ❌ No exports

_bashrc
  ✅ Prompt setup (before guard)
  ✅ TMUX guard
  ✅ Loading logic
  ❌ No duplicate PATH

Result: Clean, organized, everything works
```

---

## 🎯 Benefits of Consolidation

### Organization
- ✅ All environment exports in one place
- ✅ Easy to find and modify settings
- ✅ No duplicates
- ✅ Clear separation of concerns

### Performance
- ✅ Faster loading (no duplicates)
- ✅ Single source of truth
- ✅ No conflicting values

### Maintenance
- ✅ Easy to add new exports
- ✅ Easy to track what's exported
- ✅ Clear documentation
- ✅ Tool-specific exports stay with their tools

---

## 📝 File Structure Summary

### Core Files (NO GUARDS - Load Everywhere)
```
exports.bash   → All general environment exports
env.bash       → Shell options only (no exports)
functions.bash → Utility functions
pkg_aliases.bash → Package functions + pkg-specific exports
```

### Interactive Files (WITH GUARDS - Interactive Only)
```
git.bash       → Git aliases/functions (no exports)
aliases.bash   → General aliases (no exports)
docker.bash    → Docker aliases/functions (no exports)
colorcodes.bash → Color definitions (no exports)
variables.bash → Optional/empty (can delete)
profile.bash   → Login settings
logout.bash    → Exit handlers
```

---

## 🚀 Quick Migration Steps

```bash
# 1. Backup everything
cd ~/dotfiles/.bashrc.d
tar -czf backup-before-consolidation-$(date +%Y%m%d).tar.gz *.bash

# 2. Replace exports.bash (CRITICAL!)
mv exports.bash exports.bash.WRONG.backup
cp /path/to/exports_CONSOLIDATED.bash exports.bash

# 3. Replace env.bash
cp /path/to/env_cleaned.bash env.bash

# 4. Handle variables.bash (choose one)
# Option A: Replace
cp /path/to/variables_cleaned.bash variables.bash
# Option B: Delete
rm variables.bash

# 5. Fix .bashrc duplicate PATH
cd ~
cp .bashrc .bashrc.backup
sed -i '/^export PATH=\$PATH:\/home\/patrick\/go\/bin$/d' .bashrc

# 6. Test
source ~/.bashrc
echo "EDITOR: $EDITOR"
echo "HISTSIZE: $HISTSIZE"
ll

# 7. Test in tmux
tmux
# New pane
ll
echo $EDITOR
```

---

## ✅ Expected Result

**Terminal Start:**
- ✅ exports.bash loads → All env vars set
- ✅ env.bash loads → Shell options set
- ✅ functions.bash loads → Functions available
- ✅ pkg_aliases.bash loads → Package functions + distro detection
- ✅ aliases.bash loads → Aliases available
- ✅ Everything works!

**TMUX Panes:**
- ✅ Prompt shows (set in .bashrc before guard)
- ✅ TMUX guard activates (skips heavy loading)
- ✅ All exports inherited from parent
- ✅ All aliases inherited from parent
- ✅ Everything works!

**No Duplicates:**
- ✅ HISTIGNORE only in exports.bash
- ✅ PATH only modified in exports.bash
- ✅ All variables only exported once
- ✅ Clean, efficient loading

---

## 🎓 Why This Organization?

### Principle: "One Place, One Purpose"

**exports.bash** - Single source of truth for all general environment variables
- Easy to find settings
- Easy to modify
- No hunting through multiple files
- No duplicate definitions

**Other files** - Specific purposes
- env.bash → Shell behavior
- functions.bash → Utility functions
- pkg_aliases.bash → Package management + distro-specific
- aliases.bash → Convenience shortcuts

**Tool-specific files keep tool-specific settings**
- Docker exports (if any) → docker.bash
- Git exports (if any) → git.bash
- Package exports → pkg_aliases.bash

---

**Version:** 1.0  
**Date:** 2026-02-12  
**Status:** Ready for deployment
