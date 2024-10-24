#!/bin/sh
# This wrapper script is intended to be submitted to Slurm to support
# communicating jobs.
#
# This script uses the following environment variables set by the submit MATLAB code:
# PARALLEL_SERVER_CMR         - the value of ClusterMatlabRoot (might be empty)
# PARALLEL_SERVER_MATLAB_EXE  - the MATLAB executable to use
# PARALLEL_SERVER_MATLAB_ARGS - the MATLAB args to use
#
# The following environment variables are forwarded through mpiexec:
# PARALLEL_SERVER_DECODE_FUNCTION     - the decode function to use
# PARALLEL_SERVER_STORAGE_LOCATION    - used by decode function
# PARALLEL_SERVER_STORAGE_CONSTRUCTOR - used by decode function
# PARALLEL_SERVER_JOB_LOCATION        - used by decode function

# The following environment variables are set by Slurm
# SLURM_JOB_ID         - number of nodes allocated to Slurm job
# SLURM_JOB_NUM_NODES  - number of hosts allocated to Slurm job
# SLURM_JOB_NODELIST   - list of hostnames allocated to Slurm job
# SLURM_TASKS_PER_NODE - list containing number of tasks allocated per host to Slurm job

# Copyright 2015-2022 The MathWorks, Inc.

# load modules 
module purge
module load Stages/2024
module load GCC
module load ParaStationMPI
module load MATLAB
export LD_LIBRARY_PATH=/p/software/juwels/stages/2024/software/X11/20230603-GCCcore-12.3.0/lib64:$LD_LIBRARY_PATH

if [ ! $TZ ] ; then
    export TZ=$(timedatectl | grep "Time zone" | cut -d ":" -f2 | cut -d " " -f2)
fi

# If PARALLEL_SERVER_ environment variables are not set, assign any
# available values with form MDCE_ for backwards compatibility
PARALLEL_SERVER_CMR=${PARALLEL_SERVER_CMR:="${MDCE_CMR}"}
PARALLEL_SERVER_MATLAB_EXE=${PARALLEL_SERVER_MATLAB_EXE:="${MDCE_MATLAB_EXE}"}
PARALLEL_SERVER_MATLAB_ARGS=${PARALLEL_SERVER_MATLAB_ARGS:="${MDCE_MATLAB_ARGS}"}

# Users of Slurm older than v1.1.34 should uncomment the following code
# to enable mapping from old Slurm environment variables:

# SLURM_JOB_ID=${SLURM_JOBID}
# SLURM_JOB_NUM_NODES=${SLURM_NNODES}
# SLURM_JOB_NODELIST=${SLURM_NODELIST}

#########################################################################################
# Shut down SMPDs and exit with the exit code of the last command executed
cleanupAndExit() {
    EXIT_CODE=${?}

    echo "Exiting with code: ${EXIT_CODE}"
    exit ${EXIT_CODE}
}

#########################################################################################
runMpiexec() {

    ENVS_TO_FORWARD="PARALLEL_SERVER_DECODE_FUNCTION,PARALLEL_SERVER_STORAGE_LOCATION,PARALLEL_SERVER_STORAGE_CONSTRUCTOR,PARALLEL_SERVER_JOB_LOCATION,PARALLEL_SERVER_DEBUG,PARALLEL_SERVER_LICENSE_NUMBER,MLM_WEB_LICENSE,MLM_WEB_USER_CRED,MLM_WEB_ID"
    LEGACY_ENVS_TO_FORWARD="MDCE_DECODE_FUNCTION,MDCE_STORAGE_LOCATION,MDCE_STORAGE_CONSTRUCTOR,MDCE_JOB_LOCATION,MDCE_DEBUG,MDCE_LICENSE_NUMBER"

    CMD="srun \"${PARALLEL_SERVER_MATLAB_EXE}\" ${PARALLEL_SERVER_MATLAB_ARGS}"

    # As a debug stage: echo the command ...
    echo $CMD

    # ... and then execute it.
    eval $CMD

    MPIEXEC_CODE=${?}
    if [ ${MPIEXEC_CODE} -ne 0 ] ; then
        exit ${MPIEXEC_CODE}
    fi
}

#########################################################################################
# Define the order in which we execute the stages defined above
MAIN() {
    # Install a trap to ensure that SMPDs are closed if something errors or the
    # job is cancelled.
    trap "cleanupAndExit" 0 1 2 15
    runMpiexec
    exit 0 # Explicitly exit 0 to trigger cleanupAndExit
}

# Call the MAIN loop
MAIN
