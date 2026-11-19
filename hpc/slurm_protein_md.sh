#!/usr/bin/env bash
# =============================================================================
# SLURM Job Script: Protein-Only GROMACS MD (SNIC / Tetralith / MPI Clusters)
# =============================================================================
# Customize the #SBATCH directives (time, nodes, account, job name) and the
# `module load` line for your HPC cluster before submitting:
#
#   sbatch slurm_protein_md.sh
#
# Prerequisites in the working directory:
#   - One input .pdb file (set INPUT_PDB below)
#   - ions.mdp, minim.mdp, nvt.mdp, npt.mdp, md.mdp
# =============================================================================

#SBATCH --time=01:00:00
#SBATCH -N 4
#SBATCH -c 4
#SBATCH --account=snic2020-1-40
#SBATCH -J amyloid
#SBATCH --exclusive
#SBATCH --ntasks-per-node=32

set -euo pipefail

export OMP_NUM_THREADS=4
module load GROMACS/2019.6-nsc1-gcc-7.3.0-bare

# Input PDB file (defaults to the first *.pdb in the directory)
INPUT_PDB="${INPUT_PDB:-$(ls *.pdb | head -n 1)}"
MPPRUN_PASS="--map-by ppr:$((16 / OMP_NUM_THREADS)):socket:PE=${OMP_NUM_THREADS}"

# 1. Generate topology and box
printf "1\n1\n" | gmx_mpi pdb2gmx -f "${INPUT_PDB}" -o peptide.gro
gmx_mpi editconf -f peptide.gro -o pep_box.gro -c -d 1.0 -bt cubic
gmx_mpi solvate -cp pep_box.gro -cs spc216.gro -o solv.gro -p topol.top

# 2. Prepare ions (uncomment genion below if your system has a net charge)
gmx_mpi grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr -maxwarn -1
# printf "13\n" | gmx_mpi genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral

# 3. Energy minimization (switch solv.gro -> solv_ions.gro if genion was run)
gmx_mpi grompp -f minim.mdp -c solv.gro -p topol.top -o em.tpr -maxwarn -1
mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -v -deffnm em

# 4. NVT equilibration
gmx_mpi grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr -maxwarn -1
mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -deffnm nvt

# 5. NPT equilibration
gmx_mpi grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr -maxwarn -1
mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -deffnm npt

# 6. Production MD
gmx_mpi grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr -maxwarn -1
mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -deffnm md_0_1

# 7. Center trajectory and remove PBC jumps (Group 1 = Protein, Group 0 = System)
printf "1\n0\n" | gmx_mpi trjconv \
    -s md_0_1.tpr \
    -f md_0_1.xtc \
    -o md_0_1_center.xtc \
    -center -pbc mol -ur compact

# Optional: Extend an existing simulation by 100 ns (100000 ps):
#   gmx_mpi convert-tpr -s md_0_1.tpr -extend 100000 -o next.tpr
#   mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -s next.tpr -deffnm md_0_1 -cpi md_0_1.cpt -append
