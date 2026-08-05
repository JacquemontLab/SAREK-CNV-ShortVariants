#!/usr/bin/env bash -C -e -u -o pipefail
mkdir "indexcov"
echo "" | gzip > "indexcov/indexcov-indexcov.bed.gz"
touch "indexcov/indexcov-indexcov.bed.gz.tbi"

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:BAM_VARIANT_CALLING_GERMLINE_ALL:BAM_VARIANT_CALLING_INDEXCOV:GOLEFT_INDEXCOV":
    goleft: $(goleft --version 2>&1 | head -n 1 | sed 's/^.*goleft Version: //')
    tabix: $(echo $(tabix -h 2>&1) | sed 's/^.*Version: //; s/ .*$//')
END_VERSIONS
