# Protein-Only MD Workflow

Complete GROMACS pipeline for simulating a solvated protein in water: topology generation, box definition, solvation, ion neutralization, energy minimization, NVT/NPT equilibration, and production MD.

## Files

- [`run_protein_md.sh`](run_protein_md.sh) — Runnable Bash script for a local workstation or interactive compute node.
- For SLURM HPC clusters, see [`../../hpc/slurm_protein_md.sh`](../../hpc/slurm_protein_md.sh).

## Prerequisites

Place the following files in your simulation directory before running `run_protein_md.sh`:
- `protein.pdb` (cleaned receptor structure)
- `ions.mdp`, `minim.mdp`, `nvt.mdp`, `npt.mdp`, `md.mdp`

## Quick Start

```bash
chmod +x run_protein_md.sh
./run_protein_md.sh
```

Override defaults with environment variables when needed:

```bash
GMX=gmx_mpi PDB=my_protein.pdb FORCEFIELD_CHOICE=15 BOX_DISTANCE=1.0 ./run_protein_md.sh
```

> **Note:** Check the force field index (`FORCEFIELD_CHOICE`) and solvent group index (`SOLVENT_GROUP`) printed by `gmx pdb2gmx` and `gmx genion` for your installed GROMACS version.
