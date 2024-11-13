# Molecular Dynamics with GROMACS

This repository provides scripts and instructions for performing Molecular Dynamics (MD) simulations using **GROMACS**, a widely used software package for simulating atomic and molecular behavior. MD simulations allow for detailed exploration of biological molecules, materials, and chemical systems at the atomic level.

![GROMACS](https://github.com/pritampanda15/Molecular-Dynamics/blob/master/Youtube.png)

## YouTube Tutorial Playlist

For a comprehensive guide, please refer to my [YouTube playlist on Molecular Dynamics with GROMACS](https://www.youtube.com/playlist?list=PLS3KFDv2o0CQIvkKuL7kU2rfowWIfHFFN).

---

## Table of Contents

- [Introduction](#introduction)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Preparing Input Files](#preparing-input-files)
  - [Running Simulations](#running-simulations)
  - [Analyzing Results](#analyzing-results)
- [Customization](#customization)
- [Links](#links)
- [Contributing](#contributing)
- [License](#license)

---

## Introduction

Molecular Dynamics (MD) with GROMACS enables you to model atomic interactions in different environments, such as solvated biomolecules or solid-state materials. This README provides step-by-step instructions for setting up and running MD simulations using GROMACS.

## Getting Started

### Prerequisites

- **GROMACS**: Install GROMACS following the [official instructions](http://www.gromacs.org/Downloads).
- **Input Files**: You’ll need coordinate files (PDB or GRO format), force field parameters, and a simulation topology file (`.top`).
- **Topology File**: Prepare a `.top` file specifying molecule types and interactions in your system.

### Installation

Clone this repository to get started:

```bash
git clone https://github.com/yourusername/molecular-dynamics-gromacs.git
cd molecular-dynamics-gromacs
```

Ensure that GROMACS is installed and accessible in your system's PATH.

---

## Usage

### Preparing Input Files

1. **Coordinate File**: Contains atom positions in PDB or GRO format.
2. **Topology File**: Describes molecules and force field parameters.
3. **Parameter Files**: Any additional `.itp` force field files for specific molecules.
4. **Simulation Parameters**: Set up the `.mdp` file with parameters like time step, temperature control, and simulation duration.

### Running Simulations

1. **Edit `.mdp` File**: Customize the `.mdp` file with your desired simulation parameters.
2. **Generate a TPR File**: Create a GROMACS binary run input file (TPR):

   ```bash
   gmx grompp -f simulation.mdp -c initial.gro -p system.top -o simulation.tpr
   ```

3. **Run Simulation**: Use `gmx mdrun` to start the simulation:

   ```bash
   gmx mdrun -v -deffnm simulation
   ```

4. **Monitor Progress**: Check the log files to track simulation progress and address any issues.

### Analyzing Results

Use GROMACS analysis tools to extract and visualize simulation data:

- **Trajectory Visualization**: Use `gmx trjconv` for trajectory file conversions.
- **Data Analysis**: Compute properties like temperature, pressure, and radial distribution functions (RDF).
- **Plotting**: Visualize simulation results with your preferred plotting tools.

---

## Simulation Parameters

Customize these key parameters in the `.mdp` file:

- **Temperature & Pressure Control**: Select an appropriate thermostat and barostat.
- **Time Step**: Use an integration time step suitable for your system’s dynamics.
- **Force Field**: Choose a force field that accurately describes your system’s interactions.
- **Boundary Conditions**: Define simulation cell boundaries (e.g., periodic boundary conditions).
- **Simulation Length**: Adjust simulation duration based on system needs.

> **Step Conversion**:
> - 1 ns = 500,000 steps
> - 10 ns = 5,000,000 steps
> - 100 ns = 50,000,000 steps

---

## Python Requirements

Make sure Python is installed with essential libraries for MD simulations:

```bash
pip install numpy scipy mdanalysis
```

Alternatively, use conda:

```bash
conda install numpy scipy mdanalysis
```

---

## Customization

To adjust simulation settings:

1. Modify the `.mdp` file for simulation-specific requirements.
2. Edit the topology file to add or remove molecular components.
3. Refer to [GROMACS documentation](http://www.gromacs.org/) for detailed customization options.

---

## Links

- [YouTube channel](https://youtu.be/hc8ZXbOMEfw)
- [Lipid Coordinates](https://people.ucalgary.ca/~tieleman/download.html)
- [Nanotube Generator](http://turin.nss.udel.edu/research/tubegenonline.html)
- [Ligand Topology Generator 1](http://www.swissparam.ch/)
- [CHARMM-GUI](https://www.charmm-gui.org/)
- [Topology File Generation](https://nptel.ac.in/courses/104101002/downloads/lecture-notes/module4/chapter35.pdf)
- [MD Tutorial with GROMACS](http://www.jyhuang.idv.tw/JYH_MDSimulation.html)

---

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository and create a new branch.
2. Make your modifications.
3. Submit a pull request with a description of your changes.

Refer to the contribution guidelines for detailed information.

---

## License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute this code for research and academic purposes.

---

Thank you for using this Molecular Dynamics with GROMACS repository! Feel free to reach out with questions or open an issue for any problems. **Happy Simulating!**
