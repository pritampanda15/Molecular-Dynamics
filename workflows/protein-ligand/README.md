# Protein–Ligand Complex Workflows

Step-by-step GROMACS protocols for protein–ligand complexes across different force fields and setup patterns.

## Guides

| Guide | Force Field / Ligand Tool | Best For |
| :--- | :--- | :--- |
| [`gromos_protein_ligand_guide.md`](gromos_protein_ligand_guide.md) | GROMOS96 + ATB / PRODRG | Single docked ligand bound to a protein (includes SLURM templates & RMSD post-processing) |
| [`charmm_tetralith_guide.md`](charmm_tetralith_guide.md) | CHARMM36 + CGenFF | Single protein–ligand complex using `cgenff_charmm2gmx_py3_nx2.py` on HPC clusters (Tetralith/SNIC) |
| [`charmm_random_ligand_insertion.md`](charmm_random_ligand_insertion.md) | CHARMM36 + CGenFF | Randomly inserting multiple copies of a ligand into a solvated box/crystal (`gmx insert-molecules`) |

## Related Resources

- Binding free energy calculations: [`../../analysis/mmpbsa-gbsa/`](../../analysis/mmpbsa-gbsa/)
- Reference Word/PDF protocols: [`../../docs/`](../../docs/)
