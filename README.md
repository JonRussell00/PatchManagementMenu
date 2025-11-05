# Patch Management Menu for Ansible
I wrote an ansible helper script to provide a menu system to manage the patching for various servers I own. I have several Raspberry Pis and Linux VMs at home, and several Ubuntu servers running in AWS.

I found myself constantly running similar commands regularly to apply patches and keep the server up to date.

So, I wrote this menu system to work with my ansible setup to semi-automate the management. I have managed over 100 servers using this menu system. For large numbers of servers, the menu can be split in to columns.

The script assumes you have ansible working already on all the servers.

# Configuration
The location for the log files is defined in the ```LOGSDIR```
```
LOGSDIR="/home/username/logs/menu"
```

There are two arrays at the top of the script:
## SERVER Array
The ```SERVERS``` array is a list of server names as they appear in the Ansible inventory configuration.

```
SERVERS=( 
    test.domain.com
    test.domain.co.uk
    pi1.local
    pi2.local
    wiki.domain.com
    mqtt.local
    )
```

## SERVERTYPES Array
The ```SERVERTYPES``` array is a list of server types corresponding to the SERVERS list.
The commands for various operating systems are slightly different depending on the version, so this amends the syntax based on the operating system.

In theory, Raspberry Pi and Ubuntu are the same, however, they are in separate groups in my ansible config, so I kept the separate in case there is ever a need to treat them differently.

```
SERVERTYPES=(
    CentOS8     # test.domain.com
    CentOS8     # test.domain.co.uk
    RPi         # pi1.local
    RPi         # pi2.local
    Ubuntu      # wiki.domain.com
    Ubuntu      # mqtt.local
    )
```

# Operation
When you run the script you are presented with a menu, consisting of a series of fixed menu options, and then an automatically generated list of servers, each with a unique number.

The fixed menu options allow you to run commands across all servers, or groups of servers.
The individual list allows you to update and patch a specific server.

```
user@host:~$ ./menu.sh 

 p. Show Patch Status
 d. Show Disk Space
 o. Show OS Version
 t. Show Uptime
 a. Update All
 r. Update Raspberry Pi
 c. Update CentOS 8
 u. Update Ubuntu
 q. Exit
 1. Update test.domain.com
 2. Update test.domain.co.uk
 3. Update pi1.local
 4. Update pi2.local
 5. Update wiki.domain.com
 6. Update mqtt.local
```

Here are sample outputs from each option

## Patch Status
Shows the number of outstanding patches for each server.
```
Enter choice: p
test.domain.com | 1
test.domain.co.uk | 1
pi1.local | 6
pi2.local | 6
wiki.domain.com | 0
mqtt.local | 0
```

## Disk Space
Shows the amount of free disk space for each server, sorted by the most used space first.
```
Enter choice: d
test.domain.com | /dev/nvme0n1p2  15G   11G  4.8G  68% /
test.domain.co.uk | /dev/nvme0n1p2  15G   11G  5.0G  68% /
pi1.local | /dev/sda2  14G  7.0G  6.0G  54% /
wiki.domain.com | /dev/mapper/ubuntu--vg-ubuntu--lv  61G   19G   39G  33% /
pi2.local | /dev/root  14G  3.1G   11G  23% /
mqtt.local | /dev/mapper/ubuntu--vg-ubuntu--lv  61G  6.1G   52G  11% /
```

## OS Version
Shows the version of the OS running for each server.
```
Enter choice: o
test.domain.com | "CentOS Stream 8"
test.domain.co.uk | "CentOS Stream 8"
pi2.local | "Debian GNU/Linux 11 (bullseye)"
pi1.local | "Debian GNU/Linux 13 (trixie)"
mqtt.local | "Ubuntu 24.04.3 LTS"
wiki.domain.com | "Ubuntu 24.04.3 LTS"
```

## Uptime
Shows the uptime, in days, for each server, sorted by the longest running first.
```
Enter choice: t
wiki.domain.com | 400 days
mqtt.local | 362 days
pi2.local | 289 days
test.domain.co.uk | 120 days
test.domain.com | 59 days
pi1.local | 7 days
```

## Update All
Updates all server, running "apt upgrade" or "yum update". The full output is stored in a log file for future reference. The console displays a cut down version of the output and removes stderr, msgs, etc, to make it easier to read for large numbers of servers.
```
Enter choice: a
Updating Raspberry Pi
pi2.local | SUCCESS => {
    "changed": false,
    "stdout_lines": [
        "Reading package lists...",
        "Building dependency tree...",
        "Reading state information...",
        "Calculating upgrade...",
        "The following packages have been kept back:",
        "  linux-image-rpi-v8:arm64 raspberrypi-ui-mods wf-panel-pi wfplug-connect",
        "  wfplug-squeek",
        "0 upgraded, 0 newly installed, 0 to remove and 5 not upgraded."
    ]
}
pi1.local | SUCCESS => {
    "changed": false,
    "stdout_lines": [
        "Reading package lists...",
        "Building dependency tree...",
        "Reading state information...",
        "Calculating upgrade...",
        "The following packages have been kept back:",
        "  linux-image-rpi-v8:arm64 raspberrypi-ui-mods wf-panel-pi wfplug-connect",
        "  wfplug-squeek",
        "0 upgraded, 0 newly installed, 0 to remove and 5 not upgraded."
    ]
}

Updating CentOS 8
test.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "msg": "Nothing to do",
    "rc": 0,
    "results": []
}
test.domain.co.uk | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "msg": "Nothing to do",
    "rc": 0,
    "results": []
}

Updating Ubuntu
wiki.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "stdout_lines": [
        "Reading package lists...",
        "Building dependency tree...",
        "Reading state information...",
        "Calculating upgrade...",
        "0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded."
    ]
}
mqtt.local | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "stdout_lines": [
        "Reading package lists...",
        "Building dependency tree...",
        "Reading state information...",
        "Calculating upgrade...",
        "0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded."
    ]
}
```

## Update a single server
Updates a single server, by entering the asocciated number. Here I selected number 4:
```
 4. Update pi2.local
```

```
Enter choice: 4
Updating Raspberry Pi
pi2.local | SUCCESS => {
    "changed": false,
    "stdout_lines": [
        "Reading package lists...",
        "Building dependency tree...",
        "Reading state information...",
        "Calculating upgrade...",
        "The following packages have been kept back:",
        "  linux-image-rpi-v8:arm64 raspberrypi-ui-mods wf-panel-pi wfplug-connect",
        "  wfplug-squeek",
        "0 upgraded, 0 newly installed, 0 to remove and 5 not upgraded."
    ]
}
```

## Logging
All the output from the updates is stored in a log file in /user/username/logs/menu/ configurable in the script.
```
user@host:~$ ls -la ~/logs/menu
-rw-rw-r-- 1 usr grp 271206 Jul 21 21:00 anisible-202507212038.log
-rw-rw-r-- 1 usr grp  36006 Aug 11 11:12 anisible-202508111111.log
-rw-rw-r-- 1 usr grp 118542 Aug 29 09:52 anisible-202508290949.log
-rw-rw-r-- 1 usr grp 315834 Sep  9 08:20 anisible-202509090806.log
-rw-rw-r-- 1 usr grp 237472 Sep 18 18:56 anisible-202509181821.log
-rw-rw-r-- 1 usr grp 162112 Oct 13 09:47 anisible-202510130944.log
-rw-rw-r-- 1 usr grp  62317 Nov  5 09:57 anisible-202511050956.log
```


