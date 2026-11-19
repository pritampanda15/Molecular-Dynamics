#!/usr/bin/env bash
# =============================================================================
# Run GPU-Accelerated GROMACS via the Official NVIDIA NGC Container
# =============================================================================
# Supports Docker (workstations/cloud) and Singularity/Apptainer (HPC clusters)
# using NVIDIA's NGC GROMACS image (`nvcr.io/hpc/gromacs`).
#
# Usage:
#   chmod +x run_ngc_gromacs.sh
#   ./run_ngc_gromacs.sh [DEFFNM]
#
# Examples:
#   # Single GPU with Docker (default)
#   ./run_ngc_gromacs.sh md_0_1
#
#   # 4 GPUs (3 PP + 1 PME) with Docker
#   NTMPI=4 NTOMP=8 NPME=1 GPUS=all ./run_ngc_gromacs.sh md_0_1
#
#   # Singularity / Apptainer on HPC
#   RUNTIME=singularity IMAGE=gromacs_2023.2.sif NTMPI=1 NTOMP=8 ./run_ngc_gromacs.sh md_0_1
# =============================================================================

set -euo pipefail

DEFFNM="${1:-md_0_1}"
RUNTIME="${RUNTIME:-docker}"                # docker | singularity | apptainer
GROMACS_TAG="${GROMACS_TAG:-2023.2}"        # Check https://catalog.ngc.nvidia.com/orgs/hpc/-/containers/gromacs
IMAGE="${IMAGE:-nvcr.io/hpc/gromacs:${GROMACS_TAG}}"

GPUS="${GPUS:-0}"                           # GPU ID(s) for Docker, e.g. "0", "0,1", or "all"
NTMPI="${NTMPI:-1}"                         # Thread-MPI ranks (typically = number of GPUs)
NTOMP="${NTOMP:-8}"                         # OpenMP threads per rank
NPME="${NPME:-0}"                           # Dedicated PME ranks (set 1 for multi-GPU runs)
PIN="${PIN:-on}"                            # Thread pinning: on | off | auto
EXTRA_ARGS="${EXTRA_ARGS:-}"                # Optional extra gmx mdrun flags (e.g. "-nstlist 100")

# Build mdrun argument list
MDRUN_ARGS=(
    gmx mdrun -v -deffnm "${DEFFNM}"
    -ntmpi "${NTMPI}"
    -ntomp "${NTOMP}"
    -nb gpu -pme gpu -bonded gpu -update gpu
    -pin "${PIN}"
)

if [ "${NPME}" -gt 0 ]; then
    MDRUN_ARGS+=(-npme "${NPME}")
fi

if [ -n "${EXTRA_ARGS}" ]; then
    # shellcheck disable=SC2206
    MDRUN_ARGS+=(${EXTRA_ARGS})
fi

# Direct GPU-to-GPU communication flags (GROMACS 2022+ and 2020-2021 compatibility)
export GMX_ENABLE_DIRECT_GPU_COMM=1
export GMX_GPU_DD_COMMS=true
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true

case "${RUNTIME}" in
    docker)
        if [ "${GPUS}" = "all" ]; then
            docker run --gpus all --ipc=host --rm \
                -e GMX_ENABLE_DIRECT_GPU_COMM=1 \
                -e GMX_GPU_DD_COMMS=true \
                -e GMX_GPU_PME_PP_COMMS=true \
                -e GMX_FORCE_UPDATE_DEFAULT_GPU=true \
                -v "${PWD}:/host_pwd" \
                --workdir /host_pwd \
                "${IMAGE}" \
                "${MDRUN_ARGS[@]}"
        else
            docker run --gpus "device=${GPUS}" --ipc=host --rm \
                -e GMX_ENABLE_DIRECT_GPU_COMM=1 \
                -e GMX_GPU_DD_COMMS=true \
                -e GMX_GPU_PME_PP_COMMS=true \
                -e GMX_FORCE_UPDATE_DEFAULT_GPU=true \
                -v "${PWD}:/host_pwd" \
                --workdir /host_pwd \
                "${IMAGE}" \
                "${MDRUN_ARGS[@]}"
        fi
        ;;
    singularity|apptainer)
        # If IMAGE is a docker URI and not a local .sif file, pass docker:// prefix
        CONTAINER_REF="${IMAGE}"
        if [ ! -f "${CONTAINER_REF}" ] && [[ "${CONTAINER_REF}" != docker://* ]]; then
            CONTAINER_REF="docker://${CONTAINER_REF}"
        fi
        "${RUNTIME}" run --nv \
            -B "${PWD}:/host_pwd" \
            --pwd /host_pwd \
            "${CONTAINER_REF}" \
            "${MDRUN_ARGS[@]}"
        ;;
    *)
        echo "Error: Unsupported RUNTIME='${RUNTIME}'. Use 'docker', 'singularity', or 'apptainer'." >&2
        exit 1
        ;;
esac
