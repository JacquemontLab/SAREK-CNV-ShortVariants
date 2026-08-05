#!/usr/bin/env bash -C -e -u -o pipefail
touch wgs_calling_regions_noseconds.hg38.stub.bed

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:PREPARE_INTERVALS:CREATE_INTERVALS_BED":
    gawk: $(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
END_VERSIONS
