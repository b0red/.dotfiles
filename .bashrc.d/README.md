# Dotfiles Configuration

A comprehensive, cross-platform dotfiles setup with modular bash configuration, visual loading feedback, universal package management, and automated installation.

## Features

- ðŸ”§ **Modular Configuration**: Split into logical files in `.bashrc.d/` with smart loading
- ðŸŽ¬ **Visual Loading Feedback**: See each file load with color-coded progress indicators
- ðŸ“¦ **Universal Package Management**: Unified `p_install`, `install`, `update`, `upgrade` commands across all distros
- ðŸŽ¨ **Smart Prompt**: Color-coded by privilege level (green for users, red for root)
- ðŸŽ¯ **Intelligent Backups**: Only backs up changed files, keeps pristine originals forever
- ðŸ—‘ï¸ **Automatic Cleanup**: Keeps only 3 most recent backup archives
- ðŸ”„ **Re-runnable**: Safe to run multiple times, skips unchanged files
- ðŸ“ **Comprehensive Logging**: Timestamped logs with color-coded output
- ðŸš€ **One-Command Setup**: `./RunMe.sh` does everything
- ðŸ’» **Cross-Platform**: Supports Debian, Ubuntu, RHEL, Fedora, Arch, Gentoo, Alpine, Void, NixOS, FreeBSD, OpenBSD, macOS
- ðŸ³ **Docker Integration**: Conditional loading - Docker shortcuts only appear when Docker is installed
- ðŸ” **Smart File Loading**: Core files load everywhere, interactive files only in interactive shells

## Quick Start

```bash
# Clone the repository
cd ~
git clone git@bitbucket.org:b0red/dotfiles.git ~/dotfiles
cd dotfiles

# Run the installer
./RunMe.sh
```

The script will:
1. Detect your OS and distribution
2. Backup existing dotfiles to `~/dotfiles/oldfiles/` (only if changed)
3. Create symlinks from `~/.bashrc`, `~/.profile`, etc. to repo files
4. Load package manager functions for your distro
5. Install essential applications from `.install_apps.inc`
6. Update git submodules
7. Clone additional repos (.tmux, .vim)
8. Create archived backups (tar.gz)
9. Clean up old archives (keeps 3 most recent)
10. Log everything to `~/dotfiles/logs/install-YYYY-MM-DD_HH-MM-SS.log`

## Visual Loading System

When you reload your shell, you'll see each file loading with visual feedback:

```bash
reload

# Output:
âœ“ Loading: exports.bash
âœ“ Loading: env.bash
âœ“ Loading: functions.bash
âœ“ Loading: pkg_aliases.bash
âœ“ Loading: git.bash
âœ“ Loading: docker.bash      # Only if Docker installed
âœ“ Loading: aliases.bash
âœ… All dotfiles loaded
```

**Configuration:**
- Adjust loading delay: Edit `BASHRC_LOAD_DELAY=1` in `~/.bashrc` (default: 1 second)
- Files show in upper-left corner with cursor positioning
- Green âœ“ for success, Red âœ— for errors
- Screen clears before and after loading for clean display

## Directory Structure

```
~/dotfiles/
â”œâ”€â”€ .bashrc                 # Main bash configuration (with smart recursion guard)
â”œâ”€â”€ .bash_profile           # Login shell config
â”œâ”€â”€ .profile                # POSIX shell config
â”œâ”€â”€ .inputrc                # Readline configuration
â”œâ”€â”€ .bashrc.d/              # Modular bash configs
â”‚   â”œâ”€â”€ Core Files (load everywhere - no guards):
â”‚   â”‚   â”œâ”€â”€ exports.bash        # Environment variables
â”‚   â”‚   â”œâ”€â”€ env.bash            # Shell options & settings
â”‚   â”‚   â”œâ”€â”€ functions.bash      # Utility functions
â”‚   â”‚   â””â”€â”€ pkg_aliases.bash    # Package manager abstraction
â”‚   â”‚
â”‚   â””â”€â”€ Interactive Files (interactive shells only - with guards):
â”‚       â”œâ”€â”€ aliases.bash        # Command aliases
â”‚       â”œâ”€â”€ git.bash            # Git shortcuts (50+ aliases)
â”‚       â”œâ”€â”€ docker.bash         # Docker shortcuts (conditional)
â”‚       â”œâ”€â”€ colorcodes.bash     # Color definitions
â”‚       â”œâ”€â”€ variables.bash      # Custom variables
â”‚       â”œâ”€â”€ profile.bash        # Login shell settings
â”‚       â””â”€â”€ logout.bash         # Exit handlers
â”‚
â”œâ”€â”€ .profile.d/             # POSIX shell modules
â”‚   â”œâ”€â”€ browser.sh
â”‚   â”œâ”€â”€ pager.sh
â”‚   â””â”€â”€ timezone.sh
â”œâ”€â”€ .install_apps.inc       # List of applications to install
â”œâ”€â”€ oldfiles/               # Backup directory (pristine originals - never deleted)
â”œâ”€â”€ logs/                   # Installation logs
â”‚   â””â”€â”€ install-*.log
â”œâ”€â”€ backup-*.tar.gz         # Archive backups (auto-culled to 3 most recent)
â”œâ”€â”€ RunMe.sh                # Installation script
â”œâ”€â”€ diagnose-dotfiles.sh    # Diagnostic tool
â””â”€â”€ README.md               # This file
```

