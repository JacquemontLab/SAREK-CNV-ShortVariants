#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# prepare_samplesheet.sh
#
# From a directory of alignment files, this script:
#   1. Indexes every chosen BAM/CRAM (creates .bai/.crai) if the index is missing.
#   2. Emits a Sarek-ready samplesheet for `--step variant_calling`.
#
# Sarek accepts EITHER alignment type at the variant_calling step, but the CSV
# columns must match the file type:
#     CRAM -> patient,sample,sex,status,cram,crai
#     BAM  -> patient,sample,sex,status,bam,bai
# (sex/status are optional but recommended; status=0 => germline/normal.)
#
# Because a directory may contain only CRAM, only BAM, or both, a TYPE selector
# controls what gets used:
#     cram   use *.cram only            (error if none found)
#     bam    use *.bam only             (error if none found)
#     auto   per sample, prefer CRAM; fall back to BAM when only BAM exists
#            (default)
#
# NOTE: a single samplesheet is homogeneous - Sarek expects one alignment
# column set. In 'auto' mode, if the directory contains a MIX (some samples
# CRAM-only, some BAM-only), the two types cannot share one sheet; the script
# writes the majority type and reports the skipped samples, OR use --split to
# emit two sheets (<out>.cram.csv / <out>.bam.csv).
#
# Usage:
#   bin/prepare_samplesheet.sh <DIR> <OUTPUT_CSV> [--type cram|bam|auto] \
#                              [--sex XX|XY|NA] [--status 0|1] [--split]
#
# Examples:
#   bin/prepare_samplesheet.sh /path/to/aln sheet.csv --type cram --sex XX
#   bin/prepare_samplesheet.sh /path/to/aln sheet.csv               # auto
#   bin/prepare_samplesheet.sh /path/to/aln sheet.csv --split       # 2 sheets if mixed
#
# Assumptions:
#   - One alignment file == one sample; patient & sample IDs are the basename
#     minus the .cram/.bam extension. Adjust the derivation below if needed.
#   - `samtools` is on PATH (module load samtools, or conda/apptainer).
# ---------------------------------------------------------------------------
set -euo pipefail

# --- Positional args --------------------------------------------------------
DIR="${1:?Usage: prepare_samplesheet.sh <DIR> <OUTPUT_CSV> [--type cram|bam|auto] [--sex ..] [--status ..] [--split]}"
OUTPUT_CSV="${2:?Usage: prepare_samplesheet.sh <DIR> <OUTPUT_CSV> [--type cram|bam|auto] [--sex ..] [--status ..] [--split]}"
shift 2

# --- Options (with defaults) ------------------------------------------------
TYPE="auto"          # cram | bam | auto
SEX="NA"             # XX | XY | NA
STATUS="0"           # 0 = normal/germline, 1 = tumor
SPLIT=0              # if 1 and mixed in auto mode, write two sheets
while [[ $# -gt 0 ]]; do
    case "$1" in
        --type)   TYPE="${2:?--type needs a value}"; shift 2 ;;
        --sex)    SEX="${2:?--sex needs a value}";  shift 2 ;;
        --status) STATUS="${2:?--status needs a value}"; shift 2 ;;
        --split)  SPLIT=1; shift ;;
        -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

case "$TYPE" in cram|bam|auto) ;; *) echo "ERROR: --type must be cram|bam|auto (got '$TYPE')" >&2; exit 2 ;; esac

command -v samtools >/dev/null 2>&1 || {
    echo "ERROR: samtools not found on PATH. module load samtools (or activate env)." >&2
    exit 1
}

DIR="$(readlink -f "$DIR")"

