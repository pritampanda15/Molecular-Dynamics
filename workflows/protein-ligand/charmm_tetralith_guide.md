# Protein–Ligand Complex MD Guide (CHARMM36 / CGenFF on Tetralith HPC)

Quick-reference workflow for setting up a protein–ligand complex with the **CHARMM36** force field and **CGenFF** on the Tetralith (SNIC/NAISS) HPC cluster.

---

## 1. Parameterize the Ligand with CGenFF

1. Extract the ligand from the docked/complex PDB:
   ```bash
   grep LIG tranexamixtyr.pdb > LIG.pdb
   ```
2. Open `LIG.pdb` in **Avogadro**, add hydrogens if needed, and export as SYBYL `.mol2` (`LIG.mol2`).
3. Sort bond order with `sort_mol2_bonds.pl` (here named `sort.pl`):
   ```bash
   perl sort.pl LIG.mol2 LIG_fix.mol2
   ```
4. Upload `LIG_fix.mol2` to the [CGenFF server](https://cgenff.umaryland.edu/) and download `lig.str`.
5. Convert CHARMM topology to GROMACS format using `cgenff_charmm2gmx_py3_nx2.py` (Python 3 + NetworkX 2.x):
   ```bash
   module load Python/3.7.0-anaconda-5.3.0-extras-nsc1
   source activate my_pymatgen
   python cgenff_charmm2gmx_py3_nx2.py LIG LIG_fix.mol2 lig.str charmm36-feb2021.ff/
   ```

---

## 2. Build the Complex, Box, Solvent, and Ions

```bash
module load GROMACS/2019.6-nsc1-gcc-7.3.0-bare

# Process protein structure (select CHARMM36 force field)
gmx_mpi pdb2gmx -f cleanactive.pdb -o protein_processed.gro -ignh

# Convert ligand PDB to GRO
gmx_mpi editconf -f lig_ini.pdb -o lig.gro

# Manually merge protein_processed.gro + lig.gro -> complex.gro
# and update atom count & topol.top (#include "lig.prm" and #include "lig.itp")

# Define cubic box, solvate, and neutralize with Na+/Cl-
gmx_mpi editconf -f complex.gro -o newbox.gro -bt cubic -d 1.0
gmx_mpi solvate -cp newbox.gro -cs spc216.gro -p topol.top -o solv.gro
gmx_mpi grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr
gmx_mpi genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral
```

---

## 3. Energy Minimization

```bash
gmx_mpi grompp -f em.mdp -c solv_ions.gro -p topol.top -o em.tpr
sbatch runem.sh
```

---

## 4. Ligand Restraints, Index Groups & Equilibration

```bash
# Heavy-atom position restraints for the ligand
gmx_mpi make_ndx -f lig.gro -o index_lig.ndx
gmx_mpi genrestr -f lig.gro -n index_lig.ndx -o posre_lig.itp -fc 1000 1000 1000

# Create merged Protein_LIG index group
gmx_mpi make_ndx -f em.gro -o index.ndx

# Prepare NVT and submit NVT/NPT/Production run script
gmx_mpi grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -n index.ndx -o nvt.tpr
sbatch run.sh
```
