# ToDo.md - Dotfiles Project Task Tracker
# Version: 1.23.2 (2026-10-09)
# Last Updated: 2026-10-09

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
[x] symlink or copy the ~/.config files tmux depends on @done (2026-08-06, tmux_installer.sh v2.3.0 link_config_dir() — ~/.config/tmux/{coffee,tmux.conf})
[x] link ~/.gitconfig and restore ~/.config/mc @done (2026-08-06, run_me_first.sh v15.12.0 setup_config_symlinks() — also fixed a dangling ~/.config/mc symlink and restored config/mc/ from the last known-good Feb 2026 backup)
[x] fix ghost gitlink bug recurrence (tmux-claude-usage) @done (2026-08-06, same bug class as the already-fixed tmux-mullvad; also cleaned up dead tmux/plugins/tmux-resurrect and untracked vim/plugged/* gitlinks)
[x] untrack accidentally-committed machine state (.installation-state, stale tmux.conf/*.old backups, duplicate workspace file) @done (2026-08-06); removed dead .cygwin.d/ entirely; fixed .installation-state's broken .gitignore pattern (was ~/dotfiles/... — wrong path, predated the ~/.dotfiles migration)
[x] fix trap cleanup EXIT INT TERM in diagnose.sh / tmux_installer.sh (Ctrl-C ran cleanup, then the script kept going) @done (2026-10-06, diagnose.sh v1.0.1, tmux_installer.sh v2.3.1 — same bug fixed in 31 ~/bin scripts and Vibecoding v6.0.1)
[x] fix command_check() defined 4x across functions.bash/pkg_aliases.bash/aliases.bash/docker.bash, silently clobbering the colored interactive version @done (2026-08-06, functions.bash is now the one public version; pkg_aliases.bash's internal copy renamed to private _pkg_has_cmd())
[x] activate welcome.sh's fortune/rem/verse greeting @done (2026-08-06, removed a dead ~/.welcome/<tool> marker-file gate nothing ever created — now matches README's documented "if installed" behavior)
[x] fix psg() defined differently in env.bash (core, weaker) vs aliases.bash (interactive, better) — scripts silently got the worse version @done (2026-08-06, unified into env.bash with the -af implementation so it's identical everywhere)
[x] add confirmation prompt to gclean (was the only destructive git.bash command without one) @done (2026-08-06, converted alias to function matching gundohard/greset/gcleanup's y/n pattern)
[x] fix tmux nesting inside tmux (stacked status lines) when $TMUX is stripped by sudo/su/sudo mc @done (2026-10-07, /proc ancestry guard in .bashrc + start_tmux.sh, no auto-start as root; TMUX_TMPDIR pinned to /tmp)
[x] remove leftover ~/.config/systemd/user/tmux.service (broken ExecStop, stray session at boot) and get continuum autosave working @done (2026-10-07, unit disabled + kept as tmux.service.disabled-20261007, @continuum-boot off, save hook + timestamp seed wired in .tmux.conf)
[x] rewrite start_tmux.sh to the Vibecoding template @done (2026-10-07, start_tmux.sh v1.0.0; guard shared via tmux/tmux_guard.inc, now also catches ssh-to-self; removed malformed u/plugin line from .tmux.conf)
[x] move launcher keybindings into a tmux-menus Tools menu (kept in repo, copied by tmux_installer.sh) @done (2026-10-07, tmux/menus/tools.sh, tmux_installer.sh v2.4.0; fixed C-a double bind, @menus_config_file path, broken j/u bindings)
[x] fix copy/paste to Windows clipboard @done (2026-10-07, copy-command clip.exe + copy-mode y; root cause: Windows Terminal not installed, conhost has no OSC 52 / Shift+drag)
[] reinstall Windows Terminal (winget install --id Microsoft.WindowsTerminal) and set it as default terminal — restores Shift+drag selection and OSC 52
[x] tmux-menus custom_items/ was root-owned and world-writable (777) @done (2026-10-07, now patrick:patrick 755 — verified)
[x] tmux_installer.sh re-created ~/.tmux.conf and ~/.config/tmux/{coffee,tmux.conf} links on every run @done (2026-10-07, v2.4.1 already_linked() compares resolved paths)
[x] decide on `alias mc='sudo mc'` @done (2026-10-07, commented out — mc runs as the user; use `sudo mc` explicitly when root is needed)
[x] Coffee plugins: wildcard .gitignore, dead weather config removed, stray log removed @done (2026-10-07; tmux-ip-toggle can't be registered with Coffee — `local:` is unimplemented and a url-less YAML breaks `coffee install`)
[x] revoke the leaked weather API key (fbadfb59…) @done (2026-10-07, revoked by Patrick; still in git history but dead)
[x] tmux-mullvad.yaml was root-owned @done (2026-10-07, chowned to patrick — verified, no non-patrick files left in the repo)
[x] removed tmux-battery (unused on a desktop, no status segment) @done (2026-10-07, `coffee remove` + YAML + @batt_* icons); tmux-mullvad kept for now
[x] plugin version pinning @done (2026-10-07, decided NO — Coffee manages updates; caffeine-lock.json records the installed versions, so a bad update can be traced and rolled back from git)
[x] tmux script picker + Docker menu @done (2026-10-08, script_picker.sh / menus/docker.sh / docker_actions.sh; Docker menu meant for dellubuntu)
[x] removed unused `tmx` alias (attached to a non-existent session "0") @done (2026-10-08)
[x] easy-to-read tmux manual @done (2026-10-08, tmux/MANUAL.md; Tools menu → ?, shell: tmux-manual)
[x] .tmux.conf `bind-key C-s last-window` is overridden by tmux-resurrect's save @done (2026-10-08, decided: leave as is — C-a C-s saves, C-a C-a is last-window; documented in MANUAL.md)
[x] tmux-menus Sessions menu (list sessions, switch, detach a session's clients) @done (2026-10-08, tmux/menus/sessions.sh)
[x] Docker menu against dellubuntu @done (2026-10-08, works from WSL over ssh via @docker_menu_host — verified read-only against the real host)
[] optional: deploy on dellubuntu itself (git pull + tmux/tmux_installer.sh) to use the menus in a tmux running ON the server; there it uses local Docker
[x] check run_me_first.sh for old DeTerminator-style OS detection @done (2026-10-08, none — uses /etc/os-release + ID_LIKE; found and fixed os-release overwriting the script's VERSION, which polluted .installation-state)
[x] tmux panes took ~4.1 s to open @done (2026-10-08, loading animation off by default via BASHRC_SHOW_LOADING — ~0.7 s with all aliases; welcome.sh "Failed" in tmux fixed)
[x] .bashrc.d/.bashrc.d.rar (unreviewed Jan 2026 remnant) @done (2026-10-08, deleted)
[x] tmux/.tmux-git.conf unused @done (2026-10-08, deleted with the dead ~/.tmux-extras/tmux-git.sh block in .bashrc)
[x] symlink.sh distro-profile no-op @done (2026-10-08, symlink.sh deleted and its step removed from run_me_first.sh v15.13.0 — all real linking is in run_me_first.sh)
[x] tmux weather showed "location not found" @done (2026-10-09, wttr.in name lookup outage — @forecast-location switched to coordinates 59.33,18.07; plugin caches error text, clear /tmp/tmux-weather.cache after outages)

---

## Changelog

### v1.10.0 (2026-08-06)
- Fixed a real cross-file bug: command_check() was defined 4 times, and the colored interactive version in functions.bash was permanently shadowed by three duplicate silent one-liners loading after it
- Ran a full scan for the same bug class: found and fixed welcome.sh's dead marker-file gate (fortune/rem/verse had never fired on any machine) and psg()'s script-vs-interactive inconsistency; added a missing confirmation prompt to gclean for consistency with the rest of git.bash's destructive commands
- Added project CLAUDE.md: always update ToDo.md/README.md after code changes, then push

### v1.9.0 (2026-08-06)
- Restored mc config (config/mc/, seeded from the Feb 2026 backup) and wired up ~/.gitconfig + ~/.config/mc symlinking in run_me_first.sh (v15.12.0, setup_config_symlinks())
- Wired up ~/.config/tmux/{coffee,tmux.conf} symlinking in tmux_installer.sh (v2.3.0, link_config_dir())
- Fixed a recurring ghost-gitlink bug (tmux-claude-usage, same class as the already-fixed tmux-mullvad); cleaned up dead tmux/plugins/tmux-resurrect and untracked vim/plugged/* gitlinks
- Untracked/removed a batch of accidentally-committed machine state and cruft: .installation-state (plus fixed its broken .gitignore pattern), stale tmux.conf backups, *.old files, duplicate dotfiles.code-workspace, and the dead .cygwin.d/ leftover
- Logged three remaining low-priority gaps: .bashrc.d.rar (unreviewed archive), tmux/.tmux-git.conf (inert, depends on a machine-local script), symlink.sh's distro-profile no-op

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

