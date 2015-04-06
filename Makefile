FASTQ=
FASTA=chr22.fa
ADAM_HOME=../adam
AVOCADO_HOME=../avocado
AVOCADO_CONF=../avocado/avocado-sample-configs/basic.properties
#placeholder for spark tuning (threadcount, etc)
#SPARK_CONF=

%.fa.adam : %.fa
	${ADAM_HOME}/bin/adam-submit fasta2adam $< $@

%.bam : %.fq
	${ADAM_HOME}/bin/adam-submit fasta2adam $< $@

%.bam.adam : %.bam
	${ADAM_HOME}/bin/adam-submit transform $< $@

%.vcf.adam : %.bam.adam
	${MAKE} ${FASTA}.adam
	${AVOCADO_HOME}/bin/avocado-submit $< ${FASTA}.adam $@ ${AVOCADO_CONF}

%.vcf : %.vcf.adam
	${ADAM_HOME}/bin/adam-submit adam2vcf $< $@

