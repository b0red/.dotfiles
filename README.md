# Dotfiles Repository

## Installation

1. Clone this repository:
git clone https://your-repo-url.git ~/dotfiles


2. Run the installer:
cd ~/dotfiles
chmod +x RunMe.sh
./RunMe.sh


3. Ensure your shell sources the main `.bashrc`:
Add or confirm this line in your `~/.bashrc`:

source ~/dotfiles/.bashrc


4. Reload your shell:

source ~/.bashrc


## Usage

- `RunMe.sh` backs up old dotfiles and creates symlinks.
- It installs common applications/packages and updates submodules.
- Use `RunMe.sh -r` to revert symlinks and restore backups.

## Structure

- `.bashrc` - Main shell config, sources modular files.
- `.bashrc.d/` - Modular bash configs (.bash_exports, .bash_functions, etc.)
- `.profile.d/` - (Optional) profile scripts folder.
- `oldfiles/` - Backups and install logs (dotfile_install_<date>.log).
- `symlink.sh` - Script to safely create symlinks with backups.
- `.bashrc.d` - contains *.bash scripts (aliases, colorcodes, docker, functions).
- `.profile.d` - a few helper scripts (browser.sh, pager, TZ, welcome.sh).
- `.cygwin.d` - mostly for historical purposes,
-  `extras` - git submodules. 
- Various helper scripts for Docker, git, and shell enhancements.

## Notes

- Replace `https://your-repo-url.git` with actual repo URL.
- Customize `.bash_exports` for your environment needs.
- Check `.bash_functions` for handy shell functions.
