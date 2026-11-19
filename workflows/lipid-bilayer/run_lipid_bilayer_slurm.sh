#!/usr/bin/env bash
# =============================================================================
# SLURM Job Script: Asymmetric Mammalian Plasma Membrane (PMm) MD Simulation
# =============================================================================
# Runs energy minimization, 6-stage CHARMM-GUI equilibration, and production MD
# for the asymmetric mammalian plasma membrane system in this directory.
#
# System Summary:
#   - Lipids: 107 outer leaflet / 100 inner leaflet (POPC, PLPC, PAPE, POPE,
#     POPI, PAPS, POPA, SSM, NSM, CMH/GLPA, CHL1)
#   - Box size: ~75.26 x 75.26 x 122.17 A^3
#   - Temperature: 310.15 K
#
# Usage:
#   Customize the #SBATCH directives and `module load` for your cluster, then:
#   sbatch run_lipid_bilayer_slurm.sh
# =============================================================================

#SBATCH --time=24:00:00
#SBATCH -N 4
#SBATCH -c 4
#SBATCH --account=snic2021-1-42
#SBATCH -J Lipid
#SBATCH --exclusive
#SBATCH --ntasks-per-node=32

set -euo pipefail

export OMP_NUM_THREADS=4
module load GROMACS/2019.6-nsc1-gcc-7.3.0-bare

MPPRUN_PASS="--map-by ppr:$((16 / OMP_NUM_THREADS)):socket:PE=${OMP_NUM_THREADS}"

# 1. Energy Minimization
gmx_mpi grompp \
    -f step6.0_minimization.mdp \
    -o minimization.tpr \
    -c step5_input.gro \
    -r step5_input.gro \
    -p topol.top \
    -n index.ndx
mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -v -deffnm minimization

# 2. Six-Stage Equilibration (step6.1 .. step6.6)
prev_gro="minimization.gro"
for step in 1 2 3 4 5 6; do
    stage="step6.${step}_equilibration"
    gmx_mpi grompp \
        -f "${stage}.mdp" \
        -o "${stage}.tpr" \
        -c "${prev_gro}" \
        -r step5_input.gro \
        -p topol.top \
        -n index.ndx
    mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -v -deffnm "${stage}"
    prev_gro="${stage}.gro"
done

# 3. Production MD
gmx_mpi grompp \
    -f step7_production.mdp \
    -o md.tpr \
    -c step6.6_equilibration.gro \
    -p topol.top \
    -n index.ndx
mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -v -deffnm md

# Optional: Extend production run by 100 ns:
#   gmx_mpi convert-tpr -s md.tpr -extend 100000 -o next.tpr
#   mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -s next.tpr -deffnm md -cpi md.cpt -append
