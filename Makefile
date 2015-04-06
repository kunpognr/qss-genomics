FASTQ=sim
FASTQ_READS=10000
FASTA=chr22.fa
DWGSIM_HOME=../dwgsim
BWA_HOME=../bwa
SAMTOOLS_HOME=../samtools
ADAM_HOME=../adam
AVOCADO_HOME=../avocado
AVOCADO_CONF=../avocado/avocado-sample-configs/basic.properties
#AVOCADO_CONF=../avocado/avocado-sample-configs/snap-basic.properties

#placeholder for spark tuning (threadcount, etc)
#SPARK_HOME=
#SPARK_CONF=

fastq :
	${DWGSIM_HOME}/dwgsim -N ${FASTQ_READS} ${FASTA} ${FASTQ}
	mv ${FASTQ}.bfast.fastq ${FASTQ}.fq

index :
	${MAKE} ${FASTA}.bwa

%.fa.bwa : %.fa
	${BWA_HOME}/bwa index $< > $@
	touch -c $@

%.fa.adam : %.fa
	${ADAM_HOME}/bin/adam-submit fasta2adam $< $@

%.sam : %.fq
	${MAKE} fastq index
	${BWA_HOME}/bwa mem ${FASTA} ${FASTQ}.fq > ${FASTQ}.sam

%.bam : %.sam
	${SAMTOOLS_HOME}/samtools view -bS $< > $@

%.bam.adam : %.bam
	${ADAM_HOME}/bin/adam-submit transform $< $@

%.vcf.adam : %.bam.adam
	${MAKE} ${FASTA}.adam
	${AVOCADO_HOME}/bin/avocado-submit $< ${FASTA}.adam $@ ${AVOCADO_CONF}

%.vcf : %.vcf.adam
	${ADAM_HOME}/bin/adam-submit adam2vcf $< $@

