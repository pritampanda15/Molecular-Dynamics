# Random Ligand Insertion with CHARMM36 & CGenFF (GROMACS)

Step-by-step guide for parameterizing a small molecule via **CGenFF** and randomly inserting multiple copies into a solvated system (e.g., a cellulose crystal layer or receptor box) using `gmx insert-molecules`.

---

## 1. Obtain and Prepare the Ligand

Download your ligand from **PubChem**, **ZINC**, or extract a docked pose from **AutoDock Vina**:

```bash
cut -c-66 XYZ_out_ligand_01 > ligand.pdb
cat receptor.pdbqt ligand.pdb | grep -v '^END ' | grep -v '^END$' > complex.pdb
```

1. Open the ligand in **Avogadro** and save it in **SYBYL `.mol2`** format (`ligand.mol2`).
2. Fix bond ordering:
   ```bash
   perl sort_mol2_bonds.pl ligand.mol2 ligand_fix.mol2
   ```
3. Upload `ligand_fix.mol2` to the **CGenFF** web server and save the resulting `.str` file.
4. Ensure the residue name matches across both `ligand_fix.mol2` and `ligand.str`:
   - In `ligand_fix.mol2`, replace `*****` under `@<TRIPOS>MOLECULE` with your residue name (e.g., `UNK`, `LIG`, or `DRG`):
     ```text
     @<TRIPOS>MOLECULE
     UNK
      18 19 0 0 0
     SMALL
     GASTEIGER
     ```
   - In `ligand.str`, update `RESI *****` to the same residue name (`RESI UNK`).

---

## 2. Convert CGenFF Parameters to GROMACS Format

Copy the `charmm36-feb2021.ff` force-field folder from the MacKerell lab website into your working directory, then run:

```bash
python cgenff_charmm2gmx.py LIG ligand_fix.mol2 ligand.str charmm36-feb2021.ff
```

> **Note:** Legacy `cgenff_charmm2gmx.py` requires Python 2 and `networkx==1.1` (or use `cgenff_charmm2gmx_py3_nx2.py` with Python 3 and `networkx==2.3` in an Anaconda environment).

Convert the generated ligand PDB to `.gro`:

```bash
gmx_mpi editconf -f unk_ini.pdb -o unk.gro
```

---

## 3. Prepare the Receptor / Surface System & Randomly Insert Ligands

Example customized for a crystal/cellulose layer using GROMACS 2020.4:

```bash
# 1. Generate topology and position restraints
gmx pdb2gmx -f crystal.pdb -o processed.gro -missing -i posre.itp
gmx_mpi genrestr -f processed.gro -o crystal.itp
```

Add the custom restraint block to `topol.top`:

```text
; Include Position restraint file
#ifdef POSRES_CRYSTAL
#include "crystal.itp"
#endif
```

Define the box, solvate, add ions, and randomly insert 20 ligand copies by replacing solvent (`SOL`):

```bash
gmx_mpi editconf -f processed.gro -o newbox.gro -c -d 1.0 -bt cubic
gmx_mpi solvate -cp newbox.gro -cs spc216.gro -o solv.gro -p topol.top
gmx_mpi grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr
gmx_mpi genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral

# Insert 20 copies of unk.gro replacing SOL (writes out.gro)
gmx_mpi insert-molecules -f solv_ions.gro -ci unk.gro -replace -nmol 20
```

---

## 4. Update `topol.top` and `em.mdp`

Include the ligand `.prm` right after the force field and `.itp` before `[ system ]`:

```text
; Include forcefield parameters
#include "./charmm36-feb2021.ff/forcefield.itp"

; Include ligand parameters
#include "unk.prm"

...

; Include Position restraint file
#ifdef POSRES
#include "posre.itp"
#endif

; Include ligand topology
#include "unk.itp"

[ molecules ]
; Compound        #mols
Other_chain_X       1
SOL             43379
NA                 76
UNK                20
```

> **Tip (Atom count mismatch):** Because `insert-molecules -replace` removes water molecules, `grompp` may report a mismatch between `out.gro` and `topol.top` (e.g., `138973 - 138535 = 438` atoms). Divide the difference by `3` (for 3-point water) and subtract that number from the `SOL` molecule count in `topol.top`.

In `em.mdp`, enable crystal restraints if desired:
```text
define = -DPOSRES_CRYSTAL
```

---

## 5. Minimization, Indexing, Equilibration & Production

```bash
# Energy minimization
gmx_mpi grompp -f em.mdp -c out.gro -r out.gro -p topol.top -o em.tpr -maxwarn -1
# Optional interactive node:
# interactive -A snic2020-1-40 -t 1:00:00 --reservation=devel -N 2
mpprun gmx_mpi mdrun -v -deffnm em

# Create heavy-atom ligand index and combined system index
gmx_mpi make_ndx -f unk.gro -o index_unk.ndx
# > 0 & ! a H*
# > q

gmx_mpi make_ndx -f em.gro -o index.ndx
# > 2 | 11
# > q

# Equilibration
gmx_mpi grompp -f step4.1_equilibration.mdp -o equil.tpr -c em.gro -r out.gro -p topol.top -n index.ndx -maxwarn -1
gmx_mpi mdrun -v -deffnm equil

# Production MD
gmx_mpi grompp -f step5_production.mdp -o md.tpr -c equil.gro -p topol.top -n index.ndx -maxwarn -1
gmx_mpi mdrun -deffnm md
```

---

## 6. Extending the Simulation

```bash
gmx_mpi convert-tpr -s md_0_1.tpr -extend 100000 -o next.tpr
gmx_mpi mdrun -s next.tpr -deffnm md_0_1 -cpi md_0_1_prev.cpt
```