## File Loading Architecture

### Core Files (No Guards - Load Everywhere)
These files load in **both interactive and non-interactive contexts** (scripts, RunMe.sh, etc.):

- **exports.bash** - Environment variables, PATH setup
- **env.bash** - Shell options (shopt), history configuration
- **functions.bash** - Utility functions available everywhere
- **pkg_aliases.bash** - Package management functions (`p_*` functions)

**Why no guards?** Scripts need these core features to work properly.

### Interactive Files (With Guards - Interactive Only)
These files only load in **interactive shells** (your terminal):

- **aliases.bash** - User convenience aliases
- **git.bash** - Git workflow shortcuts
- **docker.bash** - Docker shortcuts (only loads if Docker installed)
- **colorcodes.bash** - Color code definitions
- **variables.bash** - Custom user variables
- **profile.bash** - Login shell settings
- **logout.bash** - Session cleanup handlers

**Why guards?** Aliases don't work in scripts anyway, and these are user convenience features.

### Conditional Loading: Docker Integration

The `docker.bash` file uses **two-stage loading**:

1. **First check**: Is Docker installed? (If no, skip entirely)
2. **Second check**: Is shell interactive? (If no, skip)

This means:
- âœ… Docker installed + Interactive shell = Docker shortcuts available
- âŒ Docker not installed = No Docker shortcuts, no clutter
- âŒ Non-interactive script = Docker shortcuts don't load

## Installation Options

```bash
./RunMe.sh                  # Normal installation
./RunMe.sh --help           # Show help message
./RunMe.sh --version        # Show version
./RunMe.sh --revert         # Revert changes (restore backups)
./RunMe.sh --debug          # Enable debug mode
./RunMe.sh --trace          # Enable trace mode (set -x)
DEBUG=1 ./RunMe.sh          # Debug with environment variable
TRACE_DEBUG=1 ./RunMe.sh    # Trace with environment variable
```

## Package Manager Commands

After installation, these commands work across **all supported distros**:

### Function-Based (Work Everywhere)
Use these in scripts, RunMe.sh, and interactive shells:

```bash
p_install <pkg>      # Install package(s)
p_remove <pkg>       # Remove package(s)
p_update             # Refresh package lists
p_upgrade            # Install all updates
p_search <query>     # Search for packages
p_clean              # Remove orphans & cache
p_info <pkg>         # Show package details
```

### Alias-Based (Interactive Only)
Convenient shortcuts for interactive use:

| Command | Description | Example |
|---------|-------------|---------|
| `install <pkg>` | Install package(s) | `install vim htop` |
| `remove <pkg>` | Remove package(s) | `remove vim` |
| `uninstall <pkg>` | Alias for remove | `uninstall vim` |
| `update` | Refresh package lists | `update` |
| `upgrade` | Install all updates | `upgrade` |
| `search <query>` | Search for packages | `search python` |
| `clean` | Remove orphans & cache | `clean` |
| `info <pkg>` | Show package details | `info vim` |
| `version` | Show system info | `version` |

**Note:** In scripts (like RunMe.sh), use `p_install` instead of `install` to avoid conflicts with `/usr/bin/install`.

### Supported Distributions

