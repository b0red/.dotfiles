# Dotfiles Configuration

A comprehensive, cross-platform dotfiles setup with modular bash configuration, package manager abstraction, and automated installation.

## Features

- 🔧 **Modular Configuration**: Split into logical files in `.bashrc.d/`
- 📦 **Universal Package Management**: Unified `install`, `update`, `upgrade` commands across all distros
- 🎨 **Smart Prompt**: Color-coded by privilege level (green for users, red for root)
- 🎯 **Intelligent Backups**: Only backs up changed files, keeps pristine originals forever
- 🗑️ **Automatic Cleanup**: Keeps only 3 most recent backup archives
- 🔄 **Re-runnable**: Safe to run multiple times, skips unchanged files
- 📝 **Comprehensive Logging**: Timestamped logs with color-coded output
- 🚀 **One-Command Setup**: `./RunMe.sh` does everything
- 💻 **Cross-Platform**: Supports Debian, Ubuntu, RHEL, Fedora, Arch, Gentoo, Alpine, NixOS, FreeBSD, OpenBSD, macOS

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
7. Clone additional repos (.tmux, .vim, tpm)
8. Create archived backups (tar.gz)
9. Clean up old archives (keeps 3 most recent)
10. Log everything to `~/dotfiles/logs/install-YYYY-MM-DD_HH-MM-SS.log`

## Directory Structure

```
~/dotfiles/
├── .bashrc                 # Main bash configuration (with smart recursion guard)
├── .bash_profile           # Login shell config
├── .profile                # POSIX shell config
├── .inputrc                # Readline configuration
├── .bashrc.d/              # Modular bash configs
│   ├── aliases.bash        # Command aliases
│   ├── colorcodes.bash     # Color definitions
│   ├── docker.bash         # Docker shortcuts
│   ├── env.bash            # Environment setup
│   ├── exports.bash        # Environment variables
│   ├── functions.bash      # Custom functions
│   ├── git.bash            # Git aliases/functions
│   ├── pkg_aliases.bash    # Package manager functions
│   └── variables.bash      # Variable definitions
├── .profile.d/             # POSIX shell modules
│   ├── browser.sh
│   ├── pager.sh
│   └── timezone.sh
├── .install_apps.inc       # List of applications to install
├── oldfiles/               # Backup directory (pristine originals - never deleted)
├── logs/                   # Installation logs
│   └── install-*.log
├── backup-*.tar.gz         # Archive backups (auto-culled to 3 most recent)
├── RunMe.sh                # Installation script
└── README.md               # This file
```

## Installation Options

```bash
./RunMe.sh                  # Normal installation
./RunMe.sh --help           # Show help message
./RunMe.sh --version        # Show version (v1.0.1)
./RunMe.sh --revert         # Revert changes (restore backups)
./RunMe.sh --debug          # Enable debug mode
./RunMe.sh --trace          # Enable trace mode (set -x)
DEBUG=1 ./RunMe.sh          # Debug with environment variable
TRACE_DEBUG=1 ./RunMe.sh    # Trace with environment variable
```

## Package Manager Commands

After installation, these commands work across **all supported distros**:

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

### Supported Distributions

- **Debian/Ubuntu**: apt-get
- **RHEL/Fedora/CentOS/AlmaLinux**: dnf/yum
- **openSUSE**: zypper
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

### Package Management

```bash
# Install packages (works on any distro)
install neofetch htop

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
# Quick reload
reload           # Uses the built-in alias

# Or manually
source ~/.bashrc

# Or restart your shell
exec bash
```

## Smart Backup System

### How Backups Work

1. **First Run**: Creates pristine originals in `oldfiles/`
   - Files: `.bashrc.bak-2026-01-15_10-00-00`
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
⏭️  Skipping /home/user/.bashrc (unchanged from repo)
✓ Backed up: /home/user/.profile
Backed up 1 files to /home/user/dotfiles/oldfiles/
Skipped 1 unchanged files

✓ Archived backups: backup-DESKTOP-JLMCRD0-2026-01-16_10-30-00.tar.gz

Cleaning up old backup archives (keeping 3 most recent)...
🗑️  Deleted old archive: backup-DESKTOP-JLMCRD0-2026-01-10_10-00-00.tar.gz
✓ Cleaned up 1 old archive(s), kept 3 most recent
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

Adding the tree "`###`" under the function name with a description makes it show up when you run the `function` command:

```bash
function my_function() {
    ### Short informative description of what this does
    echo "This is my function"
    # Your code here
}
```

Then run `function` to see all available functions with descriptions.

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

## Troubleshooting

### Colors Not Showing

Check if your terminal supports colors:
```bash
echo -e "\033[0;32mGreen\033[0m \033[0;31mRed\033[0m"
```

If no colors appear, your terminal might not support ANSI colors. Try a different terminal emulator.

### Aliases Not Working

