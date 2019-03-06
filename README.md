# Trying to do the dotfiles again, and keeping them in sync..

### To install, clone this repo and symlink 2 files (for now, there might be a script to automate this

```
git clone git@bitbucket.org:b0red/dotfiles.git ~/dotfiles
```

& then (backup the 2 old files, .bashrc & .profile) and symlink the two files.

```
mv ~/.profile ~/.profile.old; mv ~/.bashrc ~/.bashrc.old; ln -s ~/dotfiles/.bashrc ~/.bashrc; ln -s ~/dotfiles/.profile ~/.profile 
git submodule init && git submodule update
```
## 2 ways to install the dotfiles

### Steps for manual installation
1. git clone git@bitbucket.org:b0red/dotfiles.git ~/dotfiles
2. mv ~/.profile ~/.profile.old; mv ~/.bashrc ~/.bashrc.old; ln -s ~/dotfiles/.bashrc ~/.bashrc; ln -s ~/dotfiles/.profile ~/.profile 
3. git submodule init && git submodule update
4. sudo apt install htop ncdu pydf tree mc
5. (update submodules)
  * git submodule foreach git pull origin master

### Automated install __On Your own risk__
* Running the 'RunMe.sh' script
* sudo chmod +x RunMe.sh; ./RunMe.sh  
* the script wont break anything, but it might not work as intended :(

### Other stuff thats good to have
* htop ncdu pydf tree mc 
```
sudo apt install htop ncdu pydf tree mc #On debianbased systems
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
* [https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping](https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping)

### tested on:
* Debian (Ubuntu)
* CentOS

***
Info
* [https://www.reddit.com/r/pushover/comments/1ezepb/howto_using_wget_instead_of_curl_to_send_pushover](https://www.reddit.com/r/pushover/comments/1ezepb/howto_using_wget_instead_of_curl_to_send_pushover)
...
