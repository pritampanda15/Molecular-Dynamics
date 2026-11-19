# GROMACS Post-Processing & Trajectory Cheat Sheet

Common commands for cleaning periodic boundary conditions (PBC), centering trajectories, computing RMSD, extracting PDB snapshots, restarting/extending runs, and managing batch HPC jobs.

> For an automated script that processes multiple simulation subdirectories at once, use [`../../hpc/batch_postprocess.sh`](../../hpc/batch_postprocess.sh).

---

## 1. Remove PBC & Center Trajectory

```bash
# Center on Protein (1), keep molecules whole, compact periodic box, output System (0)
gmx_mpi trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_center.xtc -center -pbc mol -ur compact

# Remove PBC jumps without compacting
gmx_mpi trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_noPBC.xtc -pbc mol -center

# Fit trajectory to remove overall rotation and translation
gmx_mpi trjconv -s md_0_1.tpr -f md_0_1_center.xtc -o md_0_1_fit.xtc -fit rot+trans
```

---

## 2. RMSD Analysis

```bash
# Backbone/protein RMSD vs. production start or minimized reference
gmx_mpi rms -s md_0_1.tpr -f md_0_1_noPBC.xtc -o rmsd.xvg -tu ns
gmx_mpi rms -s md_0_1.tpr -f md_0_1_center.xtc -o rmsd.xvg -tu ns
gmx_mpi rms -s em.tpr -f md_0_1_center.xtc -n index.ndx -tu ns -o rmsd_protein.xvg

# Ligand (UNL) RMSD using custom index groups
gmx_mpi make_ndx -f em.gro -n index.ndx
gmx_mpi rms -s em.tpr -f md_0_1_center.xtc -n index.ndx -tu ns -o rmsd_unl.xvg
```

---

## 3. Extracting Snapshots

```bash
# Extract first frame (t = 0 ns)
gmx_mpi trjconv -s md_0_1.tpr -f md_0_1_noPBC.xtc -o start.pdb -dump 0

# Extract separated PDB frames every 1000 frames
gmx_mpi trjconv -f md_0_1_noPBC.xtc -o _pro.pdb -s md_0_1.tpr -n index.ndx -sep -center -skip 1000

# Extract Protein (group 1) snapshots every 10 frames into a dedicated folder
mkdir -p snap && cd snap
gmx trjconv -s ../md.tpr -f ../md.trr -o Pro_.pdb -sep -skip 10 -n ../index.ndx
# Choose group 1 (Protein)
```

---

## 4. Restarting & Extending Simulations

```bash
# Restart an interrupted run from checkpoint
gmx_mpi mdrun -s md_0_1.tpr -cpi md_0_1.cpt -deffnm md_0_1 -append

# Extend an existing simulation by 100 ns (100000 ps)
gmx_mpi convert-tpr -s md_0_1.tpr -extend 100000 -o next.tpr
gmx_mpi mdrun -s next.tpr -deffnm md_0_1 -cpi md_0_1.cpt -append
```

---

## 5. Multi-Folder Bash & SLURM Helpers

```bash
# Copy a script to every immediate subdirectory
for dir in */; do cp runextend.sh "$dir"; done

# Copy a folder recursively into every immediate subdirectory
for dir in */; do cp -rf /path/to/folder "$dir"; done

# Submit run.sh inside every immediate subdirectory
for d in */; do (cd "$d" && sbatch run.sh); done

# Track or cancel SLURM jobs
squeue -u "$USER"
scontrol show job <JOB_ID>
scancel <JOB_ID>
```
