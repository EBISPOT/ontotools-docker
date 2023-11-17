#!/bin/bash

# this script first performs a git pull in the script's folder, then
# wraps redeploy.sh, redirecting stdout and stderr to
# deploy_$( date )_stdout.log and deploy_$( date )_stderr.log, respectively.
# (we write the output to those logfiles mostly because it's massive, but
# also for forensic purposes if something should go wrong.)

# the script will typically be invoked from a github action

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

CUR_DATE=$( date +%Y%m%d_%H%M%S )

STDOUT_LOGFILE="${SCRIPT_DIR}/deploy_${CUR_DATE}_stdout.log"
STDERR_LOGFILE="${SCRIPT_DIR}/deploy_${CUR_DATE}_stderr.log"

cd "${SCRIPT_DIR}" && \
git pull && \
time (
    echo "Performing redeploy; writing results to: "
    echo " - stdout: ${STDOUT_LOGFILE}"
    echo " - stderr: ${STDERR_LOGFILE}"

    sudo ./redeploy.sh > ${STDOUT_LOGFILE} 2> ${STDERR_LOGFILE}

    echo "...done!"
)
