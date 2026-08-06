# ToDo.md - Dotfiles Project Task Tracker
# Version: 1.8.0 (2026-08-06)
# Last Updated: 2026-08-06

### ToDO:
#### General:
[x] Add interactive package selection and skip-install options @done (2026-05-11)
[x] Improve backup/revert flow with manifest-backed backups @done (2026-05-11)
[x] Keep canonical repo on GitHub and document it in README @done (2026-06-21)
[x] Add Taskwarrior config detection and symlink setup @done (2026-05-11)
[x] Create a function that reads apps to be installed from file, easier maintance @done (existing load_app_list function)
[x] create a small header when run, write this to affected files @done (add_file_header function exists)
[x] check logic/flow, everything must be in the correct order @done (2026-05-11)
[x] make so when it reverts, it actually shows whats getting done @done (2026-05-11)
[x] echo found distro on top of screen when running for the first time! @done (2026-05-11)
[x] maybe make so run_me_first.sh checks for previous runs or if first run? @done (2026-05-11)
[x] refactor the code to be more modular, functions for each task, easier to read and maintain @done (2026-06-21)
[x] add error handling, if a command fails, it should log the error and continue with the next one @done (2026-05-11)
[x] refactor tmux_installer.sh to Vibecoding v5.6 canonical structure @done (2026-06-21)
[x] add prompt for custom vs plain tmux on auto-start (.bashrc) @done (2026-08-06)
[x] wire up notification backend for --notify-only / --test-notify @done (2026-08-06, run_me_first.sh v15.11.0 — Pushover -> Gotify -> Email)
[x] add Vibecoding v5.6 canonical header to symlink.sh @done (2026-08-06)
[x] resolve run_me_first.sh's stale ColorCodes.inc reference @done (2026-08-06, dropped in favor of inline-only colors)
[x] wire up notification backend for tmux_installer.sh's --notify-only / --test-notify @done (2026-08-06, tmux_installer.sh v2.2.0 — same Pushover -> Gotify -> Email notify_send() pattern)
[x] add .dotfiles.code-workspace to .gitignore @done (2026-08-06)
[] Coffee-managed tmux plugins (tmux/coffee/plugins/) still need manual tinkering — not fully hands-off yet
[] symlink or copy the ~/.config files tmux depends on — neither installer handles this yet

---

## Changelog

### v1.8.0 (2026-08-06)
- Wired up tmux_installer.sh's notification backend (v2.2.0) — same Pushover -> Gotify -> Email `notify_send()` pattern as run_me_first.sh
- Logged .gitignore's `.dotfiles.code-workspace` entry as done
- Added two new open items: Coffee plugin management (manual tinkering still needed) and unhandled `~/.config` files tmux depends on

### v1.7.0 (2026-08-06)
- Wired up run_me_first.sh's notification backend (Pushover -> Gotify -> Email via new `notify_send()`) — v15.11.0
- Added Vibecoding v5.6 header block to symlink.sh
- Dropped run_me_first.sh's dead ColorCodes.inc reference (file only ever existed as a machine-local ~/bin include)
- Added timestamped file logging to tmux_installer.sh (~/.dotfiles/logs/tmux-install-*.log) — v2.1.0
- Noted tmux_installer.sh's --notify-only/--test-notify are still placeholders (only run_me_first.sh's backend was wired up)

### v1.6.0 (2026-08-06)
- Synced ToDo.md with README's Recent Changes / Version History (was stale since v1.5.0 / README v15.8.0)
- Logged tmux_installer.sh Vibecoding refactor (README v15.9.0) and the tmux auto-start prompt (README v15.10.0) as done
- TMUX section reconciled against actual script state: rename, distro/package-manager support, and custom keybindings/status bar were already implemented but still marked open
- Pulled README's "Known Issues / Migration TODOs" (notification backend, symlink.sh header, ColorCodes.inc reference) into General as open items

### v1.5.0 (2026-06-21)
- `run_me_first.sh` refactored to Vibecoding v5.6 canonical structure (v15.8.0)
- 9 logical bugs fixed in `run_me_first.sh` (state file, validate_installation, revert, logging, distro cases, taskwarrior order)
- 6 `.bashrc.d` bugs fixed (alias shadowing in aliases.bash, docker.bash lzd/lzj + unquoted IDs, exports.bash PAGER + export/assign + uname, env.bash dead var, logout.bash log rotation)
- Repository migration complete: all Bitbucket → GitHub references updated

