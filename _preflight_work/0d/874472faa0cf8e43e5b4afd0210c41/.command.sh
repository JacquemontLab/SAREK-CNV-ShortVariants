#!/usr/bin/env bash -C -e -u -o pipefail
echo "" | gzip > test_sample.chr22.strelka.genome.vcf.gz
touch test_sample.chr22.strelka.genome.vcf.gz.tbi
echo "" | gzip > test_sample.chr22.strelka.variants.vcf.gz
touch test_sample.chr22.strelka.variants.vcf.gz.tbi

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:BAM_VARIANT_CALLING_GERMLINE_ALL:BAM_VARIANT_CALLING_SINGLE_STRELKA:STRELKA_SINGLE":
    strelka: $( configureStrelkaSomaticWorkflow.py --version )
END_VERSIONS