- **Debian/Ubuntu**: apt-get
- **RHEL/Fedora/CentOS/AlmaLinux**: dnf/yum
- **Arch/Manjaro**: pacman
- **Gentoo**: emerge
- **Alpine**: apk
- **Void Linux**: xbps
- **NixOS**: nix-env
- **FreeBSD**: pkg
- **OpenBSD**: pkg_add
- **macOS**: Homebrew (if installed)

## Daily Usage

### Installing Applications

Applications are defined in `.install_apps.inc`:

```bash
# Edit the file to add/remove apps
vim ~/dotfiles/.install_apps.inc

# Add one app per line, comments allowed
curl
htop
vim
# tmux  <- commented out, won't install
```

Then run `./RunMe.sh` again - it will only install missing packages.

### Package Management Examples

```bash
# Install packages (works on any distro)
install neofetch htop           # Interactive shell
p_install neofetch htop         # Scripts or interactive

# Update system
update && upgrade

# Search for packages
search python

# Clean up
clean

# Show system info
version
```

### Reloading Configuration

The `.bashrc` includes a smart recursion guard that allows re-sourcing up to 3 times:

```bash
# Quick reload (with visual feedback)
reload

# Expected output:
# âœ“ Loading: exports.bash
# âœ“ Loading: env.bash
# ... (all files load)
# âœ… All dotfiles loaded

# Or manually
source ~/.bashrc

# Or restart your shell
exec bash
```

### Docker Commands (If Docker Installed)

When Docker is installed, you get 40+ shortcuts automatically:

```bash
dps              # docker ps
dcp              # docker compose
dex <container>  # docker exec -it <container> /bin/sh
dkln <container> # Follow logs for container
dclean           # Clean dangling images/volumes
```

If Docker is **not** installed, these aliases simply don't exist - keeping your shell clean.

## Smart Backup System

### How Backups Work

1. **First Run**: Creates pristine originals in `oldfiles/`
   - Files: `.bashrc.bak-2026-01-20_10-00-00`
   - These are **NEVER** deleted - they're your restoration point

2. **Subsequent Runs**: 
   - Compares files byte-by-byte with repo versions
   - Only backs up if changed (skips unnecessary backups)
   - Creates tar.gz archive: `backup-HOSTNAME-DATE.tar.gz`

3. **Automatic Cleanup**:
   - Keeps pristine originals forever
   - Keeps only 3 most recent tar.gz archives
   - Deletes older archives automatically

### Backup Output Example

```bash
Backing up existing dotfiles...
â­ï¸  Skipping /home/user/.bashrc (unchanged from repo)
âœ“ Backed up: /home/user/.profile
Backed up 1 files to /home/user/dotfiles/oldfiles/
Skipped 1 unchanged files

âœ“ Archived backups: backup-DESKTOP-JLMCRD0-2026-01-20_10-30-00.tar.gz

Cleaning up old backup archives (keeping 3 most recent)...
ðŸ—‘ï¸  Deleted old archive: backup-DESKTOP-JLMCRD0-2026-01-10_10-00-00.tar.gz
âœ“ Cleaned up 1 old archive(s), kept 3 most recent
```

## Color-Coded Prompt

The prompt automatically adjusts based on privilege level:

- **Green prompt**: Normal user
  ```
  user@hostname:~/path$ 
  ```

- **Red prompt**: Root/privileged user
  ```
  root@hostname:~/path# 
  ```

The prompt checks multiple conditions:
- EUID = 0
- USER/LOGNAME = root
- Optional: sudo/wheel/admin group membership (commented by default)

## Diagnostic Tool

Check your dotfiles configuration status:

```bash
cd ~/dotfiles
bash diagnose-dotfiles.sh

# Output shows:
# - Which files exist
# - Guard status (which files have interactive guards)
# - Docker check status
# - Current shell state
# - Package functions availability
# - Common issues detected
```

## Reverting Changes

### Automatic Revert

```bash
./RunMe.sh --revert
```

This will:
- Restore original dotfiles from `oldfiles/` backups
- Remove all symlinks created by the installer
- Show summary of restored files and removed symlinks
- Leave installed packages in place

### Manual Revert

If `--revert` doesn't work or you need more control:

1. **Restore backups manually:**
   ```bash
   cd ~/dotfiles/oldfiles/
   
   # Find your pristine backups (earliest .bak-* files)
   ls -lt *.bak-* | tail -n 4
   
   # Restore them
   for f in .bashrc.bak-* .profile.bak-* .bash_profile.bak-* .inputrc.bak-*; do
       [ -f "$f" ] || continue
       # Take the earliest backup (pristine original)
       original=$(echo "$f" | sed 's/\.bak-.*$//')
       cp "$f" ~/"$original"
       echo "Restored: $original"
   done
   ```

