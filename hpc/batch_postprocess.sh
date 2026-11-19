#!/usr/bin/env bash
# =============================================================================
# Batch Post-Processing Script for Multiple GROMACS Simulation Directories
# =============================================================================
# Iterates over every immediate subdirectory containing `md_0_1.tpr` and
# `md_0_1.xtc` and performs:
#   1. Centering & PBC cleanup (`md_0_1_center.xtc`, `md_0_1_noPBC.xtc`)
#   2. Snapshot extraction every 1000 frames (`_pro*.pdb`)
#   3. Backbone RMSD calculation (`rmsd.xvg`)
#
# Usage:
#   chmod +x batch_postprocess.sh
#   ./batch_postprocess.sh
#
# Optional environment overrides:
#   GMX=gmx PREFIX=md_0_1 SKIP=1000 ./batch_postprocess.sh
# =============================================================================

set -euo pipefail

GMX="${GMX:-gmx_mpi}"
PREFIX="${PREFIX:-md_0_1}"
SKIP="${SKIP:-1000}"

for dir in ./*/; do
    [ -d "${dir}" ] || continue
    if [ ! -f "${dir}/${PREFIX}.tpr" ] || [ ! -f "${dir}/${PREFIX}.xtc" ]; then
        echo "Skipping ${dir} (missing ${PREFIX}.tpr or ${PREFIX}.xtc)"
        continue
    fi

    echo "=== Post-processing ${dir} ==="
    (
        cd "${dir}"

        # Center on Protein (1), output System (0) with compact periodic box
        printf "1\n0\n" | "${GMX}" trjconv \
            -s "${PREFIX}.tpr" -f "${PREFIX}.xtc" \
            -o "${PREFIX}_center.xtc" -center -pbc mol -ur compact

        # Remove PBC jumps centered on Protein (1), output System (0)
        printf "1\n0\n" | "${GMX}" trjconv \
            -s "${PREFIX}.tpr" -f "${PREFIX}.xtc" \
            -o "${PREFIX}_noPBC.xtc" -pbc mol -center

        # Extract separated Protein (1) snapshots every SKIP frames
        printf "1\n1\n" | "${GMX}" trjconv \
            -s "${PREFIX}.tpr" -f "${PREFIX}_center.xtc" \
            -o _pro.pdb -sep -center -skip "${SKIP}"

        # Compute Backbone (4) RMSD fitted to Backbone (4)
        printf "4\n4\n" | "${GMX}" rms \
            -s "${PREFIX}.tpr" -f "${PREFIX}_noPBC.xtc" \
            -o rmsd.xvg -tu ns
    )
done

echo "Batch post-processing complete."
