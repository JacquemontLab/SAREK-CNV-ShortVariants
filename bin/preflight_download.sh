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
# Resolve env.sh at repo root, or fall back to bin/ (in case of layout drift).
if   [[ -f "${HERE}/env.sh" ]];     then ENV_FILE="${HERE}/env.sh"
elif [[ -f "${HERE}/setup/env.sh" ]]; then ENV_FILE="${HERE}/setup/env.sh"
else echo "ERROR: env.sh not found under ${HERE} (or ${HERE}/bin). Copy env.sh to the repo root." >&2; exit 1
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

mkdir -p "$NXF_SINGULARITY_CACHEDIR"

echo "=============================================="
echo " PRE-FLIGHT (online, login node) — caching containers"
echo "   cache dir : $NXF_SINGULARITY_CACHEDIR"
echo "   sarek     : $SAREK_DIR"
echo "   tools     : $SAREK_TOOLS"
echo "   ulimit -u : $(ulimit -u)"
echo "=============================================="

module load apptainer 2>/dev/null || true

# --- Restrict the environment so the login node doesn't kill us -------------
# THE key fix: apptainer's Go image-builder sets GOMAXPROCS=nproc and spawns
# ~1 thread per core to unpack OCI layers; on a 64-core login node that blows
# the per-user process cap -> pthread_create EAGAIN / SIGABRT during pull.
export GOMAXPROCS=2
export OMP_NUM_THREADS=1
# Also cap the Nextflow driver JVM: few GC/JIT threads (else it makes ~1 per
# core on a big login node) and a small heap.
export NXF_OPTS="-XX:ActiveProcessorCount=2 -XX:+UseSerialGC -Xms256m -Xmx1500m"
# Don't let Nextflow's own singularity puller run many pulls in parallel.
export NXF_SINGULARITY_CACHEDIR
# A tiny throwaway config that forces near-serial local execution during the
#    stub run (stubs are trivial, so serial is fine and keeps thread count low).
PREFLIGHT_CFG="$(mktemp "${TMPDIR:-/tmp}/preflight_XXXX.config")"
cat > "$PREFLIGHT_CFG" <<'CFG'
executor {
    name        = 'local'
    queueSize   = 2
    cpus        = 4
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