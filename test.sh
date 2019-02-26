#!/bin/bash -p
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export TERM=${TERM:-dumb}
export DISPLAY=:0.0


APPARRAY=(curl htop ncdu pydf tree tmux vim mc)    

function app_installer(){
    ###     Install software (yes/no)
    #
    for APP in "${APPARRAY[@]}"
    do
        #echo $APP
        if command -v $APP 2> /dev/null; then
            echo "$APP already installed!" >> $LOG
        elif -x command -v $APP 2>/dev/null ; then
           sudo apt install $APP
            echo "Installed $APP" >> $LOG
        else
            echo "$APP FAILED TO INSTALL!!!" >> $LOG
        fi
    done 
}

for APP in "${APPARRAY[@]}"
    do
    ## create oneliner?
    [[ ! -x command -v $APP 2>/dev/null ]] && echo $APP already installed || echo will install $APP
    sleep 1
    done