
<p align="center">
  <img src="/MMPBSA.png" title="hover text">
</p>

YouTube Link: <br>

## Command to perform analysis
```
gmx_MMPBSA -O -i mmpbsa.in -cs md_0_100.tpr -ct md_0_100_fit.xtc -ci index.ndx -cg 1 13 -cp topol.top -o FINAL_RESULTS_MMPBSA.dat -eo FINAL_RESULTS_MMPBSA.csv
```
## Analyze the results
```
gmx_MMPBSA_ana -f _GMXMMPBSA_info
```

## Install the tool
### env.yml
```
name:
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.9
  - ambertools<=23.3
  - mpi4py<=3.1.5
  - gromacs<=2023.4
  - git
  - pip
  - pip: 
    - pyqt5<=6.6.1
    - gmx-mmpbsa
    - pandas==1.2.2
    - seaborn<0.12
    - scipy>=1.6.1
    - matplotlib==3.5.2
    - tqdm
    
```

### Install

```
conda env create -n gmxMMPBSA --file env.yml
```



