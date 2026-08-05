#!/usr/bin/env bash -C -e -u -o pipefail
# write header only
samtools \
    view \
    --header-only \
    --threads 2 \
    -O BAM \
    -o "test_sample.chr22.reindex.bam" \
    --reference Homo_sapiens_assembly38.fasta \
    test_sample.chr22.cram

# write BAM index only, remove unmapped, supplementary, etc...
samtools \
    view \
    --uncompressed \
    --write-index \
    --threads 2 \
    -O BAM \
    -o "/dev/null##idx##test_sample.chr22.reindex.bam.bai" \
    --reference Homo_sapiens_assembly38.fasta \
     -F 3844 -q 30  \
    test_sample.chr22.cram

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:BAM_VARIANT_CALLING_GERMLINE_ALL:BAM_VARIANT_CALLING_INDEXCOV:SAMTOOLS_REINDEX_BAM":
    samtools: $(echo $(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*$//')
END_VERSIONS
