### ToDO:

[] echo found distro on top of screen when running for the first time!
[] maybe make so RunMe.sh checks for previous runs or if first run?

### Done:

[x] make so when it reverts, it actually shows whats getting done @done
[x] check logic/flow, everything must be in the correct order @done
[x] create a small header when run, write this to affected files:
```
  ### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  ###                                             Created by RunMe.sh <Current_Date>
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

