#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH  -N 4
#SBATCH -c 4
#SBATCH --account=snic2020-1-40
export OMP_NUM_THREADS=4
#SBATCH -J amyloid
#SBATCH --exclusive
#SBATCH --ntasks-per-node=32
#gmx_mpi convert-tpr -s md_0_1.tpr -extend 100000 -o next.tpr
module load GROMACS/2019.6-nsc1-gcc-7.3.0-bare
echo -e "1\n1" | gmx_mpi pdb2gmx -f *.pdb -o peptide.gro
gmx_mpi editconf -f peptide.gro -o pep_box.gro -c -d 1.0 -bt cubic
gmx_mpi solvate -cp pep_box.gro -cs spc216.gro -o solv.gro -p topol.top
echo -e "13\n1" | gmx_mpi grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr -maxwarn -1
gmx_mpi grompp -f minim.mdp -c solv.gro -p topol.top -o em.tpr -maxwarn -1

mpprun --pass="--map-by
ppr:$((16/OMP_NUM_THREADS)):socket:PE=${OMP_NUM_THREADS}" \
	gmx_mpi mdrun -v -deffnm em
	gmx_mpi grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr -maxwarn -1
mpprun --pass="--map-by
ppr:$((16/OMP_NUM_THREADS)):socket:PE=${OMP_NUM_THREADS}" \
	gmx_mpi mdrun -deffnm nvt
	gmx_mpi grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr -maxwarn -1
mpprun --pass="--map-by
ppr:$((16/OMP_NUM_THREADS)):socket:PE=${OMP_NUM_THREADS}" \
	gmx_mpi mdrun -deffnm npt
	gmx_mpi grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr -maxwarn -1
mpprun --pass="--map-by
ppr:$((16/OMP_NUM_THREADS)):socket:PE=${OMP_NUM_THREADS}" \
	gmx_mpi mdrun -deffnm md_0_1
gmx_mpi trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_center.xtc -center -pbc mol -ur compact
