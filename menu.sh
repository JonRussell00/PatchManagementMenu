#!/bin/bash

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.
#
# Written by Jon Russell 2025

t=`date +%Y%m%d%H%M`
N=1
MENU=""
LOGSDIR="/home/username/logs/menu"

# SERVERS is a list of server names as they appear in the Ansible inventory
SERVERS=( 
    test.domain.com
    test.domain.co.uk
    pi1.local
    pi2.local
    wiki.domain.com
    mqtt.local
    )

LEN=${#SERVERS[@]}

# SERVERTYPES is a list of server types corresponding to the SERVERS list.
# The commands are slightly different depending on the OS.
SERVERTYPES=(
    CentOS8     # test.domain.com
    CentOS8     # test.domain.co.uk
    RPi         # pi1.local
    RPi         # pi2.local
    Ubuntu      # wiki.domain.com
    Ubuntu      # mqtt.local
    )

LENT=${#SERVERTYPES[@]}

show_patch_status(){
    ansible raspberrypi -b -o -m shell -a "apt list --upgradable 2>/dev/null | wc -l" | sort | sed 's/CHANGED | rc=0 | (stdout) //g'
    ansible centos8 -b -o -m shell -a "dnf -q check-update 2>/dev/null | wc -l" | sort | sed 's/CHANGED | rc=0 | (stdout) //g'
    ansible ubuntu -b -o -m shell -a "apt list --upgradable 2>/dev/null | wc -l" | sort | sed 's/CHANGED | rc=0 | (stdout) //g'
}

show_disk_space(){
    ansible raspberrypi:centos8:ubuntu -o -m shell -a "df -h | grep -E \"[0-9]+\% /$\"" | sed 's/CHANGED | rc=0 | (stdout) //g' | sort -n -r -k7
}

show_os_version(){
    ansible raspberrypi:centos8:ubuntu -o -m shell -a "grep PRETTY_NAME /etc/os-release" | sort | sed 's/CHANGED | rc=0 | (stdout) PRETTY_NAME=//g' | sort -k3
}

show_uptime(){
    ansible raspberrypi:centos8:ubuntu -o -m shell -a "cat /proc/uptime" | awk '{print $1 " | " int(int($8)/86400) " days"}' | sort -n -r -k3
}

update_all(){
    update_rpi
    update_centos8
    update_ubuntu
}

update_rpi(){
    echo "Updating Raspberry Pi" | tee -a $LOGSDIR/anisible-$t.log
    ansible raspberrypi -m apt -a "upgrade=yes update_cache=yes" -b | tee -a $LOGSDIR/anisible-$t.log | grep -vE '^\s*"(stdout|msg|stderr|stderr_lines)":'
    echo "Restarting bind..." | tee -a $LOGSDIR/anisible-$t.log
    ansible ns1.woodside -m shell -a "systemctl restart bind9" -b | tee -a $LOGSDIR/anisible-$t.log
}

update_centos8(){
    echo "Updating CentOS 8" | tee -a $LOGSDIR/anisible-$t.log 
    ansible centos8 -m dnf -a "name=* state=latest" -b | tee -a $LOGSDIR/anisible-$t.log 
}

update_ubuntu(){
    echo "Updating Ubuntu" | tee -a $LOGSDIR/anisible-$t.log
    ansible ubuntu -m apt -a "upgrade=yes update_cache=yes" -b | tee -a $LOGSDIR/anisible-$t.log | grep -vE '^\s*"(stdout|msg|stderr|stderr_lines)":'
}

show_menus() {
    MENU+=" p. Show Patch Status\n"
    MENU+=" d. Show Disk Space\n"
    MENU+=" o. Show OS Version\n"
    MENU+=" t. Show Uptime\n"
    MENU+=" a. Update All\n"
    MENU+=" r. Update Raspberry Pi\n"
    MENU+=" c. Update CentOS 8\n"
    MENU+=" u. Update Ubuntu\n"
    MENU+=" q. Exit\n"

    for i in "${SERVERS[@]}"
    do
        MENU+="$(printf %2d $N). Update $i\n"
        let N++
    done
    #echo -e "$MENU" | column     # Split menu in to columns for large number of servers
    echo -e "$MENU"
}

read_options(){
    local CHOICE
    read -p "Enter choice: " CHOICE
    case $CHOICE in
        p) show_patch_status
            exit 0 ;;
        d) show_disk_space
            exit 0 ;;
        o) show_os_version
            exit 0 ;;
        t) show_uptime
            exit 0 ;;
        a) update_all
            exit 0 ;;
        r) update_rpi
            exit 0 ;;
        c) update_centos8
            exit 0 ;;
        u) update_ubuntu
            exit 0 ;;
        q) exit 0;;
    esac

    if (( CHOICE > LEN )); then
        echo "Error: Number Too Big"
        exit 0
    fi

    SERVERNAME=${SERVERS[CHOICE]}
    SERVERTYPE=${SERVERTYPES[CHOICE]}
    echo $SERVERNAME
    echo $SERVERTYPE
    case $SERVERTYPE in
        CentOS8)
            echo "Updating CentOS 8 - $SERVERNAME" | tee -a $LOGSDIR/anisible-$t.log
            ansible $SERVERNAME -m dnf -a "name=* state=latest" -b | tee -a $LOGSDIR/anisible-$t.log
            ;;
        RPi)
            echo "Updating Raspberry Pi - $SERVERNAME" | tee -a $LOGSDIR/anisible-$t.log
            ansible $SERVERNAME -m apt -a "upgrade=yes update_cache=yes" -b | tee -a $LOGSDIR/anisible-$t.log
            ;;
        Ubuntu)
            echo "Updating Ubuntu - $SERVERNAME" | tee -a $LOGSDIR/anisible-$t.log
            ansible $SERVERNAME -m apt -a "upgrade=yes update_cache=yes" -b | tee -a $LOGSDIR/anisible-$t.log
            ;;
        *) 
            echo "No Type?"
            ;;
    esac
}

# ----------------------------------------------
# Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
trap '' SIGINT SIGQUIT SIGTSTP

#clear
echo ""
show_menus
read_options
echo "All done!"