```bash
# Check if pkg_aliases.bash is sourced
type install

# If "not found", manually source:
source ~/dotfiles/.bashrc.d/pkg_aliases.bash
set_package_aliases

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

### "Unknown OS" Error

Your distribution isn't detected. Edit `pkg_aliases.bash` and add your distro to the case statement:

```bash
case "$DISTRO_BASE_LOCAL" in
    yourdistro*)
        install() { sudo your-pkg-manager install "$@"; }
        remove() { sudo your-pkg-manager remove "$@"; }
        update() { sudo your-pkg-manager update; }
        upgrade() { sudo your-pkg-manager upgrade; }
        search() { your-pkg-manager search "$@"; }
        clean() { sudo your-pkg-manager autoremove; }
        info() { your-pkg-manager info "$@"; }
        ;;
```

### Script Fails with "Permission Denied"

The installer needs sudo for package installation. Run:
```bash
sudo -v  # Verify sudo access
./RunMe.sh
```

### Files Not Being Backed Up

The script only backs up files that are different from the repo. To force a backup:
```bash
# Make a change to trigger backup
echo "# test" >> ~/.bashrc
./RunMe.sh
```

## Advanced Configuration

### WSL-Specific Setup

The installer automatically configures `.bash_profile` to load `.bashrc` for WSL compatibility. No additional setup needed.

### Tmux Integration

The script automatically:
- Clones tmux configuration from Bitbucket
- Clones Tmux Plugin Manager (TPM)
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
reload  # Reload configuration
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

### Success Messages (Green ✓)
- File backups
- Symlink creation
- Package installations
- Archive creation

### Info/Warning Messages (Yellow ⚠️)
- Skipped unchanged files
- Missing optional files
- Warnings about system state

### Error Messages (Red ❌)
- Failed operations
- Missing required files
- Permission issues

Example output:
```bash
=========================================
Starting Dotfiles Installation
Version: v1.0.1 (2026-01-15)
=========================================
🎨 Color output enabled
Detected: OS=linux, Distro=ubuntu, Base=debian, Kernel=5.15.0, Arch=x86_64
✓ Package management functions loaded for debian
✓ Loaded 15 applications from .install_apps.inc

🔐 Checking sudo access (you may be prompted for password)...
✓ Sudo access verified

Backing up existing dotfiles...
⏭️  Skipping /home/user/.bashrc (unchanged from repo)
✓ Backed up: /home/user/.profile
Backed up 1 files to /home/user/dotfiles/oldfiles/
Skipped 1 unchanged files
```

## Files Modified by Installer

The installer creates/modifies these files in your home directory:

- `~/.bashrc` → symlink to `~/dotfiles/.bashrc`
- `~/.bash_profile` → symlink to `~/dotfiles/.bash_profile`
- `~/.profile` → symlink to `~/dotfiles/.profile`
- `~/.inputrc` → symlink to `~/dotfiles/.inputrc`
- `~/.tmux.conf` → symlink to `~/.tmux/.tmux.conf`
- `~/.vimrc` → symlink to `~/.vim/.vimrc`

Original files are backed up to `~/dotfiles/oldfiles/` with timestamps.

## Security Notes

- 🔒 The installer never modifies system files (only user home directory)
- 🔐 Sudo is only used for package installation
- 💾 All changes are logged to timestamped log files
- 🔄 Original files are backed up before any changes
- ⚠️ Review `RunMe.sh` before running if you're security-conscious
- 🛡️ Script includes recursion guard to prevent infinite loops
- ✅ All file operations include error checking

## Version History

- **v1.0.1** (2026-01-15)
  - Added version support (`--version` flag)
  - Smart backup system (only backs up changed files)
  - Automatic cleanup (keeps 3 most recent archives)
  - Color-coded output (green/yellow/red)
  - Improved error handling throughout
  - Smart recursion guard in `.bashrc`
  - Privilege-aware prompt colors

## Getting Help

1. **Check logs**: `~/dotfiles/logs/install-*.log`
2. **Review this README**: Most issues are covered above
3. **Check bash syntax**: `bash -n ~/.bashrc`
4. **Test in debug mode**: `DEBUG=1 ./RunMe.sh`
5. **Test in trace mode**: `TRACE_DEBUG=1 ./RunMe.sh`
6. **Check version**: `./RunMe.sh --version`
7. **Open an issue**: [Your repo's issue tracker]

## License

[Your license here - MIT recommended]

## Credits & Inspiration

Some links to where I've ~~stolen~~ borrowed stuff & inspiration from:

* [Shell Config Subfiles](https://sanctum.geek.nz/arabesque/shell-config-subfiles/)
* [CLI Improved](https://remysharp.com/2018/08/23/cli-improved)
* [kenorb/dotfiles Functions](https://github.com/kenorb/dotfiles/blob/master/.bash_functions)
* [kenorb/dotfiles Aliases](https://github.com/kenorb/dotfiles/blob/master/.bash_aliases)
* [sharkdp/bat](https://github.com/sharkdp/bat/)
* [prettyping](https://github.com/denilsonsa/prettyping.git) → `~/dotfiles/extras/prettyping`

Created and maintained by **Patrick Österlund**. 

If you find this useful, consider supporting: [[PayPal](https://paypal.me/fotosbypatrick)]

---

**Last Updated**: January 16, 2026  
**Script Version**: v1.0.1