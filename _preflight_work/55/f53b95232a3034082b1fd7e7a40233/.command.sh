#!/usr/bin/env bash -C -e -u -o pipefail
touch test_sample.chr22.tiddit.vcf
touch test_sample.chr22.tiddit.bcf
touch test_sample.chr22.tiddit.frq
touch test_sample.chr22.tiddit.frq.count
touch test_sample.chr22.tiddit.idepth
touch test_sample.chr22.tiddit.ldepth
touch test_sample.chr22.tiddit.ldepth.mean
touch test_sample.chr22.tiddit.gdepth
touch test_sample.chr22.tiddit.hap.ld
touch test_sample.chr22.tiddit.geno.ld
touch test_sample.chr22.tiddit.geno.chisq
touch test_sample.chr22.tiddit.list.hap.ld
touch test_sample.chr22.tiddit.list.geno.ld
touch test_sample.chr22.tiddit.interchrom.hap.ld
touch test_sample.chr22.tiddit.interchrom.geno.ld
touch test_sample.chr22.tiddit.TsTv
touch test_sample.chr22.tiddit.TsTv.summary
touch test_sample.chr22.tiddit.TsTv.count
touch test_sample.chr22.tiddit.TsTv.qual
touch test_sample.chr22.tiddit.FILTER.summary
touch test_sample.chr22.tiddit.sites.pi
touch test_sample.chr22.tiddit.windowed.pi
touch test_sample.chr22.tiddit.weir.fst
touch test_sample.chr22.tiddit.het
touch test_sample.chr22.tiddit.hwe
touch test_sample.chr22.tiddit.Tajima.D
touch test_sample.chr22.tiddit.ifreqburden
touch test_sample.chr22.tiddit.LROH
touch test_sample.chr22.tiddit.relatedness
touch test_sample.chr22.tiddit.relatedness2
touch test_sample.chr22.tiddit.lqual
touch test_sample.chr22.tiddit.imiss
touch test_sample.chr22.tiddit.lmiss
touch test_sample.chr22.tiddit.snpden
touch test_sample.chr22.tiddit.kept.sites
touch test_sample.chr22.tiddit.removed.sites
touch test_sample.chr22.tiddit.singletons
touch test_sample.chr22.tiddit.indel.hist
touch test_sample.chr22.tiddit.hapcount
touch test_sample.chr22.tiddit.mendel
touch test_sample.chr22.tiddit.FORMAT
touch test_sample.chr22.tiddit.INFO
touch test_sample.chr22.tiddit.012
touch test_sample.chr22.tiddit.012.indv
touch test_sample.chr22.tiddit.012.pos
touch test_sample.chr22.tiddit.impute.hap
touch test_sample.chr22.tiddit.impute.hap.legend
touch test_sample.chr22.tiddit.impute.hap.indv
touch test_sample.chr22.tiddit.ldhat.sites
touch test_sample.chr22.tiddit.ldhat.locs
touch test_sample.chr22.tiddit.BEAGLE.GL
touch test_sample.chr22.tiddit.BEAGLE.PL
touch test_sample.chr22.tiddit.ped
touch test_sample.chr22.tiddit.map
touch test_sample.chr22.tiddit.tped
touch test_sample.chr22.tiddit.tfam
touch test_sample.chr22.tiddit.diff.sites_in_files
touch test_sample.chr22.tiddit.diff.indv_in_files
touch test_sample.chr22.tiddit.diff.sites
touch test_sample.chr22.tiddit.diff.indv
touch test_sample.chr22.tiddit.diff.discordance.matrix
touch test_sample.chr22.tiddit.diff.switch

cat <<-END_VERSIONS > versions.yml
"NFCORE_SAREK:SAREK:VCF_QC_BCFTOOLS_VCFTOOLS:VCFTOOLS_SUMMARY":
    vcftools: $(echo $(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
END_VERSIONS
