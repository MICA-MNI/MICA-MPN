#!/bin/bash

# in console define:
# rawdata="/host/verges/tank/data/BIDS_MPN/rawdata/"
# list_file="/host/verges/tank/data/daniel/99_varia/MPN/MPN_29jun2026.txt"
# script="/path/to/script/to/run/perSubSesPair.sh"
# logdir="/host/verges/tank/data/daniel/99_varia/MPN/logs/"

# usage:
# bash 00_qsubCall.sh $rawdata $list_file $script $logdir

rawdata=$1
list_file=$2
script=$3
logdir=$4
test=${5:-0}

cd "$rawdata" || exit 1

if [ "$test" -eq 1 ]; then
    # choose random line in list_file
    line=$(shuf -n 1 "$list_file")
    echo "[TEST] Randomly selected line: $line"
    echo "$line" > /tmp/test_list.txt
    list_file_orig="$list_file"
    list_file="/tmp/test_list.txt"
fi

while IFS=, read -r sub ses; do
    [ -n "$sub" ] || continue

    clean_sub="${sub#sub-}"
    clean_ses="${ses#ses-}"

    logs="${logdir}/${sub}_${ses}"
    echo "[QUEUE] ${sub} ${ses}"
    
    #echo "$script" "$clean_sub" "$clean_ses"
    qsub -q mica.q -pe smp 10 -l h_vmem=6G \
        -N "${sub#sub-}_${ses}" \
        -e "${logs}.e" \
        -o "${logs}.txt" \
        /bin/bash "$script" "$clean_sub" "$clean_ses"

    # testing
    if [ "$test" -eq 1 ]; then
        
        echo "[TEST] Exiting after first submission."
        list_file="$list_file_orig"
        break
    else
        echo
    fi
done < "$list_file"