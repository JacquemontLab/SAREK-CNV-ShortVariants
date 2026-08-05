#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# INSTALL.sh
#
# ONE-TIME setup on a node WITH internet (login/head node). Downloads
# everything needed to later run nf-core/sarek fully OFFLINE:
#
#   1. The Sarek pipeline code + config profiles + all Apptainer/Singularity
#      container images, via `nf-core pipelines download`. Images go into the
#      shared $NXF_SINGULARITY_CACHEDIR (amend mode) so they download once and
#      are reused across runs.
#   2. The GATK.GRCh38 iGenomes reference bundle, via a direct
#      `aws s3 sync --no-sign-request` from the public ngi-igenomes bucket
#      (no AWS credentials required).
#
# After this finishes, transfer nothing further: the cache dir, the downloaded
# pipeline dir, and the references dir are all on shared storage the compute
# nodes can see, so offline runs just work.
#
# Usage:
#   ./INSTALL.sh                 # both phases (pipeline+containers, then refs)
#   ./INSTALL.sh --containers-only
#   ./INSTALL.sh --refs-only
#   ./INSTALL.sh --force-refs    # re-sync refs even if they look present
#
# Everything is driven by setup/env.sh — edit paths there ONCE before running.
# Idempotent: re-running skips already-present containers and rsync-skips
# already-downloaded reference files.
# ---------------------------------------------------------------------------
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve env.sh at repo root, or fall back to setup/ (current layout).
if   [[ -f "${HERE}/env.sh" ]];       then ENV_FILE="${HERE}/env.sh"
elif [[ -f "${HERE}/setup/env.sh" ]]; then ENV_FILE="${HERE}/setup/env.sh"
else echo "ERROR: env.sh not found under ${HERE} (or ${HERE}/setup). Put env.sh in setup/." >&2; exit 1
fi
# shellcheck source=/dev/null
source "$ENV_FILE"

# --- Phase selection --------------------------------------------------------
DO_CONTAINERS=1
DO_REFS=1
FORCE_REFS=0
for arg in "$@"; do
    case "$arg" in
        --containers-only) DO_REFS=0 ;;
        --refs-only)       DO_CONTAINERS=0 ;;
        --force-refs)      FORCE_REFS=1 ;;
        -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown flag: $arg" >&2; exit 2 ;;
    esac
done

# --- Config (override in env.sh if you want) --------------------------------
SAREK_VERSION="${SAREK_VERSION:-3.8.1}"
# INSTALL_DIR = where the pipeline is downloaded (nf-core --outdir). env.sh
# normally sets it to dirname("$SAREK_DIR"); the fallback reproduces that.
INSTALL_DIR="${INSTALL_DIR:-$(dirname "${SAREK_DIR}")}"
IGENOMES_DEST="${IGENOMES_BASE}"

echo "=============================================="
echo " SAREK OFFLINE INSTALL"
echo "   version         : $SAREK_VERSION"
echo "   pipeline -> dir  : $INSTALL_DIR"
echo "   container cache  : $NXF_SINGULARITY_CACHEDIR"
echo "   igenomes -> dir  : $IGENOMES_DEST"
echo "   phases          : containers=$DO_CONTAINERS refs=$DO_REFS (force_refs=$FORCE_REFS)"
echo "=============================================="

mkdir -p "$NXF_SINGULARITY_CACHEDIR" "$IGENOMES_DEST" "$APPTAINER_TMPDIR"

# ---------------------------------------------------------------------------
# Login-node safety: apptainer's Go image-builder defaults GOMAXPROCS to the
# core count and spawns ~1 thread/core to unpack OCI layers, which can exhaust
# the login node's per-user process cap (pthread_create EAGAIN / SIGABRT).
# Cap it so container pulls survive.
# ---------------------------------------------------------------------------
export GOMAXPROCS=2
export OMP_NUM_THREADS=1

# ---------------------------------------------------------------------------
# 0 + 1. Tooling + pipeline/container download.
# ---------------------------------------------------------------------------
if [[ "$DO_CONTAINERS" -eq 1 ]]; then
    if ! command -v nf-core >/dev/null 2>&1; then
        echo "[0/3] nf-core not found — installing via pip..."
        pip install --user nf-core
    else
        echo "[0/3] nf-core CLI present: $(nf-core --version 2>&1 | tail -n1)"
    fi

    command -v apptainer >/dev/null 2>&1 || module load apptainer || {
        echo "ERROR: apptainer/singularity not available. module load apptainer first." >&2
        exit 1
    }

    echo "[1/3] Downloading Sarek $SAREK_VERSION + containers..."
    export NXF_SINGULARITY_CACHEDIR

    # Flag names changed across nf-core versions; detect and adapt.
    #   amend = write images into $NXF_SINGULARITY_CACHEDIR and reuse existing;
    #   do NOT copy into the pipeline dir or rewrite nextflow.config (correct
    #   when the download host and compute nodes share the filesystem).
    if nf-core pipelines download --help >/dev/null 2>&1; then
        echo "  using new CLI: nf-core pipelines download"
        nf-core pipelines download sarek \
            --revision "$SAREK_VERSION" \
            --outdir "$INSTALL_DIR" \
            --force \
            --compress none \
            --container-system singularity \
            --container-cache-utilisation amend \
            --download-configuration yes
    else
        echo "  using legacy CLI: nf-core download"
        if nf-core download --help 2>&1 | grep -q -- '--container-cache-utilisation'; then
            nf-core download sarek \
                --revision "$SAREK_VERSION" \
                --outdir "$INSTALL_DIR" \
                --force \
                --compress none \
                --container singularity \
                --container-cache-utilisation amend
        else
            nf-core download sarek \
                --revision "$SAREK_VERSION" \
                --outdir "$INSTALL_DIR" \
                --compress none \
                --singularity \
                --singularity-cache-only
        fi
    fi

    WF_DIR="$(find "$INSTALL_DIR" -maxdepth 2 -name main.nf -printf '%h\n' 2>/dev/null | head -n1)"
    echo "  -> pipeline code : ${WF_DIR:-$INSTALL_DIR/<version>/}  (set SAREK_DIR to this)"