2. **Remove symlinks:**
   ```bash
   cd ~
   rm -f .bashrc .bash_profile .profile .inputrc
   ```

3. **Delete dotfiles repo** (optional):
   ```bash
   rm -rf ~/dotfiles
   ```

4. **Restart shell:**
   ```bash
   exec bash
   ```

## Customization

### Adding Your Own Aliases

Edit or create `~/.bashrc.d/extra_alias.bash`:

```bash
# My custom aliases
alias mycommand='echo "Hello World"'
alias ll='ls -lah'
alias ..='cd ..'
```

### Adding Environment Variables

Edit `~/.bashrc.d/exports.bash`:

```bash
export MY_VAR="my_value"
export PATH="$HOME/bin:$PATH"
export EDITOR="vim"
```

### Adding Custom Functions

Edit `~/.bashrc.d/functions.bash`:

Adding the tree "`###`" under the function name with a description makes it show up when you run the `functions` command:

```bash
function my_function() {
    ### Short informative description of what this does
    echo "This is my function"
    # Your code here
}
```

Then run `functions` to see all available functions with descriptions, or `functions -?` for detailed help.

### Modifying Package Manager Behavior

Edit `~/.bashrc.d/pkg_aliases.bash` to customize package commands or add new distros.

### Customizing Application List

Edit `.install_apps.inc`:

```bash
# Core utilities
curl
wget
git

# Development tools
vim
tmux
htop

# Optional (comment out to skip)
# docker
# python3

# One app per line, # for comments
```

### Adjusting Visual Loading Speed

Edit `~/.bashrc`:

```bash
# Change this value (in seconds)
BASHRC_LOAD_DELAY=1     # Default (1 second per file)
BASHRC_LOAD_DELAY=0.5   # Faster
BASHRC_LOAD_DELAY=0.2   # Very fast
BASHRC_LOAD_DELAY=2     # Slower (more visible)
```

## Troubleshooting

### Colors Not Showing

Check if your terminal supports colors:
```bash
echo -e "\033[0;32mGreen\033[0m \033[0;31mRed\033[0m"
```

If no colors appear, your terminal might not support ANSI colors. Try a different terminal emulator.

### Package Functions Not Working in Scripts

Make sure you're using `p_install` not `install` in scripts:

```bash
# âŒ Wrong (in scripts)
install htop

# âœ… Correct (in scripts)
p_install htop

# âœ… Both work (in interactive shell)
install htop
p_install htop
```

### Docker Shortcuts Not Appearing

Docker shortcuts only load if Docker is installed. Check:

```bash
# Is Docker installed?
command -v docker

# If not installed:
p_install docker.io  # Ubuntu/Debian
p_install docker     # Other distros

# Then reload
reload
```

### Aliases Not Working

```bash
# Check if pkg_aliases.bash is sourced
declare -f p_install

# If "not found", manually source:
source ~/dotfiles/.bashrc.d/pkg_aliases.bash

# Then reload bashrc
reload
```

### "Recursion Guard" Preventing Re-source

The `.bashrc` allows re-sourcing up to 3 times per session. If you hit the limit:

```bash
# Reset the counter
BASHRC_SOURCED=0
source ~/.bashrc

# Or use the reload alias (does this automatically)
reload
```

### Symlinks Not Created

```bash
# Check if files exist in repo
ls -la ~/dotfiles/.bashrc

# Check if symlink exists
ls -la ~/.bashrc

# Manually create symlink if needed
ln -sf ~/dotfiles/.bashrc ~/.bashrc
```

### Package Installation Fails

1. Check your internet connection
2. Update package lists manually:
   ```bash
   sudo apt-get update  # Debian/Ubuntu
   sudo dnf check-update  # Fedora/RHEL
   ```
3. Check the log file:
   ```bash
   tail -f ~/dotfiles/logs/install-*.log
   ```
4. Try installing packages manually:
   ```bash
   sudo apt-get install -y curl htop vim
   ```

### Visual Loading Not Showing

Make sure you're in an **interactive** shell:

```bash
# Check if interactive
echo $-
# Should contain 'i' for interactive

# Loading feedback only shows in interactive mode
# Scripts run non-interactively and don't show feedback
```

