#!/usr/bin/env bash
# =============================================================================
# Sliding-Window PCA & Free Energy Landscape (FEL) Analysis (GROMACS)
# =============================================================================
# Splits a trajectory into fixed time windows (default: 0-10, 10-20, ..., 90-100 ns)
# and for each window computes:
#   1. Covariance matrix, eigenvalues, and eigenvectors (`gmx covar`)
#   2. 2D projection along PC1 and PC2 (`gmx anaeig`)
#   3. Gibbs Free Energy Landscape (`gmx sham`)
#   4. Colorized EPS and PDF contour plots (`gmx xpm2ps` + ImageMagick `convert`)
#
# Usage:
#   chmod +x run_pca_fel_windows.sh
#   ./run_pca_fel_windows.sh
#
# Optional environment overrides:
#   TRAJ=../md_0_100_fit.xtc TPR=../md_0_100.tpr INDEX=../index.ndx \
#   GROUP=20 STEP=10 TOTAL_NS=100 GMX=gmx ./run_pca_fel_windows.sh
# =============================================================================

set -euo pipefail

GMX="${GMX:-gmx}"
TRAJ="${TRAJ:-../md_0_100_fit.xtc}"
TPR="${TPR:-../md_0_100.tpr}"
INDEX="${INDEX:-../index.ndx}"
GROUP="${GROUP:-20}"         # Index group for both least-squares fit and covariance analysis
STEP="${STEP:-10}"           # Window size in ns
TOTAL_NS="${TOTAL_NS:-100}"  # Total trajectory length in ns

for ((start = 0; start < TOTAL_NS; start += STEP)); do
    end=$((start + STEP))

    eigenval="md_${start}_${end}_eigenval.xvg"
    eigenvec="md_${start}_${end}_eigenvec.trr"
    pca_2dproj="PCA_2dproj_md_${start}_${end}.xvg"
    fel_sham="FEL_PCA_sham_md_${start}_${end}"

    echo "=== Analyzing window ${start}-${end} ns ==="

    # 1. Covariance analysis
    printf "%s\n%s\n" "${GROUP}" "${GROUP}" | "${GMX}" covar \
        -f "${TRAJ}" -s "${TPR}" -n "${INDEX}" \
        -o "${eigenval}" -v "${eigenvec}" \
        -b "${start}" -e "${end}" -tu ns

    # 2. 2D projection onto PC1 and PC2
    printf "%s\n%s\n" "${GROUP}" "${GROUP}" | "${GMX}" anaeig \
        -v "${eigenvec}" -f "${TRAJ}" -eig "${eigenval}" \
        -s "${TPR}" -n "${INDEX}" \
        -first 1 -last 2 -2d "${pca_2dproj}"

    # 3. Free Energy Landscape via Boltzmann inversion
    "${GMX}" sham -f "${pca_2dproj}" -ls "${fel_sham}.xpm" -notime

    # 4. Render XPM -> EPS -> PDF
    "${GMX}" xpm2ps -f "${fel_sham}.xpm" -o "${fel_sham}.eps" -rainbow red
    if command -v convert >/dev/null 2>&1; then
        convert "${fel_sham}.eps" "${fel_sham}.pdf"
    else
        echo "Warning: ImageMagick 'convert' not found; skipping PDF conversion for ${fel_sham}.eps"
    fi

    # Remove GROMACS backup files if created
    rm -f ./*#
done

echo "PCA & FEL windowed analysis complete."
