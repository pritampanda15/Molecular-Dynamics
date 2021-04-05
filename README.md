# Molecular-Dynamics
Self explained tutorial for molecular dynamics simulation using gromacs

This is a self explained tutorial for usage of gromacs v.5.0 above referred from http://www.mdtutorials.com/gmx/.

Remember 500000 steps = 1 ns
        5000000 steps = 10 ns
       50000000 steps = 100 ns
      250000000 steps = 250 ns
      500000000 steps = 1 microsecond

Lipid coordinates can be downloaded from https://people.ucalgary.ca/~tieleman/download.html

Nanotube generator:http://turin.nss.udel.edu/research/tubegenonline.html

Ligand topology generator:http://www.swissparam.ch/ http://davapc1.bioch.dundee.ac.uk/cgi-bin/prodrg

Here is a simple tutorial for topology file generation:
https://nptel.ac.in/courses/104101002/downloads/lecture-notes/module4/chapter35.pdf

Best tutorial to perform MD using gromacs:
http://www.jyhuang.idv.tw/JYH_MDSimulation.html

Note: For extending simulations:
gmx_convert-tpr -s md_0_1.tpr -extend 100000 -o next.tpr
gmx_mpi mdrun -s next.tpr -deffnm md_0_1 -cpi md_0_1_prev.cpt



