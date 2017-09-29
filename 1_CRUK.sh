#!/bin/bash
#PBS -l walltime=20:00:00
#PBS -l ncpus=12
set -euo pipefail
PBS_O_WORKDIR=(`echo $PBS_O_WORKDIR | sed "s/^\/state\/partition1//" `)
cd $PBS_O_WORKDIR

#Description: CRUK Pipeline (Illumina paired-end). Not for use with other library preps/ experimental conditions.
#Mode: BY_SAMPLE
version="1.0.1"

# Directory structure required for pipeline
#
# /data
# └── results
#     └── seqId
#         ├── panel1
#         │   ├── sample1
#         │   ├── sample2
#         │   └── sample3
#         └── panel2
#             ├── sample1
#             ├── sample2
#             └── sample3
#
# Script 1 runs in sample folder, requires fastq files split by lane

#Variables files generated by IlluminaQC script

countQCFlagFails() {
    #count how many core FASTQC tests failed
    grep -E "Basic Statistics|Per base sequence quality|Per tile sequence quality|Per sequence quality scores|Per base N content" "$1" | \
    grep -v ^PASS | \
    grep -v ^WARN | \
    wc -l | \
    sed 's/^[[:space:]]*//g'
}

#load sample & pipeline variables
. *.variables
#. /data/diagnostics/pipelines/CRUK/CRUK-"$version"/"$panel"/"$panel".variables
. /data/diagnostics/pipelines/"$pipelineName"/"$pipelineName"-"$pipelineVersion"/"$panel"/"$pipelineName"-"$pipelineVersion"_"$panel".variables

### Preprocessing ###

#record FASTQC pass/fail
rawSequenceQuality=PASS

#convert FASTQ to uBAM & add RGIDs
for fastqPair in $(ls "$sampleId"_S*.fastq.gz | cut -d_ -f1-3 | sort | uniq); do

    #parse fastq filenames
    laneId=$(echo "$fastqPair" | cut -d_ -f3)
    read1Fastq=$(ls "$fastqPair"_R1_*fastq.gz)
    read2Fastq=$(ls "$fastqPair"_R2_*fastq.gz)

    #obtain names of fastqs without extensions
    read1=${read1Fastq%%.*}
    read2=${read2Fastq%%.*}

    #make directory for trimmed fastqs
    mkdir trimmed/

    #trim adapters
    /share/apps/cutadapt-distros/cutadapt-1.9.1/bin/cutadapt \
    -a "$read1Adapter" \
    -A "$read2Adapter" \
    -m 35 \
    -o trimmed/"$read1Fastq" \
    -p trimmed/"$read2Fastq" \
    "$read1Fastq" \
    "$read2Fastq"

    #fastqc
    /share/apps/fastqc-distros/fastqc_v0.11.5/fastqc -d /state/partition1/tmpdir --threads 12 --extract trimmed/"$read1Fastq" 
    /share/apps/fastqc-distros/fastqc_v0.11.5/fastqc -d /state/partition1/tmpdir --threads 12 --extract trimmed/"$read2Fastq"

    #check FASTQC output
    if [ $(countQCFlagFails trimmed/"$read1"_fastqc/summary.txt) -gt 0 ] || [ $(countQCFlagFails trimmed/"$read2"_fastqc/summary.txt) -gt 0 ]; then
        rawSequenceQuality=FAIL
    fi

    #print fastq paths <path2r1> <path2r2>
    echo -e "$(find "$PWD"/trimmed -name "$read1Fastq")\t$(find "$PWD"/trimmed -name "$read1Fastq")" >> ../FASTQs.list

done

#Print QC metrics
echo -e "RawSequenceQuality" > "$seqId"_"$sampleId"_QC.txt
echo -e "$rawSequenceQuality" >> "$seqId"_"$sampleId"_QC.txt

#check if all samples are written
if [ $(find .. -maxdepth 1 -mindepth 1 -type d | wc -l | sed 's/^[[:space:]]*//g') -eq $(sort ../FASTQs.list | uniq | wc -l | sed 's/^[[:space:]]*//g') ]; then
    echo -e "seqId=$seqId\npanel=$panel" > ../variables
    
    #soft link sample sheet
    ln -s /data/archive/fastq/"$seqId"/SampleSheet.csv ..
    #launch second pipeline script
    cp 2_CRUK.sh .. && bash 2_CRUK.sh >2_CRUK.out 2>2_CRUK.err
fi