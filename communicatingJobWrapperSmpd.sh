#!/bin/sh
# This wrapper script is intended to be submitted to SLURM at
#   Juelich Supercomputing Centre
#   Forschungszentrum Juelich GmbH
#
# The following environment variables are set by the submit MATLAB code:
# PARALLEL_SERVER_CMR         - the value of ClusterMatlabRoot (may be empty)
# PARALLEL_SERVER_MATLAB_EXE  - the MATLAB executable to use
# PARALLEL_SERVER_MATLAB_ARGS - the MATLAB args to use
# PARALLEL_SERVER_TOTAL_TASKS - total number of workers to start
# PARALLEL_SERVER_NUM_THREADS - number of cores needed per worker
# PARALLEL_SERVER_DEBUG       - used to debug problems on the cluster
#
# The following environment variables are forwarded:
# PARALLEL_SERVER_DECODE_FUNCTION     - the decode function to use
# PARALLEL_SERVER_STORAGE_LOCATION    - used by decode function
# PARALLEL_SERVER_STORAGE_CONSTRUCTOR - used by decode function
# PARALLEL_SERVER_JOB_LOCATION        - used by decode function
# PARALLEL_SERVER_DEBUG,
# PARALLEL_SERVER_LICENSE_NUMBER,
# 
# MLM_WEB_LICENSE,
# MLM_WEB_USER_CRED,
# MLM_WEB_ID,
#
# MDCE_DECODE_FUNCTION,
# MDCE_STORAGE_LOCATION,
# MDCE_STORAGE_CONSTRUCTOR,
# MDCE_JOB_LOCATION,
# MDCE_DEBUG,
# MDCE_LICENSE_NUMBER
#
# The following environment variables are set by Slurm
# SLURM_JOB_ID         - number of nodes allocated to Slurm job
# SLURM_JOB_NUM_NODES  - number of hosts allocated to Slurm job
# SLURM_JOB_NODELIST   - list of hostnames allocated to Slurm job
# SLURM_TASKS_PER_NODE - list containing number of tasks allocated per host to Slurm job

# Copyright 2015-2022 The MathWorks, Inc.

# If PARALLEL_SERVER_ environment variables are not set, assign any
# available values with form MDCE_ for backwards compatibility
PARALLEL_SERVER_CMR=${PARALLEL_SERVER_CMR:="${MDCE_CMR}"}
PARALLEL_SERVER_MATLAB_EXE=${PARALLEL_SERVER_MATLAB_EXE:="${MDCE_MATLAB_EXE}"}
PARALLEL_SERVER_MATLAB_ARGS=${PARALLEL_SERVER_MATLAB_ARGS:="${MDCE_MATLAB_ARGS}"}
PARALLEL_SERVER_TOTAL_TASKS=${PARALLEL_SERVER_TOTAL_TASKS:="${MDCE_TOTAL_TASKS}"}
PARALLEL_SERVER_NUM_THREADS=${PARALLEL_SERVER_NUM_THREADS:="${MDCE_NUM_THREADS}"}
PARALLEL_SERVER_DEBUG=${PARALLEL_SERVER_DEBUG:="${MDCE_DEBUG}"}

#########################################################################################
# Shut down and exit with the exit code of the last command executed
cleanupAndExit() {
    EXIT_CODE=${?}

    echo "Exiting with code: ${EXIT_CODE}"
    exit ${EXIT_CODE}
}

#########################################################################################
# load modules
loadModules() {
# EXTRAMODULES
}

#########################################################################################
runMpiexec() {

    # Echo the nodes that the scheduler has allocated to this job:
    echo -e "The scheduler has allocated the following nodes to this job:\n${SLURM_NODELIST:?"Node list undefined"}"

    # ENVS_TO_FORWARD="PARALLEL_SERVER_DECODE_FUNCTION,PARALLEL_SERVER_STORAGE_LOCATION,PARALLEL_SERVER_STORAGE_CONSTRUCTOR,PARALLEL_SERVER_JOB_LOCATION,PARALLEL_SERVER_DEBUG,PARALLEL_SERVER_LICENSE_NUMBER,MLM_WEB_LICENSE,MLM_WEB_USER_CRED,MLM_WEB_ID"
    # LEGACY_ENVS_TO_FORWARD="MDCE_DECODE_FUNCTION,MDCE_STORAGE_LOCATION,MDCE_STORAGE_CONSTRUCTOR,MDCE_JOB_LOCATION,MDCE_DEBUG,MDCE_LICENSE_NUMBER"
    # CMD="srun --export=${ENVS_TO_FORWARD},${LEGACY_ENVS_TO_FORWARD} \"${PARALLEL_SERVER_MATLAB_EXE}\" ${PARALLEL_SERVER_MATLAB_ARGS}"

    CMD="srun --export=ALL \"${PARALLEL_SERVER_MATLAB_EXE}\" ${PARALLEL_SERVER_MATLAB_ARGS}"

    # As a debug stage: echo the command ...
    echo $CMD

    # ... and then execute it.
    eval $CMD

    MPIEXEC_CODE=${?}
    if [ ${MPIEXEC_EXIT_CODE} -eq 42 ] ; then
        # Get here if user code errored out within MATLAB. Overwrite this to zero in this case.
        echo "Overwriting MPIEXEC exit code from 42 to zero (42 indicates a user-code failure)"
        MPIEXEC_EXIT_CODE=0
    fi

    if [ ${MPIEXEC_CODE} -ne 0 ] ; then
        exit ${MPIEXEC_CODE}
    fi
}

#########################################################################################
MAIN() {
    # Install a trap to do some work if something errors
    # or the job is cancelled.
    trap "cleanupAndExit" 0 1 2 15
    loadModules
    runMpiexec
    exit 0 # Explicitly exit 0 to trigger cleanupAndExit
}

# Call the MAIN loop
MAIN
