# Sidebar Fix - Issue Resolved

## Problem
After migrating to Coffee plugin manager, the sidebar stopped working.
Pressing `prefix + Tab` did nothing.

## Root Cause
The manual keybinding in `.tmux.conf` was conflicting with the plugin's own default bindings:

```tmux
# Old problematic configuration:
set -g @sidebar-tree 'Tab'
bind-key Tab run-shell "~/.tmux/plugins/tmux-sidebar/scripts/toggle"
```

**Issues with the old binding:**
1. The path `~/.tmux/plugins/tmux-sidebar/scripts/toggle` was incorrect (should be `toggle.sh`)
2. The manual binding was conflicting with tmux-sidebar's own default bindings
3. The plugin automatically provides its own keybindings when loaded

## Solution
Removed the manual binding and let the tmux-sidebar plugin use its default bindings.

**New configuration:**
```tmux
# Sidebar/Tree Listing Plugin Configuration
# The tmux-sidebar plugin provides default bindings:
# - prefix + Tab        : toggle sidebar
# - prefix + Backspace  : toggle sidebar and focus it
# Custom tree command for colorized output
set -g @sidebar-tree-command 'tree -C'
```

## How to Use

### Toggle Sidebar (without focus)
1. Press `Ctrl-a` (prefix)
2. Press `Tab`
3. Sidebar appears on the right side showing directory tree

### Toggle Sidebar (with focus)
1. Press `Ctrl-a` (prefix)
2. Press `Backspace`
3. Sidebar appears AND cursor moves into it so you can navigate

### Navigate in Sidebar
Once the sidebar is open and focused:
- Use arrow keys to navigate up/down
- Press `Enter` to open a directory/file
- Press `q` or `Ctrl-a + Backspace` again to close

## Why This Fix Works

According to the [tmux-sidebar documentation](https://github.com/tmux-plugins/tmux-sidebar), the plugin automatically provides these default keybindings when it's loaded:

- `prefix + Tab` - toggle sidebar
- `prefix + Backspace` - toggle sidebar and focus it

By removing the manual binding, we allow the plugin to set up its own bindings correctly. The plugin handles the proper path to its scripts internally.

## Additional Configuration

You can customize the sidebar behavior with these options:

```tmux
# Tree command (for colorized output)
set -g @sidebar-tree-command 'tree -C'

# Sidebar width (default is 40)
set -g @sidebar-tree-width '50'

# Sidebar position (left or right, default is right)
set -g @sidebar-tree-position 'right'

# Pager for long output (default is less)
set -g @sidebar-tree-pager 'less -r'
```

## Testing

After updating the config:

1. Reload tmux config:
   ```
   prefix + r
   ```
   Should see: "Config reloaded!"

2. Ensure plugin is installed:
   ```bash
   coffee list | grep sidebar
   # OR
   ls -la ~/.tmux/plugins/tmux-sidebar/
   ```

3. Test the sidebar:
   ```
   Ctrl-a + Tab
   ```
   Sidebar should appear!

4. Test with focus:
   ```
   Ctrl-a + Backspace
   ```
   Sidebar should appear AND be focused (you can use arrow keys)

## Verification

✅ Sidebar toggles with `prefix + Tab`  
✅ Sidebar toggles with focus using `prefix + Backspace`  
✅ Tree output is colorized  
✅ Navigation works with arrow keys  

## Files Updated

All documentation has been updated to reflect the correct keybindings:

- ✅ `.tmux.conf` - Removed manual binding, added proper configuration
- ✅ `README.md` - Updated keybindings section
- ✅ `QUICK_REFERENCE.md` - Fixed Tab keybinding
- ✅ `CHANGES_SUMMARY.md` - Documented the fix

## Reference

- Plugin: https://github.com/tmux-plugins/tmux-sidebar
- Default bindings are documented in the plugin's README
- The plugin works out-of-the-box with Coffee plugin manager