# --- Discover files ---------------------------------------------------------
shopt -s nullglob
crams=("$DIR"/*.cram)
bams=("$DIR"/*.bam)
shopt -u nullglob

echo "Directory : $DIR"
echo "Found     : ${#crams[@]} CRAM, ${#bams[@]} BAM   (type=$TYPE)"

# Index one alignment file if its index is missing (idempotent).
# $1 = alignment path, $2 = index extension (crai|bai)
index_if_needed() {
    local aln="$1" ext="$2"
    if [[ -f "${aln}.${ext}" ]]; then
        echo "  index ok : $(basename "$aln")"
    else
        echo "  indexing : $(basename "$aln")"
        samtools index "$aln"
    fi
}

# Write a samplesheet of a single type.
# $1 = out csv, $2 = data_col (cram|bam), $3 = idx_col (crai|bai), rest = files
write_sheet() {
    local out="$1" datacol="$2" idxcol="$3"; shift 3
    local files=("$@")
    {
        echo "patient,sample,sex,status,${datacol},${idxcol}"
        for f in "${files[@]}"; do
            local base; base="$(basename "$f")"; base="${base%.*}"   # strip .cram/.bam
            echo "${base},${base},${SEX},${STATUS},${f},${f}.${idxcol}"
        done
    } > "$out"
    echo "Wrote samplesheet: $out  (${#files[@]} sample(s), ${datacol}/${idxcol})"
    echo "----------------------------------------"
    if command -v column >/dev/null 2>&1; then
        column -t -s, "$out" | sed 's/^/  /'
    else
        sed 's/^/  /' "$out"
    fi
}

# ---------------------------------------------------------------------------
# TYPE = cram  or  bam  -> straightforward single-type sheet
# ---------------------------------------------------------------------------
if [[ "$TYPE" == "cram" ]]; then
    [[ ${#crams[@]} -gt 0 ]] || { echo "ERROR: no *.cram in $DIR" >&2; exit 1; }
    for c in "${crams[@]}"; do index_if_needed "$c" crai; done
    write_sheet "$OUTPUT_CSV" cram crai "${crams[@]}"
    exit 0
fi

if [[ "$TYPE" == "bam" ]]; then
    [[ ${#bams[@]} -gt 0 ]] || { echo "ERROR: no *.bam in $DIR" >&2; exit 1; }
    for b in "${bams[@]}"; do index_if_needed "$b" bai; done
    write_sheet "$OUTPUT_CSV" bam bai "${bams[@]}"
    exit 0
fi

# ---------------------------------------------------------------------------
# TYPE = auto  -> per-sample prefer CRAM, fall back to BAM.
#   Build sample -> chosen path maps, keyed by sample basename so a sample with
#   both formats uses the CRAM and the BAM is ignored.
# ---------------------------------------------------------------------------
declare -A cram_of bam_of
for c in "${crams[@]}"; do n="$(basename "$c" .cram)"; cram_of["$n"]="$c"; done
for b in "${bams[@]}";  do n="$(basename "$b" .bam)";  bam_of["$n"]="$b";  done

# Union of all sample names.
declare -A seen
for n in "${!cram_of[@]}"; do seen["$n"]=1; done
for n in "${!bam_of[@]}";  do seen["$n"]=1; done
[[ ${#seen[@]} -gt 0 ]] || { echo "ERROR: no *.cram or *.bam in $DIR" >&2; exit 1; }

chosen_crams=(); chosen_bams=()
for n in "${!seen[@]}"; do
    if [[ -n "${cram_of[$n]:-}" ]]; then
        chosen_crams+=("${cram_of[$n]}")
    else
        chosen_bams+=("${bam_of[$n]}")
    fi
done

echo "auto: ${#chosen_crams[@]} sample(s) via CRAM, ${#chosen_bams[@]} via BAM (BAM used only when no CRAM)"

# Homogeneous case: everything resolved to one type -> single sheet.
if [[ ${#chosen_bams[@]} -eq 0 ]]; then
    for c in "${chosen_crams[@]}"; do index_if_needed "$c" crai; done
    write_sheet "$OUTPUT_CSV" cram crai "${chosen_crams[@]}"
    exit 0
fi
if [[ ${#chosen_crams[@]} -eq 0 ]]; then
    for b in "${chosen_bams[@]}"; do index_if_needed "$b" bai; done
    write_sheet "$OUTPUT_CSV" bam bai "${chosen_bams[@]}"
    exit 0
fi

# Mixed case: some samples CRAM, some BAM. One CSV can't hold both column sets.
if [[ "$SPLIT" -eq 1 ]]; then
    cram_csv="${OUTPUT_CSV%.csv}.cram.csv"
    bam_csv="${OUTPUT_CSV%.csv}.bam.csv"
    for c in "${chosen_crams[@]}"; do index_if_needed "$c" crai; done
    for b in "${chosen_bams[@]}";  do index_if_needed "$b" bai;  done
    write_sheet "$cram_csv" cram crai "${chosen_crams[@]}"
    write_sheet "$bam_csv"  bam  bai  "${chosen_bams[@]}"
    echo
    echo "Mixed input split into two sheets (run Sarek once per sheet):"
    echo "  $cram_csv"
    echo "  $bam_csv"
    exit 0
fi

# Mixed but no --split: write the majority type, warn about the rest.
echo "WARNING: directory has a MIX of CRAM-only and BAM-only samples." >&2
echo "         A single Sarek samplesheet can't mix cram/bam columns." >&2
if [[ ${#chosen_crams[@]} -ge ${#chosen_bams[@]} ]]; then
    echo "         Writing the CRAM samples; re-run with --split for both, or --type bam for the rest." >&2
    for c in "${chosen_crams[@]}"; do index_if_needed "$c" crai; done
    write_sheet "$OUTPUT_CSV" cram crai "${chosen_crams[@]}"
    echo "  Skipped BAM-only samples: ${#chosen_bams[@]}" >&2
else
    echo "         Writing the BAM samples; re-run with --split for both, or --type cram for the rest." >&2
    for b in "${chosen_bams[@]}"; do index_if_needed "$b" bai; done
    write_sheet "$OUTPUT_CSV" bam bai "${chosen_bams[@]}"
    echo "  Skipped CRAM-only samples: ${#chosen_crams[@]}" >&2
fi