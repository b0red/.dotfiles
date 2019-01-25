# Trying to do the dotfiles again, and keeping them in sync..

### To install, clone this repo and symlink 2 files (for now, there might be a script to automate this

```
git clone git@bitbucket.org:b0red/dotfiles.git ~/dotfiles
```

& then (backup the 2 old files, .bashrc & .profile) and symlink the two files.

```
mv ~/.profile ~/.profile.old \
mv ~/.bashrc ~/.bashrc.old \
ln -s ~/dotfiles/.bashrc ~/.bashrc \
ln -s ~/dotfiles/.profile ~/.profile \
git submodule init && git submodule update
```
### Other stuff thats good to have
* htop 
* ncdu 
* pydf
* tree

Install with 
```
sudo apt install htop ncdu pydf tree
```
### Updating submodules
```
git submodule foreach git pull origin master
```
### Added things into an 'extras' directory
* git@github.com:denilsonsa/prettyping.git
* https://github.com/sharkdp/bat

...
### Some links to where I've stolen stuff from
[https://sanctum.geek.nz/arabesque/shell-config-subfiles/](https://sanctum.geek.nz/arabesque/shell-config-subfiles/)
 more to come

