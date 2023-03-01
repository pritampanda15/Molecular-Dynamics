#First get the coordinates of lipid from https://people.ucalgary.ca/~tieleman/download.html

editconf_d -f dops.gro -o dops_rotate.gro -rotate 180 0 0
editconf_d -f dops_rotate.gro -o dops_Zaxis.gro -c -box   6.17600   6.17600   6.66080

#First Copy the vwdradii.dat and change the 0.375 radii length     
genbox_d -cp dops_Zaxis.gro -cs -o dopsZ-axis.gro -box 6.17600 6.17600 16.66080   
#Now insert the protein properly in the lipid  
pdb2gmx_d -f Orient.pdb -o PFA_processed.gro -ignh -water spc (select NH2 and COOH)
#Edit the topology file and add dops.itp
#calculate the SOL in dopsZ-axis.gro and do SOL-128= number of SOL and edit the dops_topol.top at bottom add dops.itp in topology file                                    
grompp_d -f minim.mdp -c dopsZ-axis.gro -p topol_dops.top -o em.tpr -maxwarn 3     
trjconv_d -s em.tpr -f dopsZ-axis.gro -o dops128_whole.gro -pbc mol -ur compact     select 2
#Please mark the box dimensions. Copy them from the dppc128_whole.gro file 9.86750   9.86750  17.17090 
editconf_d -f PFA_processed.gro -o PFA_newbox.gro -c -box   12.35200  12.35200  18.66080 
genrestr_d -f PFA_newbox.gro -o strong_posre.itp -fc 100000 100000 100000   choose 4
cat PFA_newbox.gro dops128_whole.gro > system.gro
#Edit topol.top  ;Strong position restraints for InflateGRO  #ifdef STRONG_POSRES #include "strong_posre.itp" #endif
perl inflategro.pl system.gro 4 DOPS 14 system_inflated.gro 5 area.dat
#Now Check the system_inflated.gro in VMD
#If the protein is placed in a right way. Proceed. Else-. Change the dimension 
Step-I: editconf -f PFA_processed.gro -o PFA_newbox.gro -c -box   12.35200  12.35200  18.66080/12.66080
Step-II: genrestr -f PFA_newbox.gro -o strong_posre.itp -fc 100000 100000 100000   choose 4
Step –III: cat PFA_newbox.gro dops128_whole.gro > system.gro
Step_IV: perl inflategro.pl system.gro 4 DOPS 14 system_inflated.gro 5 area.dat
#Check the number of lipids removed and add the DOPS in the top.top file at liast line
#Before this step add    define          = -DSTRONG_POSRES    in  minim.mdp        
grompp_d -f minim.mdp -c system_inflated.gro -p topol.top -o minim.tpr 
dplace -c 0-29 mdrun_d -v -s minim.tpr -c pro_minim.gro -nt 30 &                        



sh ./script.sh 
#Again copy the vwdradii and change to 0.375

genbox_d -cp pro_minim25.gro -cs -o b4ion.gro -p topol.top
#Remove the vwdradii from the folder



grompp_d -f ions.mdp -c b4ion.gro -p topol.top -o ions.tpr
genion_d -s ions.tpr -o b4em.gro -p topol.top -pname NA -nname CL -np 9
genion_d -s ions.tpr -o b4em.gro -p topol.top -neutral -conc 0.15 -g ion.log
grompp_d -f minim.mdp -c b4em.gro -p topol.top -o em.tpr
dplace -c 0-49 mdrun_d -v -s em.tpr -o em.trr -c em.gro -e em.edr -g em.log -nt 50
make_ndx_d -f em.gro -o index.ndx     16 | 14     and then 1 | 13
grompp_d -f nvt.mdp -c em.gro -p topol.top -n index.ndx -o nvt.tpr
dplace -c 0-99 mdrun_d -v -s nvt.tpr -o nvt.trr -e nvt.edr -c nvt.gro -cpo nvt.cpt -g nvt.log -nt 100 &
grompp_d -f npt.mdp -c nvt.gro -t nvt.cpt -p topol.top -n index.ndx -o npt.tpr
dplace -c 100-195 mdrun_d -v -s npt.tpr -o npt.trr -e npt.edr -c npt.gro -cpo npt.cpt -g npt.log -nt 96 &
grompp_d -f md.mdp -c npt.gro -t npt.cpt -p topol.top -n index.ndx -o md.tpr
dplace -c 0-119 mdrun_d -v -s md.tpr -o md.trr -e md.edr -c md.gro -cpo md.cpt -g md.log -nt 120 &