else
    echo "[1/3] skipping pipeline+container download (--refs-only)"
fi

# ---------------------------------------------------------------------------
# 2. Download GATK.GRCh38 references from the PUBLIC iGenomes bucket.
#    --no-sign-request is mandatory (public bucket; without it the aws CLI
#    fails looking for credentials). Skipped if already present; --force-refs
#    overrides.
# ---------------------------------------------------------------------------
IGENOMES_SUBPATH="Homo_sapiens/GATK/GRCh38"
S3_SRC="s3://ngi-igenomes/igenomes/${IGENOMES_SUBPATH}"
DEST="${IGENOMES_DEST}/${IGENOMES_SUBPATH}"

if [[ "$DO_REFS" -eq 0 ]]; then
    echo "[2/3] skipping references (--containers-only)"
elif [[ "$FORCE_REFS" -eq 0 ]] \
     && find "$DEST" -path '*WholeGenomeFasta/*.fasta' -size +100M 2>/dev/null | grep -q .; then
    echo "[2/3] references already present in $DEST — skipping."
    echo "      (use --force-refs to re-sync, e.g. to complete a partial download)"
else
    echo "[2/3] Downloading GATK.GRCh38 iGenomes references..."
    if command -v aws >/dev/null 2>&1; then
        mkdir -p "$DEST"
        echo "  aws s3 sync (no-sign-request):"
        echo "    $S3_SRC  ->  $DEST"
        aws s3 sync --no-sign-request "$S3_SRC" "$DEST"
        echo "  references synced: $(du -sh "$DEST" 2>/dev/null | cut -f1)"
    else
        cat >&2 <<EOF
  WARNING: 'aws' CLI not found. Install it, then run:

    aws s3 sync --no-sign-request \\
      ${S3_SRC} \\
      ${DEST}

  (awscli: pip install awscli  — or module load awscli)
EOF
    fi
fi

echo
echo "=============================================="
echo " INSTALL COMPLETE"
WF_DIR="$(find "$INSTALL_DIR" -maxdepth 2 -name main.nf -printf '%h\n' 2>/dev/null | head -n1)"
echo "   Set these in setup/env.sh:"
if [[ -n "$WF_DIR" ]]; then
    echo "     SAREK_DIR=\"$WF_DIR\""
else
    echo "     SAREK_DIR=<INSTALL_DIR>/<version>   (main.nf not found yet — re-check after download completes)"
fi
echo "     IGENOMES_BASE=\"${IGENOMES_DEST}\""
echo "     NXF_SINGULARITY_CACHEDIR=\"${NXF_SINGULARITY_CACHEDIR}\""
echo " Next: bin/preflight_download.sh <csv>   then   sbatch submit_slurm.sh <csv> <outdir>"
echo "=============================================="

# ---------------------------------------------------------------------------
# 3. Finalize the offline installation.
#
# Running the helper scripts once downloads the last container(s) they depend
# on, ensuring that all components required for offline execution are present
# in the shared Apptainer cache.
# ---------------------------------------------------------------------------
echo "[3/3] Finalizing offline installation..."

if [[ "$DO_CONTAINERS" -eq 1 && "$DO_REFS" -eq 1 ]]; then
    "${HERE}/bin/prepare_samplesheet.sh" "${HERE}/tests/" "${HERE}/sample_cram.csv" --type cram
    "${HERE}/bin/prepare_samplesheet.sh" "${HERE}/tests/" "${HERE}/sample_bam.csv"  --type bam

    "${HERE}/bin/preflight_download.sh" "${HERE}/sample_cram.csv"
    "${HERE}/bin/preflight_download.sh" "${HERE}/sample_bam.csv"

    rm "${HERE}/sample_bam.csv" "${HERE}/sample_cram.csv"
else
    echo "  skipped (needs both pipeline+containers and references present;" \
         "re-run ./INSTALL.sh with no flags once both phases have completed," \
         "or run bin/preflight_download.sh manually)"
fi