### "Unknown OS" Error

Your distribution isn't detected. Edit `pkg_aliases.bash` and add your distro to the case statement:

```bash
case "$DISTROBASE" in
    yourdistro*)
        p_install() { sudo your-pkg-manager install "$@"; }
        p_remove() { sudo your-pkg-manager remove "$@"; }
        p_update() { sudo your-pkg-manager update; }
        p_upgrade() { sudo your-pkg-manager upgrade; }
        p_search() { your-pkg-manager search "$@"; }
        p_clean() { sudo your-pkg-manager autoremove; }
        p_info() { your-pkg-manager info "$@"; }
        ;;
```

### Files Loading Twice

Run the diagnostic:
```bash
bash ~/dotfiles/diagnose-dotfiles.sh
```

Check for duplicate loading loops in `.bashrc`. Should only have 3 loading sections.

## Advanced Configuration

### WSL-Specific Setup

The installer automatically configures `.bash_profile` to load `.bashrc` for WSL compatibility. No additional setup needed.

### Tmux Integration

The script automatically:
- Clones tmux configuration from Bitbucket
- Installs Coffee plugin manager
- Creates symlink for `.tmux.conf`

Inside tmux:
```bash
# Press: prefix + I (capital i) to install plugins
# Default prefix is Ctrl+b
```

### SSH Key Management

The `.bashrc` includes keychain integration for SSH keys. Install keychain:
```bash
install keychain
```

The script automatically detects and loads SSH keys:
- `~/.ssh/id_ed25519` (preferred)
- `~/.ssh/id_rsa`
- `~/.ssh/id_ecdsa`
- `~/.ssh/id_dsa`

### Vim Setup

The script clones your vim configuration:
```bash
# Automatically cloned to ~/.vim
# Symlinks ~/.vimrc to ~/.vim/.vimrc
```

## Maintenance

### Updating Dotfiles

```bash
cd ~/dotfiles
git pull origin main
reload  # Reload configuration with visual feedback
```

### Backing Up Current Config

```bash
cd ~/dotfiles
git add -A
git commit -m "Update configuration"
git push
```

### Cleaning Up Old Backups

The script automatically:
- Keeps pristine originals in `oldfiles/` **forever**
- Keeps only 3 most recent `backup-*.tar.gz` archives

To manually clean archives:
```bash
# Remove all but 3 newest archives
cd ~/dotfiles
ls -t backup-*.tar.gz | tail -n +4 | xargs rm -f
```

### Viewing Logs

```bash
# View latest log
tail -f ~/dotfiles/logs/install-*.log

# View all logs
ls -lth ~/dotfiles/logs/

# Clean old logs (older than 30 days)
find ~/dotfiles/logs -name "*.log" -mtime +30 -delete
```

## Script Output

### Success Messages (Green âœ“)
- File backups
- Symlink creation
- Package installations
- Archive creation
- File loading progress

### Info/Warning Messages (Yellow âš ï¸)
- Skipped unchanged files
- Missing optional files
- Warnings about system state

### Error Messages (Red âœ—)
- Failed operations
- Missing required files
- Permission issues
- Failed file loads

Example output:
```bash
=========================================
Starting Dotfiles Installation
Version: v15.1.0 (2026-01-20)
=========================================
ðŸŽ¨ Color output enabled
Detected: OS=linux, Distro=ubuntu, Base=ubuntu, Kernel=5.15.0, Arch=x86_64
âœ… Package functions configured for ubuntu
âœ“ Loaded 15 applications from .install_apps.inc

ðŸ”“ Checking sudo access (you may be prompted for password)...
âœ“ Sudo access verified

Backing up existing dotfiles...
â­ï¸  Skipping /home/user/.bashrc (unchanged from repo)
âœ“ Backed up: /home/user/.profile
Backed up 1 files to /home/user/dotfiles/oldfiles/
Skipped 1 unchanged files
```

## Files Modified by Installer

The installer creates/modifies these files in your home directory:

- `~/.bashrc` â†’ symlink to `~/dotfiles/.bashrc`
- `~/.bash_profile` â†’ symlink to `~/dotfiles/.bash_profile`
- `~/.profile` â†’ symlink to `~/dotfiles/.profile`
- `~/.inputrc` â†’ symlink to `~/dotfiles/.inputrc`
- `~/.tmux.conf` â†’ symlink to `~/.tmux/.tmux.conf`
- `~/.vimrc` â†’ symlink to `~/.vim/.vimrc`

