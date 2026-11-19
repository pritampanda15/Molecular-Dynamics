# Nanomaterials & 2D Layer Simulations

Guides and structure-building scripts for nanomaterials simulations in **GROMACS** and **LAMMPS**.

## Contents

| File | Engine / Language | Purpose |
| :--- | :--- | :--- |
| [`charmm_nanomaterials_guide.md`](charmm_nanomaterials_guide.md) | GROMACS (CHARMM36 / CGenFF) | Combining CHARMM-GUI nanomaterial inputs (`step3_input.pdb`) with small-molecule ligands, running EM/EQ/MD, and computing RDF |
| [`build_fluid_on_layer.py`](build_fluid_on_layer.py) | Python (`ase`, `numpy`, `matplotlib`) → LAMMPS | Builds a 2D substrate (GaN, AlN, or Si from `.xyz`) + graphene sheet + water/Na⁺/Cl⁻/OH⁻/H₃O⁺ fluid and writes `system.data` for LAMMPS |
| [`build_fluid_on_layer.ipynb`](build_fluid_on_layer.ipynb) | Jupyter / Google Colab | Interactive notebook version of `build_fluid_on_layer.py` |

## Running the LAMMPS System Builder Locally

```bash
pip install ase numpy matplotlib
python build_fluid_on_layer.py path/to/substrate.xyz
```

This generates `system.data` in the current working directory.