### v1.4.0 (2026-06-20)
- Fixed three improperly formatted done items (had @done text but `[]` checkbox)
- Bug fixes to colorcodes.bash (NC), aliases.bash (list_extensions, please, ghost, tm), pkg_aliases.bash (startup noise)
- Tmux auto-start wired into .bashrc (runs ~/.start_tmux.sh on first interactive login)

### v1.3.0.1 (2026-05-17)
- Added Taskwarrior config detection and symlink setup
- Translated some lines from swedish to english for better readability

### v1.3.0 (2026-05-11)
- Added prominent distro display on first run
- Implemented first-run detection with state file tracking
- Enhanced error handling for resilient operation (removed set -euo pipefail)
- Updated installer to continue on non-critical failures
- Added installation state persistence for future reference

### v1.1.0 (2026-05-08)
- TMUX fixes completed (coffee plugin, keybindings, weather, numbering)
- General installer improvements marked as done

### v1.0.0 (2026-04-27)
- Initial ToDo.md structure with VIM and general tasks

---

#### TMUX:

##### Major:
[x] add logging, create a log file and write all actions and errors to it, with timestamps @done (2026-08-06, tmux_installer.sh v2.1.0 — writes to ~/.dotfiles/logs/tmux-install-*.log)
[x] rename the script to something more descriptive, like tmux_setup.sh or tmux_install.sh @done (renamed to tmux_installer.sh)
[] add support for more tmux themes, like powerline, gruvbox, etc.
[x] add support for more tmux configurations, like custom keybindings, status bar @done (see README Custom Keybindings / Status Bar sections)

##### Minor:
[x] add support for more distros/package managers, like apt, pacman, dnf, zypper, apk, brew @done (tmux_installer.sh installs deps via apt-get/dnf/pacman/zypper/apk/brew)
[] add support for more shells, like zsh, fish, etc.
[] add support for more terminal emulators, like alacritty, kitty, etc.

##### Completed (May 8, 2026):
[x] Fix Coffee plugin manager initialization (symlink repair, force reinstall)
[x] Fix broken keybindings for htop/btop (prefix h/H/o/O)
[x] Fix task-monitor script argument passing (launch_monitor.sh)
[x] Fix weather display (removed broken wttr.in forecast)
[x] Fix window/pane numbering mismatch (base-index 1)

#### VIM

##### Major:
* WIP
##### Minor:
* WIP

### Done:

[x] fix case selection for the different aliases @done (19-04-27 22:44)
[x] check that we have nicely written logfiles@done (19-04-27 22:44)
[x] make so when it reverts, it actually shows whats getting done @done
[x] check logic/flow, everything must be in the correct order @done
[x] create a small header when run, write this to affected files:
```
  ### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  ###                                             Created by run_me_first.sh <Current_Date>
  ### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  ```
[x] Create a function that reads apps to be installed from file, easier maintance
[x] fixa casesatsen för de olika aliasen @done (19-04-27 22:44)
[x] fixa så logfilen skrivs snyggt @done (19-04-27 22:44)

### Install:

curl -sSL https://raw.githubusercontent.com/Gu1llaum-3/sshm/main/install/unix.sh | bash
curl -LO https://github.com/ClementTsang/bottom/releases/download/0.12.3/bottom_0.12.3-1_amd64.deb
sudo dpkg -i bottom_0.12.3-1_amd64.deb

### add alias as per os using $_myos ###
case $_myos in
    Linux) alias foo='/path/to/linux/bin/foo';;
    FreeBSD|OpenBSD) alias foo='/path/to/bsd/bin/foo' ;;
    SunOS) alias foo='/path/to/sunos/bin/foo' ;;
    *) ;;
  esac

### Links:
---------------------------------------------------------------------------------
[Package Management on Linux, BSD, and Solaris](https://cromwell-intl.com/open-source/package-management.html)
[Zypper usage](https://en.opensuse.org/SDB:Zypper_usage)
[envtrace](https://github.com/FlerAlex/envtrace) 

### Not in use, but might be useful later:
```
#[[ -e $LOG ]] && rm -f $LOG || touch $LOG; echo -e "\n\n$NAME - $DATE" > $LOG
#[[ -e ${LOG} ]] && rm -f ${LOG} || (touch ${LOG}; echo -e "\n\n$NAME - $DATE" > ${LOG})
```

