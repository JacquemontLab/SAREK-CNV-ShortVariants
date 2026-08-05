#!/usr/bin/env bash -C -e -u -o pipefail
cnvkit.py \
    batch \
    test_sample.chr22.bam \
    --normal  \
    --fasta Homo_sapiens_assembly38.fasta \
     \
    --targets wgs_calling_regions_noseconds.hg38.bed \
    --processes 12 \
    --method wgs --diagram --scatter

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:BAM_VARIANT_CALLING_GERMLINE_ALL:BAM_VARIANT_CALLING_CNVKIT:CNVKIT_BATCH":
    cnvkit: $(cnvkit.py version | sed -e 's/cnvkit v//g')
END_VERSIONS