Original files are backed up to `~/dotfiles/oldfiles/` with timestamps.

## Security Notes

- ðŸ”’ The installer never modifies system files (only user home directory)
- ðŸ”‘ Sudo is only used for package installation
- ðŸ’¾ All changes are logged to timestamped log files
- ðŸ”„ Original files are backed up before any changes
- âš ï¸ Review `RunMe.sh` before running if you're security-conscious
- ðŸ›¡ï¸ Script includes recursion guard to prevent infinite loops
- âœ… All file operations include error checking
- ðŸŽ¯ Core files load in all contexts, interactive files guarded
- ðŸ³ Docker shortcuts only load when Docker is installed

## Architecture Benefits

### Why Split Core and Interactive Files?

**Core files (no guards):**
- Scripts like `RunMe.sh` need package management functions
- Environment variables needed everywhere
- Shell options improve script reliability
- Utility functions used by automation

**Interactive files (with guards):**
- Aliases don't work in scripts anyway
- User convenience features not needed in automation
- Reduces overhead for non-interactive contexts
- Prevents unexpected behavior in scripts

### Function Export Pattern

```bash
# In pkg_aliases.bash
p_install() { sudo apt-get install -y "$@"; }  # Function
export -f p_install                            # Export for scripts

# In interactive shells only
if [[ $- == *i* ]]; then
    alias install='p_install'                  # Convenient alias
fi
```

**Result:**
- `p_install` works in scripts âœ“
- `p_install` works interactively âœ“
- `install` works interactively âœ“
- `install` doesn't interfere with `/usr/bin/install` in scripts âœ“

## Version History

- **v15.1.0** (2026-01-20)
  - **NEW**: Visual loading feedback with cursor positioning
  - **NEW**: Conditional Docker loading (only if Docker installed)
  - **NEW**: Smart file loading architecture (core vs interactive)
  - **NEW**: Diagnostic tool (`diagnose-dotfiles.sh`)
  - **IMPROVED**: Package management with `p_*` functions and aliases
  - **IMPROVED**: Cross-distro support with proper distro detection
  - **IMPROVED**: Function exports for script compatibility
  - **FIXED**: Guard logic - core files load everywhere, interactive files guarded
  - **FIXED**: Docker shortcuts don't clutter shell when Docker not installed
  - Configurable loading delay
  - Better error handling in shopt commands
  - Enhanced README with architecture documentation

- **v15.0.0** (2026-01-16)
  - Added version support (`--version` flag)
  - Smart backup system (only backs up changed files)
  - Automatic cleanup (keeps 3 most recent archives)
  - Color-coded output (green/yellow/red)
  - Improved error handling throughout
  - Smart recursion guard in `.bashrc`
  - Privilege-aware prompt colors

## Getting Help

1. **Check diagnostic**: `bash ~/dotfiles/diagnose-dotfiles.sh`
2. **Check logs**: `~/dotfiles/logs/install-*.log`
3. **Review this README**: Most issues are covered above
4. **Check bash syntax**: `bash -n ~/.bashrc`
5. **Test in debug mode**: `DEBUG=1 ./RunMe.sh`
6. **Test in trace mode**: `TRACE_DEBUG=1 ./RunMe.sh`
7. **Check version**: `./RunMe.sh --version`
8. **Check loading**: `reload` (should show visual feedback)

## License

[Your license here - MIT recommended]

## Credits & Inspiration

Some links to where I've ~~stolen~~ borrowed stuff & inspiration from:

* [Shell Config Subfiles](https://sanctum.geek.nz/arabesque/shell-config-subfiles/)
* [CLI Improved](https://remysharp.com/2018/08/23/cli-improved)
* [kenorb/dotfiles Functions](https://github.com/kenorb/dotfiles/blob/master/.bash_functions)
* [kenorb/dotfiles Aliases](https://github.com/kenorb/dotfiles/blob/master/.bash_aliases)
* [sharkdp/bat](https://github.com/sharkdp/bat/)
* [prettyping](https://github.com/denilsonsa/prettyping.git) â†’ `~/dotfiles/extras/prettyping`

Created and maintained by **Patrick Ã–sterlund**. 

If you find this useful, consider supporting: [[PayPal](https://paypal.me/fotosbypatrick)]

---

**Last Updated**: February 16, 2026  
**Script Version**: v15.5.0