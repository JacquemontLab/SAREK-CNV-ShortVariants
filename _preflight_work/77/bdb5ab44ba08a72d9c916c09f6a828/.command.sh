#!/usr/bin/env bash -C -e -u -o pipefail
echo "" | gzip > test_sample.chr22.tiddit.vcf.gz
touch test_sample.chr22.tiddit.vcf.gz.tbi

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:BAM_VARIANT_CALLING_GERMLINE_ALL:BAM_VARIANT_CALLING_SINGLE_TIDDIT:TABIX_BGZIP_TIDDIT_SV":
    tabix: $(echo $(tabix -h 2>&1) | sed 's/^.*Version: //; s/ .*$//')
END_VERSIONS
