#!/usr/bin/env bash -C -e -u -o pipefail
echo "" | gzip > wgs_calling_regions_noseconds.hg38.stub.bed.gz
touch wgs_calling_regions_noseconds.hg38.stub.bed.gz.tbi

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:PREPARE_INTERVALS:TABIX_BGZIPTABIX_INTERVAL_SPLIT":
    tabix: $(echo $(tabix -h 2>&1) | sed 's/^.*Version: //; s/ .*$//')
END_VERSIONS
