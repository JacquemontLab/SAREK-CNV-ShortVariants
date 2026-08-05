#!/usr/bin/env bash -C -e -u -o pipefail
touch test_sample.chr22.recal.cram.stats

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:CRAM_SAMPLEQC:CRAM_QC_RECAL:SAMTOOLS_STATS":
    samtools: $(echo $(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*$//')
END_VERSIONS
