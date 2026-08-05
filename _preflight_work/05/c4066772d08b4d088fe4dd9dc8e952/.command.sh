#!/usr/bin/env bash -C -e -u -o pipefail
touch test_sample.chr22.strelka.variants.vcf
touch test_sample.chr22.strelka.variants.bcf
touch test_sample.chr22.strelka.variants.frq
touch test_sample.chr22.strelka.variants.frq.count
touch test_sample.chr22.strelka.variants.idepth
touch test_sample.chr22.strelka.variants.ldepth
touch test_sample.chr22.strelka.variants.ldepth.mean
touch test_sample.chr22.strelka.variants.gdepth
touch test_sample.chr22.strelka.variants.hap.ld
touch test_sample.chr22.strelka.variants.geno.ld
touch test_sample.chr22.strelka.variants.geno.chisq
touch test_sample.chr22.strelka.variants.list.hap.ld
touch test_sample.chr22.strelka.variants.list.geno.ld
touch test_sample.chr22.strelka.variants.interchrom.hap.ld
touch test_sample.chr22.strelka.variants.interchrom.geno.ld
touch test_sample.chr22.strelka.variants.TsTv
touch test_sample.chr22.strelka.variants.TsTv.summary
touch test_sample.chr22.strelka.variants.TsTv.count
touch test_sample.chr22.strelka.variants.TsTv.qual
touch test_sample.chr22.strelka.variants.FILTER.summary
touch test_sample.chr22.strelka.variants.sites.pi
touch test_sample.chr22.strelka.variants.windowed.pi
touch test_sample.chr22.strelka.variants.weir.fst
touch test_sample.chr22.strelka.variants.het
touch test_sample.chr22.strelka.variants.hwe
touch test_sample.chr22.strelka.variants.Tajima.D
touch test_sample.chr22.strelka.variants.ifreqburden
touch test_sample.chr22.strelka.variants.LROH
touch test_sample.chr22.strelka.variants.relatedness
touch test_sample.chr22.strelka.variants.relatedness2
touch test_sample.chr22.strelka.variants.lqual
touch test_sample.chr22.strelka.variants.imiss
touch test_sample.chr22.strelka.variants.lmiss
touch test_sample.chr22.strelka.variants.snpden
touch test_sample.chr22.strelka.variants.kept.sites
touch test_sample.chr22.strelka.variants.removed.sites
touch test_sample.chr22.strelka.variants.singletons
touch test_sample.chr22.strelka.variants.indel.hist
touch test_sample.chr22.strelka.variants.hapcount
touch test_sample.chr22.strelka.variants.mendel
touch test_sample.chr22.strelka.variants.FORMAT
touch test_sample.chr22.strelka.variants.INFO
touch test_sample.chr22.strelka.variants.012
touch test_sample.chr22.strelka.variants.012.indv
touch test_sample.chr22.strelka.variants.012.pos
touch test_sample.chr22.strelka.variants.impute.hap
touch test_sample.chr22.strelka.variants.impute.hap.legend
touch test_sample.chr22.strelka.variants.impute.hap.indv
touch test_sample.chr22.strelka.variants.ldhat.sites
touch test_sample.chr22.strelka.variants.ldhat.locs
touch test_sample.chr22.strelka.variants.BEAGLE.GL
touch test_sample.chr22.strelka.variants.BEAGLE.PL
touch test_sample.chr22.strelka.variants.ped
touch test_sample.chr22.strelka.variants.map
touch test_sample.chr22.strelka.variants.tped
touch test_sample.chr22.strelka.variants.tfam
touch test_sample.chr22.strelka.variants.diff.sites_in_files
touch test_sample.chr22.strelka.variants.diff.indv_in_files
touch test_sample.chr22.strelka.variants.diff.sites
touch test_sample.chr22.strelka.variants.diff.indv
touch test_sample.chr22.strelka.variants.diff.discordance.matrix
touch test_sample.chr22.strelka.variants.diff.switch

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:VCF_QC_BCFTOOLS_VCFTOOLS:VCFTOOLS_SUMMARY":
    vcftools: $(echo $(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
END_VERSIONS
