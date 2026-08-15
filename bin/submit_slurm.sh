#!/bin/bash
#SBATCH --job-name=sarek_cram_vc
#SBATCH --mail-type=END,FAIL
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=192
#SBATCH --mem-per-cpu=3500MB
#SBATCH --time=48:00:00
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
#   sbatch submit_slurm.sh <SAMPLESHEET_CSV> <OUTPUT_DIR> <GIT_DIR>
# ---------------------------------------------------------------------------
set -euo pipefail

HERE=$3
# Resolve env.sh at repo root, or fall back to setup/ (current layout).
if   [[ -f "${HERE}/env.sh" ]];       then ENV_FILE="${HERE}/env.sh"
elif [[ -f "${HERE}/setup/env.sh" ]]; then ENV_FILE="${HERE}/setup/env.sh"
else echo "ERROR: env.sh not found under ${HERE} (or ${HERE}/setup). Put env.sh in setup/." >&2; exit 1
fi
# shellcheck source=/dev/null
source "$ENV_FILE"

SAMPLESHEET="${1:?Usage: sbatch submit_slurm.sh <SAMPLESHEET_CSV> <OUTPUT_DIR>}"
OUT_DIR="${2:?Usage: sbatch submit_slurm.sh <SAMPLESHEET_CSV> <OUTPUT_DIR>}"
mkdir -p "$OUT_DIR"

# Work dir. SLURM_TMPDIR is fast per-job local scratch but is WIPED at job end,
# which breaks -resume. Keep work on shared storage so -resume works across
# requeues; switch to SLURM_TMPDIR only for single-shot throwaway runs.
WORK_DIR="${OUT_DIR}/nf-work"
mkdir -p "$WORK_DIR" "$APPTAINER_TMPDIR"

# Detect resources actually allocated to THIS job (not the whole node).
# /proc/meminfo reports the WHOLE NODE's physical RAM, not this job's cgroup
# allocation -- on a shared (non-exclusive) node that overestimates what's
# actually available and can lead Nextflow to schedule more than the job's
# cgroup memory limit allows. Prefer Slurm's own allocation env vars.
CPUS="${SLURM_CPUS_PER_TASK:-$(nproc)}"
if   [[ -n "${SLURM_MEM_PER_NODE:-}" ]]; then
    MAX_MEM_GB=$(( SLURM_MEM_PER_NODE * 95 / 100 / 1024 ))
elif [[ -n "${SLURM_MEM_PER_CPU:-}" ]]; then
    MAX_MEM_GB=$(( SLURM_MEM_PER_CPU * CPUS * 95 / 100 / 1024 ))
else
    MEM_GB=$(awk '/MemTotal/{printf "%.0f",$2/1024/1024}' /proc/meminfo)
    MAX_MEM_GB=$(( MEM_GB * 95 / 100 ))
fi

echo "=============================================="
echo "  Samplesheet : $SAMPLESHEET"
echo "  Out dir     : $OUT_DIR"
echo "  Work dir    : $WORK_DIR"
echo "  CPUs        : $CPUS   Mem: ${MAX_MEM_GB} GB"
echo "  Started     : $(date)"
echo "=============================================="

module load apptainer
export NXF_OFFLINE="true"

# This Sarek version has no --max_cpus/--max_memory params (no check_max()
# anywhere in the bundled pipeline) -- it caps per-process resource requests
# via Nextflow's native `process.resourceLimits` directive instead (see
# sarek-3.8.1-offline/3_8_1/conf/test.config for the same pattern). Without
# this, labels like process_medium/process_high_memory can request far more
# than this job's actual Slurm allocation.
RESOURCE_CFG="$(mktemp "${TMPDIR:-/tmp}/sarek_resources_XXXX.config")"
cat > "$RESOURCE_CFG" <<CFG
process {
    resourceLimits = [
        cpus:   ${CPUS},
        memory: '${MAX_MEM_GB}.GB',
        time:   '24.h'
    ]
}
executor {
    name   = 'local'
    cpus   = ${CPUS}
    memory = '${MAX_MEM_GB}.GB'
}
CFG
trap 'rm -f "$RESOURCE_CFG"' EXIT

"$NEXTFLOW_BIN" run "$SAREK_DIR/" \
    -c "${HERE}/setup/sarek.config" \
    -c "$RESOURCE_CFG" \
    -profile apptainer \
    --input "$SAMPLESHEET" \
    --outdir "$OUT_DIR" \
    -work-dir "$WORK_DIR" \
    --genome "$GENOME" \
    --step variant_calling \
    --igenomes_base "$IGENOMES_BASE" \
    --tools "$SAREK_TOOLS" \
    --vep_cache NULL \
    --snpeff_cache NULL \
    -with-report -with-timeline \
    -offline -resume

echo "Sarek finished at $(date)"