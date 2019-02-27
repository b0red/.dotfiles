#!/bin/bash -p
##########################################################################################
##
##
##          This is just for testing
##
##
##########################################################################################

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
        elif ! [ -x command -v $APP 2>/dev/null ]; then
           sudo apt install $APP
            echo "Installed $APP" >> $LOG
        else
            echo "$APP FAILED TO INSTALL!!!" >> $LOG
        fi
    done 
}

app_installer; sleep 1

# for APP in "${APPARRAY[@]}"
#     do
#         echo  ny loop
#     ## create oneliner?
#     if (command -v $APP 2>/dev/null); then
#           echo $APP already installed 
#     else
#         echo will install ${APP}
#         install $APP

#     sleep 1
# fi
#     done