# Principal Component Analysis (PCA), Free Energy Landscape (FEL) & Entropy

Scripts, slides, and GROMACS command reference for essential dynamics (PCA), conformational entropy estimation, and 2D Gibbs Free Energy Landscape (FEL) plotting.

## Contents

- [`run_pca_fel_windows.sh`](run_pca_fel_windows.sh) — Automated script that splits a trajectory into fixed time windows (default: 10 ns windows across 0–100 ns) and runs `gmx covar` → `gmx anaeig` → `gmx sham` → `gmx xpm2ps` → `convert` (EPS to PDF).
- [`PCA.pptx`](PCA.pptx) — Presentation slides explaining PCA and FEL workflow.

---

## 1. Automated Windowed PCA + FEL Script

Run from an empty output subdirectory (expects `../md_0_100_fit.xtc`, `../md_0_100.tpr`, and `../index.ndx` by default):

```bash
chmod +x run_pca_fel_windows.sh
./run_pca_fel_windows.sh
```

Override defaults with environment variables:

```bash
TRAJ=../md_fit.xtc TPR=../md.tpr INDEX=../index.ndx GROUP=4 STEP=20 TOTAL_NS=100 ./run_pca_fel_windows.sh
```

---

## 2. Standard PCA & Quasi-Harmonic Entropy Commands

Reference tutorial: [Strodel Group GROMACS Analysis Tutorial](http://www.strodel.info/index_files/lecture/html/analysis-9.html)

```bash
# 1. Compute covariance matrix, eigenvalues, and eigenvectors (choose e.g. 4 = Backbone twice)
printf "4\n4\n" | gmx covar -f md_protein.xtc -s md_protein.tpr

# 2. Extract extreme conformations along PC1 and PC2 for visualization
gmx_mpi anaeig -v eigenvec.trr -f md.xtc -eig eigenval.xvg -s md.tpr -first 1 -last 1 -nframes 100 -extr ev1.pdb
gmx_mpi anaeig -v eigenvec.trr -f md.xtc -eig eigenval.xvg -s md.tpr -first 2 -last 2 -nframes 100 -extr ev2.pdb

# 3. Estimate quasi-harmonic conformational entropy
gmx_mpi anaeig -v eigenvec.trr -f md_0_1_center.xtc -eig eigenval.xvg -s md_0_1.tpr \
    -first 1 -last 1 -nframes 100 -extr ev1.pdb -n index.ndx -entropy
```

---

## 3. PCA on CHARMM-GUI Trajectories

```bash
# Remove PBC and strip water molecules
gmx_mpi trjconv -s md.tpr -f md.xtc -o md_100_noPBC.xtc -pbc mol -ur compact
gmx_mpi trjconv -s md.tpr -f md_100_noPBC.xtc -o md_01_noWAT.xtc -n index.ndx

# Run covariance analysis against step1_pdbreader.pdb
gmx_mpi covar -s step1_pdbreader.pdb -f md_01_noWAT.xtc

# Filtered trajectory, extreme structures, and 1D/2D/3D projections
gmx_mpi anaeig -s step1_pdbreader.pdb -f md_01_noWAT.xtc -filt filter1.pdb -first 1 -last 1 -skip 100
gmx_mpi anaeig -s step1_pdbreader.pdb -f md_01_noWAT.xtc -extr extreme1.pdb -first 1 -last 1 -nframes 30
gmx_mpi anaeig -s step1_pdbreader.pdb -f md_01_noWAT.xtc -proj -first 1 -last 1
gmx_mpi anaeig -s step1_pdbreader.pdb -f md_01_noWAT.xtc -2d -first 1 -last 2
gmx_mpi anaeig -s step1_pdbreader.pdb -f md_01_noWAT.xtc -3d -first 1 -last 3
```
