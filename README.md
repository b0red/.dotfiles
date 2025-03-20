# My latest to do the dotfiles, and keeping them in sync..

## Install git first:
```
sudo apt install git
```
## 2 ways to install the dotfiles
### Automated install __*On Your own risk*__!!!
```
* Download the repo as usual:
# git clone git@bitbucket.org:b0red/dotfiles.git ~/dotfiles; cd ~/dotfiles; sudo chmod +x RunMe.sh; ./RunMe.sh
The script wont break anything, but it might not work as intended :(
```
### Steps for manual installation
```
1. Install git, vim, tmux (check your distro how to do this)
2. git clone --recurse-submodules git@bitbucket.org:b0red/dotfiles.git ~/dotfiles; cd ~/dotfiles
3. mv ~/.profile ~/.profile.old; mv ~/.bashrc ~/.bashrc.old; \ 
ln -s ~/dotfiles/.bashrc ~/.bashrc; ln -s ~/dotfiles/.profile ~/.profile
4. git submodule init && git submodule update
5. sudo apt install htop ncdu pydf tree mc
6. (update submodules)
  * git submodule foreach git pull origin master (Not necessary if using ' --recurse-submodules ')
```

### Other stuff thats nice to have
* htop ncdu pydf tree mc 
```
sudo apt install htop ncdu pydf tree mc vim tmux fd-find #On debianbased systems (The RunMe script installs these)
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
