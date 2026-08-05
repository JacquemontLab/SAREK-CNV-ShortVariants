#!/usr/bin/env bash -C -e -u -o pipefail
touch test_sample.chr22.bam
touch test_sample.chr22.bam.bai

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:CRAM_TO_BAM":
    samtools: $(echo $(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*$//')
END_VERSIONS
