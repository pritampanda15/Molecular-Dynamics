# Lipid Bilayer & Plasma Membrane Simulation

Ready-to-run CHARMM-GUI input files and scripts for an **asymmetric mammalian plasma membrane (PMm)** in GROMACS, plus a legacy InflateGRO guide for membrane-protein insertion.

## Contents

- [`run_lipid_bilayer_slurm.sh`](run_lipid_bilayer_slurm.sh) — SLURM script running minimization (`step6.0`), 6-stage equilibration (`step6.1`–`step6.6`), and production MD (`step7_production`).
- [`inflategro_membrane_protein.md`](inflategro_membrane_protein.md) — Step-by-step protocol for embedding a protein into a pre-equilibrated bilayer with `inflategro.pl`.
- **CHARMM-GUI Input Bundle** (keep together when running `grompp`):
  - Coordinates & structure: `step5_input.gro`, `step5_input.pdb`, `step5_input.psf`
  - Topology & force field: `topol.top`, `toppar/`
  - Index & MDP files: `index.ndx`, `step6.0_minimization.mdp` through `step6.6_equilibration.mdp`, `step7_production.mdp`
- **Reference Figures**:
  - [`images/Composition.png`](images/Composition.png)
  - [`images/Chemical_formulae.png`](images/Chemical_formulae.png)

## Plasma Membrane System Composition

- **Box size:** ~75.26 × 75.26 × 122.17 Å³
- **Temperature:** 310.15 K
- **Solvent & Ions:** TIP3P water + Na⁺ (SOD) + Cl⁻ (CLA) (exact counts in `topol.top`)

| Lipid | Head / Tail | Outer Leaflet | Inner Leaflet | Charge (e) |
| :--- | :--- | :---: | :---: | :---: |
| POPC | PC(16:0/18:1(9Z)) | 16 | 7 | 0 |
| PLPC | PC(16:0/18:2(9Z,12Z)) | 22 | 11 | 0 |
| PAPE | PE(16:0/20:4(5Z,8Z,11Z,14Z)) | 3 | 12 | 0 |
| POPE | PE(16:0/18:1(9Z)) | 3 | 14 | 0 |
| POPI | PI(16:0/18:1(9Z)) | 0 | 5 | -1 |
| PAPS | PS(16:0/20:4(5Z,8Z,11Z,14Z)) | 0 | 11 | -1 |
| POPA | PA(16:0/18:1(9Z)) | 0 | 1 | -1 |
| SSM | SM(d18:1/18:0) | 11 | 5 | 0 |
| NSM | SM(d18:1/24:1) | 11 | 5 | 0 |
| CMH (GLPA) | GlcCer(d18:1/16:0) | 4 | 0 | -1 |
| CHL1 | Cholesterol | 37 | 29 | 0 |
| **Total** | | **107** | **100** | |

## Quick Start

From inside `workflows/lipid-bilayer/`, customize the `#SBATCH` account/module headers in `run_lipid_bilayer_slurm.sh` and submit:

```bash
cd workflows/lipid-bilayer
sbatch run_lipid_bilayer_slurm.sh
```

To run locally without SLURM, replace `mpprun ... gmx_mpi` with `gmx` and run the commands sequentially.
