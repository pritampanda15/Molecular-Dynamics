# Trajectory Post-Processing & Analysis

Scripts, input templates, and command guides for analyzing GROMACS MD trajectories.

| Topic | Directory | Key Files |
| :--- | :--- | :--- |
| **Post-Processing & Trajectory Utilities** | [`post-processing/`](post-processing/) | [`README.md`](post-processing/README.md) (PBC removal, centering, RMSD, snapshots, extending/restarting runs, batch shell helpers) |
| **PCA, Free Energy Landscape (FEL) & Entropy** | [`pca-fel-entropy/`](pca-fel-entropy/) | [`run_pca_fel_windows.sh`](pca-fel-entropy/run_pca_fel_windows.sh), [`README.md`](pca-fel-entropy/README.md), [`PCA.pptx`](pca-fel-entropy/PCA.pptx) |
| **MM-PBSA / MM-GBSA Binding Free Energy** | [`mmpbsa-gbsa/`](mmpbsa-gbsa/) | [`mmpbsa.in`](mmpbsa-gbsa/mmpbsa.in), [`env.yml`](mmpbsa-gbsa/env.yml), [`README.md`](mmpbsa-gbsa/README.md), [`example-results/`](mmpbsa-gbsa/example-results/) |

For running post-processing across many simulation directories at once, see [`../hpc/batch_postprocess.sh`](../hpc/batch_postprocess.sh).
