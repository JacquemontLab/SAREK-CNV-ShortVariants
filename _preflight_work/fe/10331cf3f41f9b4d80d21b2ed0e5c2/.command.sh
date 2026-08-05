#!/usr/bin/env bash -C -e -u -o pipefail
touch test_sample.chr22.recal.global.dist.txt
touch test_sample.chr22.recal.region.dist.txt
touch test_sample.chr22.recal.summary.txt
touch test_sample.chr22.recal.per-base.d4
echo "" | gzip > test_sample.chr22.recal.per-base.bed.gz
touch test_sample.chr22.recal.per-base.bed.gz.csi
echo "" | gzip > test_sample.chr22.recal.regions.bed.gz
touch test_sample.chr22.recal.regions.bed.gz.csi
echo "" | gzip > test_sample.chr22.recal.quantized.bed.gz
touch test_sample.chr22.recal.quantized.bed.gz.csi
echo "" | gzip > test_sample.chr22.recal.thresholds.bed.gz
touch test_sample.chr22.recal.thresholds.bed.gz.csi

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:CRAM_SAMPLEQC:CRAM_QC_RECAL:MOSDEPTH":
    mosdepth: $(mosdepth --version 2>&1 | sed 's/^.*mosdepth //; s/ .*$//')
END_VERSIONS
