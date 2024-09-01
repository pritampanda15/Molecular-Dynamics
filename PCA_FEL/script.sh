#!/bin/bash

# Set the step size
STEP=10

# Loop from 0 to 90 (since we want up to 100, but the last step ends at 90-100)
for ((i=0; i<100; i+=STEP)); do
  # Calculate the start and end of the range
  start=$i
  end=$((i + STEP))

  # Create the filenames based on the range
  eigenval="md_${start}_${end}_eigenval.xvg"
  eigenvec="md_${start}_${end}_eigenvec.trr"
  pca_2dproj="PCA_2dproj_md_${start}_${end}.xvg"
  fel_sham="FEL_PCA_sham_md_${start}_${end}"

  # Run gmx covar
  echo 20 20 | gmx covar -f ../md_0_100_fit.xtc -s ../md_0_100.tpr -n ../index.ndx -o $eigenval -v $eigenvec -b $start -e $end -tu ns

  # Run gmx anaeig
  echo 20 20 |gmx anaeig -v $eigenvec -f ../md_0_100_fit.xtc -eig $eigenval -s ../md_0_100.tpr -first 1 -last 2 -2d $pca_2dproj -n ../index.ndx

  # Run gmx sham
  gmx sham -f $pca_2dproj -ls ${fel_sham}.xpm -notime

  # Run xpm2ps
  gmx xpm2ps -f ${fel_sham}.xpm -o ${fel_sham}.eps -rainbow red

  # Convert .eps to .pdf
  convert ${fel_sham}.eps ${fel_sham}.pdf

  rm *#
done
