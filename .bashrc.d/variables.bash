#!/usr/bin/env bash
# =================================================================================================
# variables.bash - Custom Variables & Settings
# =================================================================================================
# Purpose: Optional user-defined variables and custom settings
# Dependencies: None
# 
# 🔒 INTERACTIVE ONLY - This file contains optional customizations
# 
# NOTE: All environment exports have been moved to exports.bash for cleaner organization.
#       This file is now optional and can be deleted if not needed.
# =================================================================================================

# =============================================================================
# INTERACTIVE SHELL GUARD
# =============================================================================
[[ $- == *i* ]] || return 0

# =============================================================================
# OPTIONAL: Add any interactive-only custom variables here
# =============================================================================
# All the original exports (DOTFILES_DIR, uname_* variables, etc.) have been
# moved to exports.bash for better organization.
#
# You can add new interactive-only variables here if needed, or delete this file.

# End of variables.bash (now optional - can be deleted)
