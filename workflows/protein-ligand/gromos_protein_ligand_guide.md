# Protein–Ligand Complex MD Guide (GROMOS96 / ATB or PRODRG)

Step-by-step commands for setting up, running, and post-processing a protein–ligand complex in GROMACS using a GROMOS96 force field and ligand topologies from [ATB](https://atb.uq.edu.au/) or PRODRG.

---

## 1. Prepare Protein and Ligand Topologies

Extract the ligand (`UNL`) from your cleaned complex PDB and generate the protein topology:

```bash
grep UNL clean.pdb > UNL.pdb
gmx_mpi pdb2gmx -f clean.pdb -o protein_processed.gro
```

Generate the ligand topology (`UNL.itp`) and coordinates from `UNL.pdb` using **ATB** or **PRODRG**, then convert the ligand coordinates to `.gro`:

```bash
gmx_mpi editconf -f UNL.pdb -o UNL.gro
```

### Combine Protein and Ligand Coordinates
1. Copy `protein_processed.gro` to `complex.gro`.
2. Append the atom coordinate lines from `UNL.gro` to `complex.gro` (before the final box-vector line).
3. Update the total atom count on line 2 of `complex.gro`.

### Update `topol.top`
Include the ligand topology and add `UNL` under `[ molecules ]`:

```text
; Include ligand topology
#include "UNL.itp"

[ molecules ]
; Compound        #mols
Protein_chain_A     1
UNL                 1
```

---

## 2. Define Box, Solvate, and Add Ions

```bash
gmx_mpi editconf -f complex.gro -o newbox.gro -bt cubic -d 1.0
gmx_mpi solvate -cp newbox.gro -cs spc216.gro -p topol.top -o solv.gro

# Note: Ligand residue name must match the name defined in UNL.itp
gmx_mpi grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr -maxwarn 2
gmx_mpi genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral
```

---

## 3. Energy Minimization

```bash
gmx_mpi grompp -f em.mdp -c solv_ions.gro -p topol.top -o em.tpr -maxwarn 2
```

For quick testing on an interactive SNIC/Tetralith node:
```bash
interactive -A snic2021-1-42 -t 1:00:00 --reservation=devel -N 2
```

Or submit as a SLURM batch job (`run_em.sh`):

```bash
#!/usr/bin/env bash
#SBATCH --time=01:00:00
#SBATCH -N 4
#SBATCH -c 4
#SBATCH --account=snic2020-1-40
#SBATCH -J em_complex
#SBATCH --exclusive
#SBATCH --ntasks-per-node=32

export OMP_NUM_THREADS=4
module load GROMACS/2019.2-nsc1-gcc-7.3.0-bare

mpprun --pass="--map-by ppr:$((16/OMP_NUM_THREADS)):socket:PE=${OMP_NUM_THREADS}" \
    gmx_mpi mdrun -deffnm em
```

---

## 4. Ligand Position Restraints & Index Groups

Create a heavy-atom index for the ligand and generate position restraints:

```bash
gmx_mpi make_ndx -f UNL.gro -o index_UNL.ndx
# Interactive prompt:
# > 0 & ! a H*
# > q

gmx_mpi genrestr -f UNL.gro -n index_UNL.ndx -o posre_UNL.itp -fc 1000 1000 1000
# Choose the heavy-atom group (e.g., 3)
```

Add the restraint include to `topol.top` right after `#include "UNL.itp"`:

```text
; Ligand position restraints
#ifdef POSRES
#include "posre_UNL.itp"
#endif
```

Create a combined `Protein_UNL` coupling group for temperature/pressure control:

```bash
gmx_mpi make_ndx -f em.gro -o index.ndx
# Interactive prompt:
# > 1 | 13
# > q
```

---

## 5. Equilibration (NVT, NPT) and Production MD

Prepare the NVT input:

```bash
gmx_mpi grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -n index.ndx -o nvt.tpr -maxwarn 2
```

Submit NVT, NPT, and Production MD via SLURM (`run_md.sh`):

```bash
#!/usr/bin/env bash
#SBATCH --time=24:00:00
#SBATCH -N 4
#SBATCH -c 4
#SBATCH --account=snic2020-1-40
#SBATCH -J protein_ligand_md
#SBATCH --exclusive
#SBATCH --ntasks-per-node=32

export OMP_NUM_THREADS=4
module load GROMACS/2019.2-nsc1-gcc-7.3.0-bare

MPPRUN_PASS="--map-by ppr:$((16/OMP_NUM_THREADS)):socket:PE=${OMP_NUM_THREADS}"

# NVT equilibration
mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -deffnm nvt

# NPT equilibration
gmx_mpi grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -n index.ndx -o npt.tpr -maxwarn 2
mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -deffnm npt

# Production MD
gmx_mpi grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -n index.ndx -o md_0_1.tpr -maxwarn 2
mpprun --pass="${MPPRUN_PASS}" gmx_mpi mdrun -deffnm md_0_1
```

---

## 6. Post-Processing & RMSD Analysis

```bash
# Center trajectory on Protein (1) and output System (0)
printf "1\n0\n" | gmx_mpi trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_center.xtc -center -pbc mol -ur compact

# Remove rotational/translational motion
gmx_mpi trjconv -s md_0_1.tpr -f md_0_1_center.xtc -o md_0_1_fit.xtc -fit rot+trans

# Remove PBC jumps without compacting
gmx_mpi trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_noPBC.xtc -pbc mol -center

# Protein and ligand RMSD calculations
gmx_mpi rms -s em.tpr -f md_0_1_center.xtc -n index.ndx -tu ns -o rmsd_protein.xvg
gmx_mpi rms -s md_0_1.tpr -f md_0_1_noPBC.xtc -o rmsd.xvg -tu ns
gmx_mpi rms -s em.tpr -f md_0_1_center.xtc -n index.ndx -tu ns -o rmsd_unl.xvg

# Extract first frame (t = 0 ns) as PDB
gmx_mpi trjconv -s md_0_1.tpr -f md_0_1_center.xtc -o start.pdb -dump 0
```
