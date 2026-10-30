#!/bin/bash

# in console define:
# rawdata="/host/verges/tank/data/BIDS_MPN/rawdata/"
# list_file="/host/verges/tank/data/daniel/99_varia/MPN_proc/demo/MPN_29jun2026.txt"
# script="/path/to/script/to/run/perSubSesPair.sh"
# logdir="/host/verges/tank/data/daniel/99_varia/MPN_proc/logs"

# usage:
# bash 00_call.sh [--local] [--test] [--batch-size N] [--hostname XYZ] [--vmem <vmem>] [--threads <threads>] \
#   <processing step specific arguments: ex. --t1-resolution 0.5|0.7> \
#   $rawdata $list_file $script $logdir

set -e

local=0
test=0
threads=10
batch_size=10
vmem=6G
hostname=NA

rawdata=
list_file=
script=
logdir=
t1_resolution=
script_args=()

submitted_job_ids=()

wait_for_open_slot() {
    local active_ids=()
    local jobid

    while :; do
        active_ids=()
        for jobid in "${submitted_job_ids[@]}"; do
            if qstat -j "$jobid" >/dev/null 2>&1; then
                active_ids+=("$jobid")
            fi
        done
        submitted_job_ids=("${active_ids[@]}")

        if [ "${#submitted_job_ids[@]}" -lt "$batch_size" ]; then
            break
        fi

        echo "[INFO] batch full (${#submitted_job_ids[@]}/${batch_size}); waiting 90secs..."
        sleep 90
    done
}

wait_for_all_jobs() {
    local active_ids=()
    local jobid

    while [ "${#submitted_job_ids[@]}" -gt 0 ]; do
        active_ids=()
        for jobid in "${submitted_job_ids[@]}"; do
            if qstat -j "$jobid" >/dev/null 2>&1; then
                active_ids+=("$jobid")
            fi
        done
        submitted_job_ids=("${active_ids[@]}")

        if [ "${#submitted_job_ids[@]}" -gt 0 ]; then
            echo "[INFO] waiting for remaining jobs: ${#submitted_job_ids[@]}"
            sleep 60
        fi
    done
}

while [ $# -gt 0 ]; do
    case "$1" in
        --hostname|-host)
            hostname="${2:?missing hostname}"
            shift 2
            ;;
        --local)
            local=1
            shift
            ;;
        --test)
            test=1
            shift
            ;;
        --batch-size|-b)
            batch_size="${2:?missing batch size}"
            shift 2
            ;;
        --threads|-t)
            threads="${2:?missing threads}"
            shift 2
            ;;
        --vmem)
            vmem="${2:?missing vmem}"
            shift 2
            ;;
        --)
            shift
            script_args=("$@")
            break
            ;;
        *)
            if [ -z "$rawdata" ]; then
                rawdata="$1"
            elif [ -z "$list_file" ]; then
                list_file="$1"
            elif [ -z "$script" ]; then
                script="$1"
            elif [ -z "$logdir" ]; then
                logdir="$1"
            else
                echo "[ERROR] Unexpected extra argument: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate inputs
: "${rawdata:?missing rawdata directory}"
: "${list_file:?missing participant-session list}"
: "${script:?missing processing script}"
: "${logdir:?missing log directory}"

rawdata="${rawdata%/}"

if [[ "${rawdata##*/}" != "rawdata" ]]; then
    echo "[ERROR] Expected rawdata path to end in /rawdata, got: ${rawdata}" >&2
    exit 1
fi

root="$(dirname -- "$rawdata")"

root="$(cd "$root" && pwd)"

if ! [[ "$batch_size" =~ ^[1-9][0-9]*$ ]]; then
    echo "[ERROR] batch_size must be a positive integer, got: $batch_size" >&2
    exit 1
fi

echo "[INFO] local=$local test=$test batch_size=$batch_size hostname=$hostname"
echo

cd "$rawdata" || exit 1

if [ "$test" -eq 1 ]; then
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
    logs="${logdir}/sub-${sub}_ses-${ses}"
    logs_pth="${logs}.o"
    
    echo "==============================================================="
    echo "[INFO] ${sub} ${ses}"

    if [ "$local" -eq 1 ]; then
        echo "[INFO] running locally: '$script' '$clean_sub' '$clean_ses' '${script_args[@]}'"
        "$script" "$clean_sub" "$clean_ses" "$root" "$t1_resolution" >> "${logs_pth}" 2>&1 || true
        continue
    else
        wait_for_open_slot

        echo "[INFO] queueing: '$script' '$clean_sub' '$clean_ses'"

        if [ "$hostname" != "NA" ]; then
            job_id=$(
                qsub -terse -l hostname="${hostname}" -pe smp "${threads}" -l h_vmem="${vmem}" \
                    -N "${sub#sub-}_${ses}" \
                    -e "${logs_pth}" \
                    -o "${logs_pth}" \
                    "$script" "$clean_sub" "$clean_ses" "${script_args[@]}"
            )
            echo "[INFO] qsub job ${job_id} submitted to ${hostname}"
        else
            job_id=$(
                qsub -terse -q mica.q -pe smp "${threads}" -l h_vmem="${vmem}" \
                    -N "${sub#sub-}_${ses}" \
                    -e "${logs_pth}" \
                    -o "${logs_pth}" \
                    "$script" "$clean_sub" "$clean_ses"
            )
            echo "[INFO] qsub job ${job_id} submitted"
        fi

        submitted_job_ids+=("$job_id")
        echo "[INFO] active_batch=${#submitted_job_ids[@]}/${batch_size}"
    fi

    # testing
    if [ "$test" -eq 1 ]; then
        echo "[TEST] Exiting after first submission."
        list_file="$list_file_orig"
        break
    else
        echo
    fi
done < "$list_file"

if [ "$local" -eq 0 ]; then
    echo "[INFO] all jobs submitted; waiting for remaining batch to finish"
    wait_for_all_jobs
    echo "[INFO] $(date) all submitted jobs have exited qstat"
fi
