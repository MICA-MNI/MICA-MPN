#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <command> [args ...]" >&2
    exit 1
fi

# HANDLE THREADS ARGUMENT
# Optional: --threads N command [args...]
threads_arg=""
if [[ "$#" -ge 2 && "$1" == "--threads" ]]; then
    threads_arg="$2"
    shift 2
fi

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 [--threads N] <command> [args ...]" >&2
    exit 1
fi

# 1) explicit --threads N
# 2) default 6
threads="${threads_arg:-6}"

# TMP DIR SETUP
base_tmp="${TMPDIR:-/tmp}"
job_tmp="$(mktemp -d "${base_tmp%/}/job_${JOB_ID:-manual}_XXXXXX")"

cleanup() {
    status=$?
    [[ -d "${job_tmp:-}" ]] && rm -rf -- "$job_tmp"
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

export JOB_TMPDIR="$job_tmp"
export TMPDIR="$job_tmp"
export TMP="$job_tmp"
export TEMP="$job_tmp"
export THREADS="$threads"
export OMP_NUM_THREADS="$threads"

echo "Job ID    : ${JOB_ID:-manual}"
echo "Now       : $(date)"
echo "Host      : $(hostname)"
echo "NSLOTS    : $threads"
echo "Threads   : $threads"
echo "JOB_TMPDIR: $job_tmp"
echo "Command   : $*"

"$@"