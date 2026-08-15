# ---------------------------------------------------------------------------
# env.sh  — EDIT THESE PATHS ONCE for your cluster/account.
# Sourced by both preflight_download.sh and submit_slurm.sh so there is a
# single source of truth. Not executable on its own.
# ---------------------------------------------------------------------------

# --- Sarek version (used by install.sh) -------------------------------------
SAREK_VERSION="3.8.1"

# --- Nextflow binary (pinned version recommended for reproducibility) -------
NEXTFLOW_BIN="/home/flben/work_projects/bioutils/bin/nextflow-25.10.2-dist"

# --- Local clone / offline copy of the nf-core/sarek pipeline code ----------
# After running bin/install.sh this becomes:
#   <INSTALL_DIR>/<something>/workflow   (install.sh prints the exact path)
# You already have a sandbox at .../cram_hbcc/3_8_1# in env.sh
SAREK_DIR="~/links/projects/rrg-jacquese/LAB_WORKSPACE/SOFTWARE/Git_pipeline/SAREK-CNV-ShortVariants/sarek-3.8.1-offline/3_8_1"

# --- iGenomes / reference base (pre-downloaded, offline) --------------------
IGENOMES_BASE="~/links/projects/rrg-jacquese/LAB_WORKSPACE/SOFTWARE/Git_pipeline/SAREK-CNV-ShortVariants/sarek-resource-offline/references"
GENOME="GATK.GRCh38"

# --- Variant callers to run -------------------------------------------------
SAREK_TOOLS="strelka,haplotypecaller,deepvariant,cnvkit,manta,indexcov,tiddit"

# --- Container cache (shared across runs so images download only once) ------
export NXF_SINGULARITY_CACHEDIR="~/links/projects/rrg-jacquese/LAB_WORKSPACE/SOFTWARE/Git_pipeline/SAREK-CNV-ShortVariants/sarek-resource-offline/NXF_SINGULARITY_CACHEDIR"
export NXF_APPTAINER_CACHEDIR="$NXF_SINGULARITY_CACHEDIR"
export APPTAINER_CACHEDIR="$NXF_SINGULARITY_CACHEDIR"
export SINGULARITY_CACHEDIR="$NXF_SINGULARITY_CACHEDIR"

# --- Apptainer build scratch space -------------------------------------------
# Converting a large OCI image (e.g. conda-based containers) to .sif unpacks
# it into a scratch dir first. Apptainer defaults that to $TMPDIR/tmp, which
# on many systems (including this one) is a small, per-user-quota'd tmpfs --
# large images then die with "disk quota exceeded" mid-unpack. Point it at
# the same shared, plenty-large storage as the container cache instead.
export APPTAINER_TMPDIR="~/links/projects/rrg-jacquese/LAB_WORKSPACE/SOFTWARE/Git_pipeline/SAREK-CNV-ShortVariants/sarek-resource-offline/apptainer_tmp"
export SINGULARITY_TMPDIR="$APPTAINER_TMPDIR"

# --- Nextflow behaviour -----------------------------------------------------
export KMP_DUPLICATE_LIB_OK=TRUE
export NXF_OPTS="-Dprocess.cacheable=true"