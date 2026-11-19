# HPC & SLURM Job Scripts

Reusable SLURM job submission templates and multi-directory batch scripts originally configured for SNIC/NAISS Tetralith clusters.

## Scripts & Guides

| Script / Guide | Shell / Type | Purpose |
| :--- | :--- | :--- |
| [`slurm_protein_md.sh`](slurm_protein_md.sh) | Bash (SLURM) | Full protein-only GROMACS workflow (pdb2gmx → solvate → EM → NVT → NPT → Production → PBC centering) |
| [`slurm_charmm_gui.csh`](slurm_charmm_gui.csh) | C Shell (SLURM) | CHARMM-GUI GROMACS runner (`step6.0` minimization, 6-step equilibration `step6.1`–`step6.6`, 10-segment production `step7_1`–`step7_10`) |
| [`batch_postprocess.sh`](batch_postprocess.sh) | Bash | Loops over all subdirectories containing `md_0_1.{tpr,xtc}` to run PBC centering, snapshot extraction, and backbone RMSD |
| [`nvidia-gpu/`](nvidia-gpu/) | Guide + Bash | NVIDIA NGC GROMACS container (Docker & Singularity/Apptainer), full GPU offload (`-nb/-pme/-bonded/-update gpu`), multi-GPU direct comms, and MPS/MIG throughput scaling |

See also [`../workflows/lipid-bilayer/run_lipid_bilayer_slurm.sh`](../workflows/lipid-bilayer/run_lipid_bilayer_slurm.sh) for the plasma-membrane SLURM script.

## Before Submitting

Always update these cluster-specific lines at the top of each SLURM script:
1. `#SBATCH --account=...` — your HPC allocation ID
2. `#SBATCH --time=...`, `-N`, `-c`, `--ntasks-per-node` — walltime and node geometry
3. `module load GROMACS/...` — GROMACS module installed on your cluster
4. `mpprun` — replace with `srun` or `mpirun` if your cluster does not use NSC's `mpprun` wrapper

## Useful SLURM One-Liners

```bash
# Submit jobs across every subdirectory
for d in */; do (cd "$d" && sbatch run.sh); done

# Copy a script into every subdirectory
for d in */; do cp runextend.sh "$d"; done

# Monitor or cancel jobs
squeue -u "$USER"
scontrol show job <JOB_ID>
scancel <JOB_ID>
```
