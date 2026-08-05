#!/bin/bash
#SBATCH --job-name=sarek_cram_vc
#SBATCH --mail-type=END,FAIL
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=4000MB
#SBATCH --time=24:00:00
#SBATCH --output=sarek_cram_vc_%j.log
#SBATCH --account=rrg-jacquese
# ---------------------------------------------------------------------------
# submit_slurm.sh — OFFLINE Sarek variant_calling run on a compute node.
#
# Prerequisite: run bin/preflight_download.sh ONCE on the login node first,
# so all containers are cached. This job runs with -offline and never touches
# the internet.
#
# Usage:
#   sbatch submit_slurm.sh <SAMPLESHEET_CSV> <OUTPUT_DIR>
# ---------------------------------------------------------------------------
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${HERE}/env.sh"

SAMPLESHEET="${1:?Usage: sbatch submit_slurm.sh <SAMPLESHEET_CSV> <OUTPUT_DIR>}"
OUT_DIR="${2:?Usage: sbatch submit_slurm.sh <SAMPLESHEET_CSV> <OUTPUT_DIR>}"
mkdir -p "$OUT_DIR"

# Work dir. SLURM_TMPDIR is fast per-job local scratch but is WIPED at job end,
# which breaks -resume. Keep work on shared storage so -resume works across
# requeues; switch to SLURM_TMPDIR only for single-shot throwaway runs.
WORK_DIR="${OUT_DIR}/nf-work"
mkdir -p "$WORK_DIR"

# Detect resources actually allocated to THIS job (not the whole node).
CPUS="${SLURM_CPUS_PER_TASK:-$(nproc)}"
MEM_GB=$(awk '/MemTotal/{printf "%.0f",$2/1024/1024}' /proc/meminfo)
MAX_MEM_GB=$(( MEM_GB * 95 / 100 ))

echo "=============================================="
echo "  Samplesheet : $SAMPLESHEET"
echo "  Out dir     : $OUT_DIR"
echo "  Work dir    : $WORK_DIR"
echo "  CPUs        : $CPUS   Mem: ${MAX_MEM_GB} GB"
echo "  Started     : $(date)"
echo "=============================================="

module load apptainer
export NXF_OFFLINE="true"

"$NEXTFLOW_BIN" run "$SAREK_DIR/" \
    -c "${HERE}/bin/sarek.config" \
    -profile apptainer \
    --input "$SAMPLESHEET" \
    --outdir "$OUT_DIR" \
    -work-dir "$WORK_DIR" \
    --genome "$GENOME" \
    --step variant_calling \
    --igenomes_base "$IGENOMES_BASE" \
    --tools "$SAREK_TOOLS" \
    --max_cpus "8" \
    --max_memory "50.GB" \
    --vep_cache NULL \
    --snpeff_cache NULL \
    -with-report -with-timeline \
    -offline -resume

echo "Sarek finished at $(date)"