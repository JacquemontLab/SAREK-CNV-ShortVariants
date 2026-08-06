#!/bin/bash
# ---------------------------------------------------------------------------
# preflight_download.sh
#
# Run this ONCE on a node that HAS internet access (e.g. a login node) to cache
# every Sarek container image locally. Compute nodes then run fully OFFLINE
# (-offline / NXF_OFFLINE=true) and never need the network.
#
# It uses `-stub-run`: Nextflow resolves the whole workflow DAG and PULLS every
# container, but replaces each process body with a trivial stub — so no real
# HaplotypeCaller/Strelka JVMs are launched and no genomics is done.
#
# Why the restricted environment: on a login node the per-user thread/process
# limit is low. A normal Nextflow launch (driver JVM + one JVM per interval)
# spawns enough threads to hit `pthread_create ... EAGAIN / unable to create
# native thread`. Here we clamp the driver JVM's thread + heap use and force
# the local executor to run (stub) tasks nearly serially, so the prefetch
# survives the login node long enough to pull all images.
#
# Usage:
#   bin/preflight_download.sh <SAMPLESHEET_CSV>
#
# Requires the same env.sh as the real run.
# ---------------------------------------------------------------------------
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Resolve env.sh at repo root, or fall back to setup/ (current layout).
if   [[ -f "${HERE}/env.sh" ]];       then ENV_FILE="${HERE}/env.sh"
elif [[ -f "${HERE}/setup/env.sh" ]]; then ENV_FILE="${HERE}/setup/env.sh"
else echo "ERROR: env.sh not found under ${HERE} (or ${HERE}/setup). Put env.sh in setup/." >&2; exit 1
fi
# shellcheck source=/dev/null
source "$ENV_FILE"

SAMPLESHEET="${1:?Usage: preflight_download.sh <SAMPLESHEET_CSV> [--real]}"
# --real : do a real (non-stub) run instead of -stub-run. Slower and does some
#          compute, but pulls containers for any process lacking a stub block.
#          Still thread-restricted so it survives the login node. Ctrl-C once
#          all images are cached (you don't need it to finish).
STUB_FLAG="-stub-run"
[[ "${2:-}" == "--real" ]] && STUB_FLAG=""

mkdir -p "$NXF_SINGULARITY_CACHEDIR" "$APPTAINER_TMPDIR"

echo "=============================================="
echo " PRE-FLIGHT (online, login node) — caching containers"
echo "   cache dir : $NXF_SINGULARITY_CACHEDIR"
echo "   build tmp : $APPTAINER_TMPDIR"
echo "   sarek     : $SAREK_DIR"
echo "   tools     : $SAREK_TOOLS"
echo "   ulimit -u : $(ulimit -u)"
echo "=============================================="

module load apptainer 2>/dev/null || true

# --- Restrict the environment so the login node doesn't kill us -------------
# export GOMAXPROCS=2

# # Apptainer image build/runtime thread limits
# export APPTAINER_BUILD_NPROC=2
# export APPTAINER_PULLFUSE=0
# export APPTAINER_MKSQUASHFS_OPTIONS="-processors 1"
# export APPTAINER_SQUASHFS_ARGS="-processors 1"
# export APPTAINER_NO_FUSE=1
# export APPTAINER_SIF_FUSE=0
# export APPTAINERENV_OPENBLAS_NUM_THREADS=1
# export APPTAINERENV_OMP_NUM_THREADS=1
# export APPTAINERENV_MKL_NUM_THREADS=1
# export APPTAINERENV_NUMEXPR_NUM_THREADS=1
# # Scientific Python/OpenBLAS thread limits
# export OPENBLAS_NUM_THREADS=1
# export MKL_NUM_THREADS=1
# export NUMEXPR_NUM_THREADS=1
# export OMP_NUM_THREADS=1

# # Nextflow JVM limits
# export NXF_OPTS="-XX:ActiveProcessorCount=2 -XX:+UseSerialGC -Xms256m -Xmx1500m"

export NXF_SINGULARITY_CACHEDIR
# A tiny throwaway config that forces near-serial local execution during the
#    stub run (stubs are trivial, so serial is fine and keeps thread count low).
PREFLIGHT_CFG="$(mktemp "${TMPDIR:-/tmp}/preflight_XXXX.config")"
cat > "$PREFLIGHT_CFG" <<'CFG'
process {
    maxForks = 1
    // Stub tasks do trivial `touch`/no-op work, so the resource *requests*
    // Sarek's base.config computes per label (e.g. process_medium = 36.GB)
    // are fiction here. Cap them well under a typical login node's real
    // memory so Nextflow's local-executor preflight check doesn't reject
    // a task for "exceeding available memory" before it ever runs.
    resourceLimits = [
        cpus:   8,
        memory: '8.GB',
        time:   '2.h'
    ]
}
executor {
    name        = 'local'
    queueSize   = 2
    cpus        = 8
}
singularity {
    pullTimeout = '2h'
}
CFG
trap 'rm -f "$PREFLIGHT_CFG"' EXIT

# ONLINE here: do NOT set -offline / NXF_OFFLINE.
# -stub-run resolves + pulls every container without real process execution.
"$NEXTFLOW_BIN" run "$SAREK_DIR" \
    -c "${HERE}/setup/sarek.config" \
    -c "$PREFLIGHT_CFG" \
    -profile apptainer \
    --input "$SAMPLESHEET" \
    --outdir "${HERE}/_preflight_out" \
    -work-dir "${HERE}/_preflight_work" \
    --genome "$GENOME" \
    --step variant_calling \
    --igenomes_base "$IGENOMES_BASE" \
    --tools "$SAREK_TOOLS" \
    --vep_cache NULL \
    --snpeff_cache NULL \
    $STUB_FLAG

echo
echo "Pre-flight complete. Containers cached in:"
echo "   $NXF_SINGULARITY_CACHEDIR"
echo "Now submit the offline job:  sbatch submit_slurm.sh $SAMPLESHEET <outdir>"

# Clean the throwaway stub outputs.
rm -rf "${HERE}/_preflight_out" "${HERE}/_preflight_work"