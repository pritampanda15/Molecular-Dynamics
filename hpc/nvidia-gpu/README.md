# NVIDIA GPU-Accelerated GROMACS (NGC Containers, GPU Offload, MPS & MIG)

Instructions and ready-to-use scripts for running high-throughput **GROMACS** simulations on NVIDIA GPUs, based on official NVIDIA NGC and Developer documentation:

- [NVIDIA NGC GROMACS Container Catalog](https://catalog.ngc.nvidia.com/orgs/hpc/-/containers/gromacs/-?_lr=1)
- [Creating Faster Molecular Dynamics Simulations with GROMACS 2020](https://developer.nvidia.com/blog/creating-faster-molecular-dynamics-simulations-with-gromacs-2020/)
- [Maximizing GROMACS Throughput with Multiple Simulations per GPU Using MPS and MIG](https://developer.nvidia.com/blog/maximizing-gromacs-throughput-with-multiple-simulations-per-gpu-using-mps-and-mig/)

## Included Scripts

| Script | Purpose |
| :--- | :--- |
| [`run_ngc_gromacs.sh`](run_ngc_gromacs.sh) | Launches GPU-resident `gmx mdrun` via the official NGC container (`nvcr.io/hpc/gromacs`) using Docker or Singularity/Apptainer |
| [`run_mps_multidir.sh`](run_mps_multidir.sh) | Runs multiple concurrent simulations on a shared GPU using NVIDIA CUDA MPS and GROMACS `-multidir` / `-pinoffset` |

---

## 1. Running the Official NVIDIA NGC GROMACS Container

NVIDIA publishes pre-optimized, CUDA-enabled GROMACS images on NGC (`nvcr.io/hpc/gromacs`). Check the [NGC GROMACS catalog](https://catalog.ngc.nvidia.com/orgs/hpc/-/containers/gromacs/-?_lr=1) for available version tags (e.g., `2023.2`, `2022.1`, or the latest release).

### Option A: Docker (Workstations & Cloud Nodes)

Requires Docker and the NVIDIA Container Toolkit.

```bash
export GROMACS_TAG=2023.2

# Interactive shell with all GPUs and current directory mounted
docker run --gpus all --ipc=host -it --rm \
    -v "${PWD}:/host_pwd" \
    --workdir /host_pwd \
    "nvcr.io/hpc/gromacs:${GROMACS_TAG}"

# Non-interactive single-GPU run
docker run --gpus '"device=0"' --ipc=host --rm \
    -e GMX_ENABLE_DIRECT_GPU_COMM=1 \
    -v "${PWD}:/host_pwd" \
    --workdir /host_pwd \
    "nvcr.io/hpc/gromacs:${GROMACS_TAG}" \
    gmx mdrun -v -deffnm md_0_1 -ntmpi 1 -ntomp 8 -nb gpu -pme gpu -bonded gpu -update gpu
```

### Option B: Singularity / Apptainer (HPC Clusters)

HPC clusters typically use Singularity or Apptainer instead of Docker because they do not require root privileges.

```bash
export GROMACS_TAG=2023.2

# 1. Pull and build a local .sif image (one-time step)
# (If your registry requires NGC auth, set SINGULARITY_DOCKER_USERNAME='$oauthtoken'
#  and SINGULARITY_DOCKER_PASSWORD=<your-ngc-api-key> first.)
singularity build "gromacs_${GROMACS_TAG}.sif" "docker://nvcr.io/hpc/gromacs:${GROMACS_TAG}"

# 2. Run GROMACS with GPU passthrough (--nv)
export GMX_ENABLE_DIRECT_GPU_COMM=1
singularity run --nv \
    -B "${PWD}:/host_pwd" \
    --pwd /host_pwd \
    "gromacs_${GROMACS_TAG}.sif" \
    gmx mdrun -v -deffnm md_0_1 -ntmpi 1 -ntomp 8 -nb gpu -pme gpu -bonded gpu -update gpu
```

> Or use the wrapper script: `RUNTIME=singularity IMAGE=gromacs_2023.2.sif ./run_ngc_gromacs.sh md_0_1`.

---

## 2. Full GPU Offload & Multi-GPU Acceleration

Starting with GROMACS 2020, the entire MD timestep—short-range non-bonded forces, bonded forces, long-range PME electrostatics, coordinate/velocity updates, and constraints—can stay resident on NVIDIA GPUs, eliminating expensive CPU–GPU memory transfers every step.

### Key `gmx mdrun` GPU Flags

| Flag | What It Offloads to the GPU |
| :--- | :--- |
| `-nb gpu` | Short-range non-bonded interactions |
| `-pme gpu` | Particle Mesh Ewald (PME) long-range electrostatics (via cuFFT) |
| `-bonded gpu` | Bonded interactions (bonds, angles, dihedrals) |
| `-update gpu` | Coordinate/velocity integration and constraints (LINCS/SETTLE), keeping simulation state GPU-resident |
| `-npme 1` | Dedicates 1 rank to PME for balanced multi-GPU scaling |
| `-pin on` | Pins OpenMP/MPI threads to physical CPU cores to prevent OS thread migration |

### Recommended `.mdp` Settings for GPU-Resident Runs

- Use **`constraints = h-bonds`** (instead of `all-bonds`) so GROMACS can construct update groups required by `-update gpu`.
- Increase **`nstlist`** (e.g., `nstlist = 40` in `.mdp`, or override at runtime with `-nstlist 100` to `200` on modern GPUs) to reduce neighbor-list search frequency and improve GPU utilization.

### Single-GPU Command (GPU-Resident)

```bash
gmx mdrun -v -deffnm md_0_1 \
    -ntmpi 1 -ntomp 8 \
    -nb gpu -pme gpu -bonded gpu -update gpu \
    -pin on
```

### Multi-GPU Command (Direct GPU-to-GPU Communications)

To avoid staging halo exchanges and PME–PP transfers through CPU host memory, enable direct GPU communication:

- **GROMACS 2022+ (recommended):**
  ```bash
  export GMX_ENABLE_DIRECT_GPU_COMM=1
  ```
- **GROMACS 2020–2021 (legacy variable names):**
  ```bash
  export GMX_GPU_DD_COMMS=true
  export GMX_GPU_PME_PP_COMMS=true
  export GMX_FORCE_UPDATE_DEFAULT_GPU=true
  ```

Example across **4 GPUs** on a single node (3 PP ranks + 1 dedicated PME rank, 8 OpenMP threads per rank):

```bash
export GMX_ENABLE_DIRECT_GPU_COMM=1
# For GROMACS 2020-2021 also set:
# export GMX_GPU_DD_COMMS=true GMX_GPU_PME_PP_COMMS=true GMX_FORCE_UPDATE_DEFAULT_GPU=true

gmx mdrun -v -deffnm md_0_1 \
    -ntmpi 4 -ntomp 8 -npme 1 \
    -nb gpu -pme gpu -bonded gpu -update gpu \
    -pin on
```

---

## 3. Maximizing Throughput: Multiple Simulations per GPU (MPS & MIG)

Modern data-center GPUs (V100, A100, H100, A40, etc.) are often underutilized by a single small-to-medium biomolecular system (< ~100K–400K atoms). Running **multiple replicas or independent ensembles concurrently on one GPU** can dramatically increase aggregate ns/day throughput.

### MPS vs. MIG at a Glance

| Feature | NVIDIA CUDA MPS | NVIDIA MIG |
| :--- | :--- | :--- |
| **Hardware support** | Any NVIDIA GPU (Volta, Turing, Ampere, Hopper, Ada, etc.) | Ampere A100/A30, Hopper H100/H200, and newer MIG-capable GPUs |
| **How it works** | Software service allowing concurrent GPU kernels from multiple host processes without heavy context switching | Hardware-level partitioning of one physical GPU into isolated GPU instances with dedicated SMs, cache, and memory |
| **Privileges needed** | Standard user can start `nvidia-cuda-mps-control -d` per job | Requires admin/root privileges (`sudo nvidia-smi`) to configure partitions |
| **Best for** | Flexible oversubscription (2–8+ sims/GPU) and dynamic load sharing | Strict memory/compute fault isolation across multi-tenant HPC jobs |

---

### Option A: Running Multiple Simulations with CUDA MPS

1. **Start the MPS control daemon** (pointing at GPU 0, or whichever GPUs are allocated):
   ```bash
   export CUDA_VISIBLE_DEVICES=0
   export CUDA_MPS_PIPE_DIRECTORY=/tmp/nvidia-mps
   export CUDA_MPS_LOG_DIRECTORY=/tmp/nvidia-log
   mkdir -p "${CUDA_MPS_PIPE_DIRECTORY}" "${CUDA_MPS_LOG_DIRECTORY}"
   nvidia-cuda-mps-control -d
   ```

2. **Launch concurrent simulations** using either:
   - **GROMACS native `-multidir` (with MPI-enabled `gmx_mpi`):**
     Place `md_0_1.tpr` inside `sim_0/`, `sim_1/`, `sim_2/`, `sim_3/` and run 4 simulations concurrently on 1 GPU (with 4 OpenMP threads each = 16 CPU cores total):
     ```bash
     mpirun -np 4 gmx_mpi mdrun \
         -multidir sim_0 sim_1 sim_2 sim_3 \
         -deffnm md_0_1 \
         -ntomp 4 -nb gpu -pme gpu -bonded gpu -update gpu -pin on
     ```
   - **Independent background `gmx` processes (with explicit `-pinoffset`):**
     When launching separate `gmx` processes on the same node, always pass non-overlapping `-pinoffset` values so CPU threads do not fight for the same cores:
     ```bash
     NTOMP=4
     for i in 0 1 2 3; do
         offset=$((i * NTOMP))
         (
             cd "sim_${i}"
             gmx mdrun -deffnm md_0_1 \
                 -ntmpi 1 -ntomp "${NTOMP}" \
                 -nb gpu -pme gpu -bonded gpu -update gpu \
                 -pin on -pinoffset "${offset}"
         ) &
     done
     wait
     ```

3. **Shut down the MPS daemon** after your jobs finish:
   ```bash
   echo quit | nvidia-cuda-mps-control
   ```

> See [`run_mps_multidir.sh`](run_mps_multidir.sh) for a ready-to-run script that handles MPS startup, `-pinoffset` pinning, and clean shutdown automatically.

---

### Option B: Partitioning an A100 / H100 GPU with NVIDIA MIG

On MIG-capable GPUs (e.g., NVIDIA A100 / H100), administrators can partition a physical GPU into hardware-isolated instances:

```bash
# 1. Enable MIG mode on GPU 0 (requires root/sudo)
sudo nvidia-smi -i 0 -mig 1

# 2. List supported MIG profiles (e.g., 1g.5gb, 2g.10gb, 3g.20gb on A100-40GB; 1g.10gb on A100-80GB)
nvidia-smi mig -lgip

# 3. Create GPU instances and compute instances (-C)
# Example: 4 slices of profile ID 14 (or use named profiles such as 1g.10gb, 2g.20gb)
sudo nvidia-smi mig -i 0 -cgi 1g.10gb,1g.10gb,1g.10gb,1g.10gb -C

# 4. List the created MIG device UUIDs
nvidia-smi -L
```

Assign each GROMACS simulation to its own MIG UUID via `CUDA_VISIBLE_DEVICES` and non-overlapping `-pinoffset`:

```bash
# Example launching 2 simulations on 2 distinct MIG instances:
CUDA_VISIBLE_DEVICES="MIG-<uuid-0>" gmx mdrun -s sim_0/md.tpr -deffnm sim_0/md \
    -ntmpi 1 -ntomp 4 -nb gpu -pme gpu -bonded gpu -update gpu -pin on -pinoffset 0 &

CUDA_VISIBLE_DEVICES="MIG-<uuid-1>" gmx mdrun -s sim_1/md.tpr -deffnm sim_1/md \
    -ntmpi 1 -ntomp 4 -nb gpu -pme gpu -bonded gpu -update gpu -pin on -pinoffset 4 &

wait
```

To reset MIG partitions when done (requires root/sudo):

```bash
sudo nvidia-smi mig -i 0 -dci
sudo nvidia-smi mig -i 0 -dgi
sudo nvidia-smi -i 0 -mig 0
```
