#!/usr/bin/env bash -C -e -u -o pipefail
touch test_sample.chr22.tiddit.vcf
touch test_sample.chr22.tiddit.ploidies.tab

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:BAM_VARIANT_CALLING_GERMLINE_ALL:BAM_VARIANT_CALLING_SINGLE_TIDDIT:TIDDIT_SV":
    tiddit: $(echo $(tiddit 2>&1) | sed 's/^.*tiddit-//; s/ .*$//')
END_VERSIONS
