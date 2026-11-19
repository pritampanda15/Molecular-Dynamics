# Nanomaterials + Ligands MD Guide (CHARMM-GUI / CGenFF + GROMACS)

Step-by-step instructions for combining a **CHARMM-GUI Nanomaterial Modeler** system (`step3_input.pdb`) with small-molecule ligands parameterized via **CHARMM-GUI Ligand Reader** or **CGenFF**.

---

## 1. Prepare Ligand and Nanomaterial Coordinates

1. Obtain the CHARMM potential for your ligand using **CGenFF** (see [Random Ligand Insertion Guide](../protein-ligand/charmm_random_ligand_insertion.md)).
2. Convert both ligand and nanomaterial PDB files to `.gro`:
   ```bash
   gmx_mpi editconf -f unk_ini.pdb -o unk.gro
   gmx_mpi editconf -f step3_input.pdb -o step3_input.gro
   ```
3. Randomly insert 20 ligand molecules by replacing solvent (`SOLV`):
   ```bash
   gmx_mpi insert-molecules -f step3_input.gro -ci unk.gro -replace -nmol 20 -n index.ndx
   # Choose SOLV when prompted (creates out.gro)
   ```

---

## 2. Update `topol.top`

### Option A: Ligand parameterized with CHARMM-GUI
1. Upload your bond-sorted `.mol2` file (fixed with `sort_mol2_bonds.pl`) to CHARMM-GUI.
2. Open the generated `charmm36.itp` and **delete** the duplicate `[ defaults ]` section:
   ```text
   [ defaults ]
   ; nbfunc  comb-rule  gen-pairs  fudgeLJ  fudgeQQ
   1         2          yes        1.0      1.0
   ```
3. Place `#include "toppar/charmm36.itp"` directly after `forcefield.itp` in `topol.top`:
   ```text
   ; Include forcefield parameters
   #include "toppar/forcefield.itp"
   #include "toppar/charmm36.itp"
   #include "toppar/NMA.itp"
   #include "toppar/POT.itp"
   #include "toppar/CLA.itp"
   #include "toppar/TIP3.itp"
   #include "toppar/unk.itp"
   ```

### Option B: Ligand parameterized with CGenFF
If CHARMM-GUI cannot process your ligand, use CGenFF and structure `topol.top` as:

```text
; Include forcefield parameters
#include "charmm36-feb2021.ff/forcefield.itp"
#include "toppar/forcefield.itp"
#include "toppar/unk.prm"
#include "toppar/NMA.itp"
#include "toppar/POT.itp"
#include "toppar/CLA.itp"
#include "toppar/TIP3.itp"
#include "toppar/unk.itp"
```

### Adjust Water Molecule Count
After replacing solvent with ligands, compute `(topology_atoms - coordinate_atoms) / 3` and subtract that integer from the `TIP3` count under `[ molecules ]` in `topol.top`.

---

## 3. Minimization, Equilibration, and Production MD

```bash
# Energy minimization
gmx_mpi grompp -f step4.0_minimization.mdp -o min.tpr -c out.gro -r out.gro -p topol.top -n index.ndx -maxwarn -1
# Optional interactive allocation on SNIC/Tetralith:
# interactive -A snic2020-1-40 -t 1:00:00 --reservation=devel -N 2
mpprun gmx_mpi mdrun -v -deffnm min

# Equilibration
# Note: If grompp reports invalid atom numbers in index.ndx, inspect the total atom
# count in min.gro and remove out-of-range atom indices from index.ndx.
gmx_mpi grompp -f step4.1_equilibration.mdp -o equil.tpr -c min.gro -r out.gro -p topol.top -n index.ndx -maxwarn -1
mpprun gmx_mpi mdrun -deffnm equil

# Production MD
gmx_mpi grompp -f step5_production.mdp -o md.tpr -c equil.gro -p topol.top -n index.ndx -maxwarn -1
gmx_mpi mdrun -deffnm md
```

---

## 4. Post-Processing & Radial Distribution Function (RDF)

```bash
# Center trajectory on group 1 and output group 0 (System)
printf "1\n0\n" | gmx_mpi trjconv -s md.tpr -f md.xtc -o md_0_1_center.xtc -center -pbc mol -ur compact

# Generate custom index groups and compute RDF
gmx_mpi make_ndx -f md.tpr -o ind.ndx
gmx_mpi rdf -f md_0_1_center.xtc -o rdf.xvg -n ind.ndx
```
