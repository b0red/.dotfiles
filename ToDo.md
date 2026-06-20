# ToDo.md - Dotfiles Project Task Tracker
# Version: 1.4.0 (2026-06-20)
# Last Updated: 2026-06-20

### ToDO:
#### General:
[x] Add interactive package selection and skip-install options @done (2026-05-11)
[x] Improve backup/revert flow with manifest-backed backups @done (2026-05-11)
[x] Keep canonical repo on Bitbucket and document it in README @done (2026-05-11)
[x] Add Taskwarrior config detection and symlink setup @done (2026-05-11)
[x] Create a function that reads apps to be installed from file, easier maintance @done (existing load_app_list function)
[x] create a small header when run, write this to affected files @done (add_file_header function exists)
[x] check logic/flow, everything must be in the correct order @done (2026-05-11)
[x] make so when it reverts, it actually shows whats getting done @done (2026-05-11)
[x] echo found distro on top of screen when running for the first time! @done (2026-05-11)
[x] maybe make so run_me_first.sh checks for previous runs or if first run? @done (2026-05-11)
[] refactor the code to be more modular, functions for each task, easier to read and maintain
[x] add error handling, if a command fails, it should log the error and continue with the next one @done (2026-05-11)

---

## Changelog

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
[] add logging, create a log file and write all actions and errors to it, with timestamps
[] rename the script to something more descriptive, like tmux_setup.sh or tmux_install.sh
[] add support for more tmux themes, like powerline, gruvbox, etc.
[] add support for more tmux configurations, like custom keybindings, status bar

##### Minor:
[] add support for more distros, like Arch, Debian, etc.
[] add support for more package managers, like apt, pacman, etc.
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

