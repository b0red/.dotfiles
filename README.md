# Trying to do the dotfiles again, and keeping them in sync..

## Install some software first:
tmux git vim 


### To install, clone this repo and symlink 2 files (for now, there might be a script to automate this)

```
git clone --recurse-submodules git@bitbucket.org:b0red/dotfiles.git ~/dotfiles; cd ~/dotfiles
```

& then (backup the 2 old files, .bashrc & .profile) and symlink the two files.

```
mv ~/.profile ~/.profile.old; mv ~/.bashrc ~/.bashrc.old; ln -s ~/dotfiles/.bashrc ~/.bashrc; ln -s ~/dotfiles/.profile ~/.profile 

(Not necessary if using ' --recurse-submodules ')
git submodule init && git submodule update
```
## 2 ways to install the dotfiles

### Steps for manual installation
1. install git, vim, tmux (check your distro how to do this)
2. git clone git@bitbucket.org:b0red/dotfiles.git ~/dotfiles
3. mv ~/.profile ~/.profile.old; mv ~/.bashrc ~/.bashrc.old; ln -s ~/dotfiles/.bashrc ~/.bashrc; ln -s ~/dotfiles/.profile ~/.profile 
4. git submodule init && git submodule update
5. sudo apt install htop ncdu pydf tree mc
6. (update submodules)
  * git submodule foreach git pull origin master

### Automated install __*On Your own risk*__!!!
* Download the repo as usual git clone ...
* sudo chmod +x RunMe.sh; ./RunMe.sh  
* Running the 'RunMe.sh' script
* the script wont break anything, but it might not work as intended :(

### Other stuff thats nice to have
* htop ncdu pydf tree mc 
```
sudo apt install htop ncdu pydf tree mc vim tmux #On debianbased systems (The RunMe script installs these)
```
### Updating submodules
```
git submodule foreach git pull origin master
```
### Added things into an 'extras' directory
* https://github.com/sharkdp/bat

### Some links to where I've stolen stuff from
* [https://sanctum.geek.nz/arabesque/shell-config-subfiles/](https://sanctum.geek.nz/arabesque/shell-config-subfiles/)
* [https://remysharp.com/2018/08/23/cli-improved](https://remysharp.com/2018/08/23/cli-improved)
* [https://github.com/kenorb/dotfiles/blob/master/.bash_functions](https://github.com/kenorb/dotfiles/blob/master/.bash_functions)
* [https://github.com/kenorb/dotfiles/blob/master/.bash_aliases](https://github.com/kenorb/dotfiles/blob/master/.bash_aliases)
* [https://github.com/sharkdp/bat/](https://github.com/sharkdp/bat/)
* [https://github.com/denilsonsa/prettyping.git](https://github.com/denilsonsa/prettyping.git) ~/dotfiles/extras/prettyping

### tested on:
* Debian (Ubuntu)
* CentOS

***
Info
* [https://www.reddit.com/r/pushover/comments/1ezepb/howto_using_wget_instead_of_curl_to_send_pushover](https://www.reddit.com/r/pushover/comments/1ezepb/howto_using_wget_instead_of_curl_to_send_pushover)
...
