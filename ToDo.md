### ToDO:
[] echo found distro on top of screen when running for the first time!
[] check logic/flow, everything must be in the correct order
[] make so when it reverts, it actually shows whats getting done
[] ev fixa så att RunMe.sh kollar om det är kört tidigare eller om det är nytt?
[] Skapa en "firstrun"-check. Om inte körd tidigare, gör en sak, annars en 

### Done:

[x] create a small header when run, write this to affected files:
  ### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  ###                                             Created by RunMe.sh <Current_Date>
  ### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
[x] Create a function that reads apps to be installed from file, easier maintance
[x] fixa casesatsen för de olika aliasen @done (19-04-27 22:44)
[x] fixa så logfilen skrivs snyggt @done (19-04-27 22:44)

### Kanske kan omarbetas: 
Källa: https://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html
### Get os name via uname ###
_myos="$(uname)"
 
### add alias as per os using $_myos ###
case $_myos in
    Linux) alias foo='/path/to/linux/bin/foo';;
    FreeBSD|OpenBSD) alias foo='/path/to/bsd/bin/foo' ;;
    SunOS) alias foo='/path/to/sunos/bin/foo' ;;
    *) ;;
  esac

Länkar:
---------------------------------------------------------------------------------
https://cromwell-intl.com/open-source/package-management.html
https://packagecontrol.io/packages/PlainTasks
https://en.opensuse.org/SDB:Zypper_usage
https://en.opensuse.org/SDB:Cleanup_system

Används inte:

#[[ -e $LOG ]] && rm -f $LOG || touch $LOG; echo -e "\n\n$NAME - $DATE" > $LOG
#[[ -e ${LOG} ]] && rm -f ${LOG} || (touch ${LOG}; echo -e "\n\n$NAME - $DATE" > ${LOG})


