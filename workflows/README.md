# Simulation Workflows

End-to-end molecular dynamics setup guides, input bundles, and run scripts organized by system type.

| System Type | Directory | Force Field / Engine | Key Files |
| :--- | :--- | :--- | :--- |
| **Protein in Water** | [`protein-only/`](protein-only/) | OPLS-AA / GROMACS | [`run_protein_md.sh`](protein-only/run_protein_md.sh) |
| **Protein–Ligand Complex** | [`protein-ligand/`](protein-ligand/) | GROMOS96 (ATB/PRODRG) & CHARMM36 (CGenFF) / GROMACS | [`gromos_protein_ligand_guide.md`](protein-ligand/gromos_protein_ligand_guide.md), [`charmm_tetralith_guide.md`](protein-ligand/charmm_tetralith_guide.md), [`charmm_random_ligand_insertion.md`](protein-ligand/charmm_random_ligand_insertion.md) |
| **Lipid Bilayer / Membrane** | [`lipid-bilayer/`](lipid-bilayer/) | CHARMM36 (CHARMM-GUI) & InflateGRO / GROMACS | [`run_lipid_bilayer_slurm.sh`](lipid-bilayer/run_lipid_bilayer_slurm.sh), [`inflategro_membrane_protein.md`](lipid-bilayer/inflategro_membrane_protein.md), full CHARMM-GUI inputs |
| **Nanomaterials & 2D Layers** | [`nanomaterials/`](nanomaterials/) | CHARMM36 / GROMACS & ASE / LAMMPS | [`charmm_nanomaterials_guide.md`](nanomaterials/charmm_nanomaterials_guide.md), [`build_fluid_on_layer.py`](nanomaterials/build_fluid_on_layer.py), [`build_fluid_on_layer.ipynb`](nanomaterials/build_fluid_on_layer.ipynb) |

See also:
- [`../hpc/`](../hpc/) for reusable SLURM job scripts and batch post-processing.
- [`../analysis/`](../analysis/) for trajectory post-processing, PCA/FEL, entropy, and MM-PBSA/GBSA binding free energy.
