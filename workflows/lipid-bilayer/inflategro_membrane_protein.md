# Membrane-Protein Insertion Guide (InflateGRO / Legacy GROMACS)

Step-by-step protocol for embedding a protein into a pre-equilibrated lipid bilayer (e.g., DOPS from [Tieleman's Lipid Coordinates](https://people.ucalgary.ca/~tieleman/download.html)) using **InflateGRO** (`inflategro.pl`).

> **Version Note:** The commands below use legacy GROMACS 4.x double-precision binary names (`editconf_d`, `genbox_d`, `grompp_d`, `mdrun_d`, etc.). On GROMACS 5.x/20xx, replace them with `gmx editconf`, `gmx solvate`, `gmx grompp`, `gmx mdrun`, etc.

---

## 1. Prepare and Orient the Lipid Bilayer

Download lipid coordinates (e.g., `dops.gro`) from https://people.ucalgary.ca/~tieleman/download.html:

```bash
editconf_d -f dops.gro -o dops_rotate.gro -rotate 180 0 0
editconf_d -f dops_rotate.gro -o dops_Zaxis.gro -c -box 6.17600 6.17600 6.66080
```

Before solvating, copy `vdwradii.dat` into your working directory and increase the carbon van der Waals radius to `0.375` nm to prevent water from entering the hydrophobic bilayer core:

```bash
genbox_d -cp dops_Zaxis.gro -cs -o dopsZ-axis.gro -box 6.17600 6.17600 16.66080
```

---

## 2. Process the Protein and Make Lipids Whole

```bash
# Process oriented protein (select NH2 and COOH termini if prompted)
pdb2gmx_d -f Orient.pdb -o PFA_processed.gro -ignh -water spc
```

1. Add `dops.itp` to the topology file (`topol_dops.top`).
2. Update the `SOL` count (`SOL - 128`) and add `DOPS` at the bottom of `[ molecules ]`.
3. Run `grompp` and remove periodicity jumps from the lipid bilayer:

```bash
grompp_d -f minim.mdp -c dopsZ-axis.gro -p topol_dops.top -o em.tpr -maxwarn 3
trjconv_d -s em.tpr -f dopsZ-axis.gro -o dops128_whole.gro -pbc mol -ur compact
# Select group 2 (or DOPS/System as appropriate)
```

Note the box dimensions at the end of the whole bilayer file (e.g., `9.86750 9.86750 17.17090`).

---

## 3. Embed Protein Using InflateGRO

```bash
# Step I: Place protein in a matching box
editconf_d -f PFA_processed.gro -o PFA_newbox.gro -c -box 12.35200 12.35200 18.66080

# Step II: Generate strong position restraints for the protein (choose group 4 = Backbone)
genrestr_d -f PFA_newbox.gro -o strong_posre.itp -fc 100000 100000 100000

# Step III: Concatenate protein and bilayer coordinates (update atom count & box vector)
cat PFA_newbox.gro dops128_whole.gro > system.gro
```

Add strong position restraints to `topol.top`:

```text
; Strong position restraints for InflateGRO
#ifdef STRONG_POSRES
#include "strong_posre.itp"
#endif
```

Inflate the lipid bilayer around the protein:

```bash
# Step IV: Inflate by factor 4 with 14 A cutoff around protein
perl inflategro.pl system.gro 4 DOPS 14 system_inflated.gro 5 area.dat
```

Inspect `system_inflated.gro` in **VMD**. If the protein orientation or Z-position looks off, adjust the box Z-dimension in Step I (e.g., `12.66080`) and repeat Steps I–IV.

Update the number of remaining `DOPS` molecules in `topol.top`, add `define = -DSTRONG_POSRES` to `minim.mdp`, minimize, and run iterative shrinking:

```bash
grompp_d -f minim.mdp -c system_inflated.gro -p topol.top -o minim.tpr
dplace -c 0-29 mdrun_d -v -s minim.tpr -c pro_minim.gro -nt 30 &

# Run iterative InflateGRO shrinking script until target area per lipid is reached
sh ./script.sh
```

---

## 4. Solvate, Neutralize, Equilibrate, and Run Production MD

Copy `vdwradii.dat` back (with `0.375` nm carbon radius) during solvation, then remove `vdwradii.dat` afterward:

```bash
genbox_d -cp pro_minim25.gro -cs -o b4ion.gro -p topol.top
rm -f vdwradii.dat

# Add neutralizing counter-ions and 0.15 M NaCl
grompp_d -f ions.mdp -c b4ion.gro -p topol.top -o ions.tpr
genion_d -s ions.tpr -o b4em.gro -p topol.top -pname NA -nname CL -np 9
# Or neutralize with physiological salt concentration:
genion_d -s ions.tpr -o b4em.gro -p topol.top -neutral -conc 0.15 -g ion.log

# Energy minimization
grompp_d -f minim.mdp -c b4em.gro -p topol.top -o em.tpr
dplace -c 0-49 mdrun_d -v -s em.tpr -o em.trr -c em.gro -e em.edr -g em.log -nt 50

# Create coupling index groups (e.g., merge solvent+ions and protein+lipid: 16 | 14 and 1 | 13)
make_ndx_d -f em.gro -o index.ndx

# NVT equilibration
grompp_d -f nvt.mdp -c em.gro -p topol.top -n index.ndx -o nvt.tpr
dplace -c 0-99 mdrun_d -v -s nvt.tpr -o nvt.trr -e nvt.edr -c nvt.gro -cpo nvt.cpt -g nvt.log -nt 100 &

# NPT equilibration
grompp_d -f npt.mdp -c nvt.gro -t nvt.cpt -p topol.top -n index.ndx -o npt.tpr
dplace -c 100-195 mdrun_d -v -s npt.tpr -o npt.trr -e npt.edr -c npt.gro -cpo npt.cpt -g npt.log -nt 96 &

# Production MD
grompp_d -f md.mdp -c npt.gro -t npt.cpt -p topol.top -n index.ndx -o md.tpr
dplace -c 0-119 mdrun_d -v -s md.tpr -o md.trr -e md.edr -c md.gro -cpo md.cpt -g md.log -nt 120 &
```
