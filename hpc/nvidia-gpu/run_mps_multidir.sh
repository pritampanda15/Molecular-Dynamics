#!/usr/bin/env bash
# =============================================================================
# Multi-Simulation GPU Throughput Runner with NVIDIA CUDA MPS
# =============================================================================
# Runs multiple independent GROMACS simulations concurrently on a single GPU
# using NVIDIA Multi-Process Service (MPS) and non-overlapping CPU core pinning
# (`-pin on -pinoffset`), following NVIDIA's MPS/MIG throughput guide.
#
# Prerequisites:
#   - Simulation subdirectories passed as arguments (each containing `<DEFFNM>.tpr`)
#   - `nvidia-cuda-mps-control` available in PATH
#
# Usage:
#   chmod +x run_mps_multidir.sh
#   ./run_mps_multidir.sh sim_0 sim_1 sim_2 sim_3
#
# Optional environment overrides:
#   GPU_ID=0 NTOMP=4 DEFFNM=md_0_1 GMX=gmx MODE=independent ./run_mps_multidir.sh sim_0 sim_1 sim_2 sim_3
#   GPU_ID=0 NTOMP=4 DEFFNM=md_0_1 GMX=gmx_mpi MODE=multidir ./run_mps_multidir.sh sim_0 sim_1 sim_2 sim_3
# =============================================================================

set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <sim_dir_1> [sim_dir_2 ...]" >&2
    exit 1
fi

SIM_DIRS=("$@")
NUM_SIMS="${#SIM_DIRS[@]}"

GPU_ID="${GPU_ID:-0}"
NTOMP="${NTOMP:-4}"                    # OpenMP threads per simulation (keep NUM_SIMS * NTOMP <= physical cores)
DEFFNM="${DEFFNM:-md_0_1}"             # TPR / output prefix inside each simulation directory
GMX="${GMX:-gmx}"                      # Use `gmx` for MODE=independent, `gmx_mpi` for MODE=multidir
MODE="${MODE:-independent}"            # independent (thread-MPI + pinoffset) | multidir (mpirun + gmx_mpi)
BASE_PINOFFSET="${BASE_PINOFFSET:-0}"  # Starting CPU core index

export CUDA_VISIBLE_DEVICES="${GPU_ID}"
export CUDA_MPS_PIPE_DIRECTORY="${CUDA_MPS_PIPE_DIRECTORY:-/tmp/nvidia-mps-${USER}-gpu${GPU_ID}}"
export CUDA_MPS_LOG_DIRECTORY="${CUDA_MPS_LOG_DIRECTORY:-/tmp/nvidia-mps-log-${USER}-gpu${GPU_ID}}"
export GMX_ENABLE_DIRECT_GPU_COMM=1

mkdir -p "${CUDA_MPS_PIPE_DIRECTORY}" "${CUDA_MPS_LOG_DIRECTORY}"

cleanup() {
    echo "Stopping NVIDIA CUDA MPS daemon..."
    echo quit | nvidia-cuda-mps-control >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Starting NVIDIA CUDA MPS daemon on GPU ${GPU_ID}..."
nvidia-cuda-mps-control -d

case "${MODE}" in
    independent)
        echo "Launching ${NUM_SIMS} independent GPU-resident simulations (${NTOMP} OpenMP threads each)..."
        pids=()
        for idx in "${!SIM_DIRS[@]}"; do
            dir="${SIM_DIRS[$idx]}"
            offset=$((BASE_PINOFFSET + idx * NTOMP))
            echo "  [${idx}] ${dir} -> GPU ${GPU_ID}, pinoffset=${offset}, ntomp=${NTOMP}"
            (
                cd "${dir}"
                "${GMX}" mdrun -deffnm "${DEFFNM}" \
                    -ntmpi 1 -ntomp "${NTOMP}" \
                    -nb gpu -pme gpu -bonded gpu -update gpu \
                    -pin on -pinoffset "${offset}"
            ) &
            pids+=("$!")
        done

        status=0
        for pid in "${pids[@]}"; do
            if ! wait "${pid}"; then
                status=1
            fi
        done
        exit "${status}"
        ;;
    multidir)
        echo "Launching ${NUM_SIMS} simulations via mpirun + -multidir (${NTOMP} OpenMP threads per rank)..."
        mpirun -np "${NUM_SIMS}" "${GMX}" mdrun \
            -multidir "${SIM_DIRS[@]}" \
            -deffnm "${DEFFNM}" \
            -ntomp "${NTOMP}" \
            -nb gpu -pme gpu -bonded gpu -update gpu \
            -pin on -pinoffset "${BASE_PINOFFSET}"
        ;;
    *)
        echo "Error: Unsupported MODE='${MODE}'. Use 'independent' or 'multidir'." >&2
        exit 1
        ;;
esac
