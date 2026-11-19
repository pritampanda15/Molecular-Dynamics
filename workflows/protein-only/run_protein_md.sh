#!/usr/bin/env bash
# =============================================================================
# Protein-Only Molecular Dynamics Workflow (GROMACS)
# =============================================================================
# Runs a complete protein-in-water GROMACS workflow:
#   pdb2gmx -> editconf -> solvate -> genion -> EM -> NVT -> NPT -> Production MD
#
# Prerequisites in the working directory:
#   - protein.pdb
#   - ions.mdp, minim.mdp, nvt.mdp, npt.mdp, md.mdp
#
# Usage:
#   chmod +x run_protein_md.sh
#   ./run_protein_md.sh
#
# Optional environment overrides:
#   GMX=gmx_mpi PDB=my_protein.pdb ./run_protein_md.sh
# =============================================================================

set -euo pipefail

# Uncomment and adjust if running on an HPC cluster with environment modules:
# module load gromacs/5.1.2

GMX="${GMX:-gmx}"
PDB="${PDB:-protein.pdb}"
FORCEFIELD_CHOICE="${FORCEFIELD_CHOICE:-5}"  # e.g., 5 = OPLS-AA (verify for your GROMACS version)
WATER_MODEL="${WATER_MODEL:-spce}"
BOX_DISTANCE="${BOX_DISTANCE:-0.5}"          # nm from protein to box wall (commonly 0.5–1.0 nm)
SOLVENT_GROUP="${SOLVENT_GROUP:-13}"         # SOL group index in genion (verify for your system)

# 1. Convert PDB to GROMACS structure & topology (ignoring original hydrogens)
printf "%s\n1\n" "${FORCEFIELD_CHOICE}" | "${GMX}" pdb2gmx \
    -f "${PDB}" \
    -o protein_processed.gro \
    -water "${WATER_MODEL}" \
    -ignh

# 2. Define a cubic simulation box centered on the protein
"${GMX}" editconf \
    -f protein_processed.gro \
    -o protein_newbox.gro \
    -c -d "${BOX_DISTANCE}" -bt cubic

# 3. Solvate with SPC/E water (spc216.gro)
"${GMX}" solvate \
    -cp protein_newbox.gro \
    -cs spc216.gro \
    -o protein_solv.gro \
    -p topol.top

# 4. Add counter-ions to neutralize the system
"${GMX}" grompp -f ions.mdp -c protein_solv.gro -p topol.top -o ions.tpr
printf "%s\n" "${SOLVENT_GROUP}" | "${GMX}" genion \
    -s ions.tpr \
    -o protein_solv_ions.gro \
    -p topol.top \
    -neutral

# 5. Energy minimization
"${GMX}" grompp -f minim.mdp -c protein_solv_ions.gro -p topol.top -o em.tpr
"${GMX}" mdrun -v -deffnm em

# 6. NVT equilibration (temperature coupling)
"${GMX}" grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
"${GMX}" mdrun -v -deffnm nvt

# 7. NPT equilibration (pressure coupling)
"${GMX}" grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
"${GMX}" mdrun -v -deffnm npt

# 8. Production MD
"${GMX}" grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr
"${GMX}" mdrun -v -deffnm md_0_1

# -----------------------------------------------------------------------------
# Optional: Restart a crashed or interrupted production run from checkpoint:
#   ${GMX} mdrun -s md_0_1.tpr -cpi md_0_1.cpt -deffnm md_0_1 -append
#
# Optional: Extract snapshots every 100 frames (requires index.ndx):
#   ${GMX} trjconv -f md_0_1.xtc -o _pro.gro -s md_0_1.tpr -n index.ndx -sep -center -skip 100
# -----------------------------------------------------------------------------
