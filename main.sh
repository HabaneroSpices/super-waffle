#!/bin/bash
#backgroundOnly=true

ACTION=($@)
scrnm=`basename "$0"`
tempDir=`mktemp -d`
confFile=./conf.env # This file is generated by the script. Should point to to a file.



function WriteConfig() {
    cp $confFile.sample $confFile
}

function PreCheck() {
    preCheck=0
    if [ -z $confFile ]; then echo "[*] confFile not set."; preCheck+=1;fi
    if [ -z $rcloneShare ]; then echo "[*] rcloneShare not set."; preCheck+=1;fi
    if [ -z $rcloneConf ]; then echo "[*] rcloneConf not set."; preCheck+=1;fi
    return $preCheck
}

function UnmountDrive() {
    # Unmount all defined AniExtreme shares.
    for i in "${aniexShares[@]}"; do
        echo "[*] Trying to unmount $i (1)"
        fusermount -u ${rcloneShare}/aniextreme-all/${i} ;
        if [ $? -eq 0 ]; then echo "[-] Unmouted ${i}"; else echo "[!] Failed to unmount ${i} - Trying forcefully! (2)"; fusermount -zu ${rcloneShare}/aniextreme-all/${i}; fi
    done
}
function MountDrive() {
    # Mount all defined AniExtreme shares.
    for i in "${aniexShares[@]}"; do
        mkdir -p ${rcloneShare}/aniextreme-all/${i}
        echo "[*] Trying to mount $i"
        rclone mount --max-read-ahead 1024k --allow-other $i: $rcloneShare/aniextreme-all/$i & 
        if [ $? -eq 0 ]; then echo "[+] Mounted ${i}"; else echo "[!] Failed to mount ${i}"; fi
     done
}

function AddDrive() { #! ADD DRIVE
    if [ -z "${ACTION[1]}" ]; then echo "No drive supplied"; exit; fi # exit if no second argument is not supplied.
    for i in "${ACTION[@]:1:20}"; do
        #TODO Check if arg exists in rClone conf file. 
        aniexShares+=("$i")
        aniexSharesTmp+=("$i")
    done
    sed "/aniexShares=(/,/)/d" $confFile > $tempDir/2
    echo 'aniexShares=(' >> $tempDir/2
    for i in "${aniexShares[@]}"; do
        echo -e "\"$i\"" >> $tempDir/2
    done
    echo ')' >> $tempDir/2
    cp $tempDir/2 $confFile
    echo "Added the following shares: ${aniexSharesTmp[@]}"
}

function RemoveDrive() { #! REMOVE DRIVE
    if [ -z "${ACTION[1]}" ]; then echo "No drive supplied"; exit; fi # exit if no second argument is not supplied.
    #TODO Check if there is active mounts before removing.
    cp $confFile $tempDir/2
    for i in "${ACTION[@]:1:20}"; do
        sed -i "/\"$i\"/d" $tempDir/2
        aniexSharesTmp+=("$i")
    done
    cp $tempDir/2 $confFile
    echo "Removed the following shares: ${aniexSharesTmp[@]}"
}

# *Main*

if [ ! -f $confFile ]; then WriteConfig; fi

source $confFile

if ! PreCheck -eq 0; then echo "[!] Failed precheck. - Exiting"; exit; fi

case "${ACTION[0]}" in
"unmount")
    UnmountDrive
    ;;
"list")
    echo "- Available Drives:"
    grep -Po '(?<=\[)(.*?)(?=\])' ${rcloneConf} # List strings inbetween Square brackets
    echo ""
    echo "- Added Drives:"
    echo "${aniexShares[@]}"
    ;;
"add")
    AddDrive
    ;;
"remove")
    RemoveDrive
    ;;
"reset")
    rm $confFile
    WriteConfig
    ;;
"mount")
    MountDrive
    ;;
*)
    echo "Usage: ${scrnm}... (mount|unmount|add|remove|list|reset)"    
    ;;
esac
rm -r $tempDir
exit