# ---------------------------------------------------------------------------
# env.sh  — EDIT THESE PATHS ONCE for your cluster/account.
# Sourced by both preflight_download.sh and submit_slurm.sh so there is a
# single source of truth. Not executable on its own.
# ---------------------------------------------------------------------------

# --- Sarek version (used by install.sh) -------------------------------------
SAREK_VERSION="3.8.1"

# --- Nextflow binary (pinned version recommended for reproducibility) -------
NEXTFLOW_BIN="/home/flben/links/projects/rrg-jacquese/LAB_WORKSPACE/SOFTWARE/bioutils/bin/nextflow-25.10.2-dist"

# --- Local clone / offline copy of the nf-core/sarek pipeline code ----------
# After running bin/install.sh this becomes:
#   <INSTALL_DIR>/<something>/workflow   (install.sh prints the exact path)
# You already have a sandbox at .../cram_hbcc/3_8_1# in env.sh
SAREK_DIR="/lustre09/project/6008022/flben/SAREK-CNV-ShortVariants/sarek-3.8.1-offline-v2/3_8_1"

# --- iGenomes / reference base (pre-downloaded, offline) --------------------
IGENOMES_BASE="/lustre09/project/6008022/flben/SAREK-CNV-ShortVariants/sarek-resource-offline/references"
GENOME="GATK.GRCh38"

# --- Variant callers to run -------------------------------------------------
SAREK_TOOLS="strelka,haplotypecaller"

# --- Container cache (shared across runs so images download only once) ------
export NXF_SINGULARITY_CACHEDIR="/lustre09/project/6008022/flben/SAREK-CNV-ShortVariants/sarek-resource-offline-v2/NXF_SINGULARITY_CACHEDIR"
export NXF_APPTAINER_CACHEDIR="$NXF_SINGULARITY_CACHEDIR"
export APPTAINER_CACHEDIR="$NXF_SINGULARITY_CACHEDIR"
export SINGULARITY_CACHEDIR="$NXF_SINGULARITY_CACHEDIR"

# --- Nextflow behaviour -----------------------------------------------------
export KMP_DUPLICATE_LIB_OK=TRUE
export NXF_OPTS="-Dprocess.cacheable=true"