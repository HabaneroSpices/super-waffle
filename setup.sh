tempDir=`mktemp -d`
scrnm=`basename "$0"`
ACTION=($@)
sectionStart="#!-- aniextreme --"
sectionEnd="#!-- aniextreme-end --"
confFile=./conf.env

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

function generateConfig() {
    rclone backend -o config drives aniextreme: > $tempDir/1

    sed -i 's/  I AniEx I -- Anime -- /aniextreme-/gmi' $tempDir/1
    sed -i 's/  I AniEx I -- Anime - /aniextreme-/gmi' $tempDir/1
    sed -i 's/  I AniEx I - /aniextreme-/gmi' $tempDir/1
    sed -i 's/ - /-/gmi' $tempDir/1
    sed -i 's/ual Nov/ual-Nov/gmi' $tempDir/1
}

function writeConfig() {
    sed "/$sectionStart/,/$sectionEnd/d" $rcloneConf > $tempDir/2
    echo -e "$sectionStart" >> $tempDir/2
    cat $tempDir/1 >> $tempDir/2
    echo -e "$sectionEnd" >> $tempDir/2
    cp $tempDir/2 $rcloneConf
}

function removeConfig() {
    sed "/$sectionStart/,/$sectionEnd/d" $rcloneConf > $tempDir/2
    cp $tempDir/2 $rcloneConf
}

# *Main*

if [ ! -f $confFile ]; then WriteConfig; fi

source $confFile

if ! PreCheck -eq 0; then echo "[!] Failed precheck. - Exiting"; exit; fi

case "${ACTION[0]}" in
    "add")   
    grep -q "$sectionStart" $rcloneConf
    if [ $? -eq 0 ]; then echo -e "[!] Drives are already added. - Exiting\nTo remove drives run:\n \"setup.sh remove\"\nTo update drives run:\n \"setup.sh update\""; exit; fi
    generateConfig
    writeConfig
    echo -e "[+] Inserted drives into rclone conf file. - See \"main.sh list\" for available drives."
    ;;
    "remove")
    grep -q "$sectionStart" $rcloneConf
    if [ ! $? -eq 0 ]; then echo -e "[!] No drives seem to have been added yet - Exiting\nTo add drives run:\n \"setup.sh add\""; exit; fi
    removeConfig
    echo -e "[-] Removed drives from rclone config file."
    ;;
    "update")
    generateConfig
    echo -e "[*] Generating new list"
    writeConfig
    echo -e "[+] Inserted new drives into rclone conf file. - See \"main.sh list\" for available drives."
    ;;
    *)
    echo "Usage: ${scrnm}... (add|remove|update)"
    ;;
esac

rm -r $tempDir
exit
