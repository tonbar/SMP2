# CRUK Analysis with the SMP2 v2 app
# 1_CRUK.sh script
## Requirements
  * Requires variables files generated by MakeVariablesFiles.jar (https://github.com/mcgml/MakeVariableFiles).
  * Requires untrimmed fastqs.
  * Requires a correctly set up sample sheet.
  * The script requires the following directory structure:

 /data
 
 └── results
 
     └── seqId
	 
         ├── panel
		 
         │   ├── sample1
		 
         │   ├── sample2
		 
         │   └── sample3


## Pre-requisites
### Setting up the sample sheet to be compatible with the workflow
The SampleSheet.csv should be set up according to instructions supplied by Illumina to facilitate correct sequencing and demultiplexing 
of multiplexed data (https://support.illumina.com/downloads/miseq_sample_sheet_quick_reference_guide_15028392.html). In addition, 
variables for the analysis pipeline are required to be entered in the Description field of the SampleSheet.csv. These should be as ;
separated key value pairs. The variables are pipelineName, pipelineVersion, panel, negative and pairs.

e.g. pipelineName=CRUK;pipelineVersion=1;panel=SMP2v2;negative=negativeControl;pairs=1.

pipelineName is the name of the pipeline, pipelineVersion is the version of the pipeline currently in use, panel is the name and version of 
the panel currently in use. negative is the name of the negative control sample, and pairs should be set to 1 where creation of a manual 
pairs file is created, and to 0 where the samples are paired in the usual way (see below for details of cases where a manual pairs file is 
required and how to create one).


### Panel variables file creation and location
The panel variables file should be placed in the pipeline location on the cluster nested inside the directories 
/$pipelineName/$pipelineName-$pipelineVersion/$panel/ with the file named $pipelineName-$pipelineVersion_$panel.variables.
This file should contain the adapters to be trimmed from the data in the format:

read1Adapter=XXXXXXX

read2Adapter=XXXXXXX



## Introduction
This script trims the adapter sequences from the fastq files using cutadapt (http://cutadapt.readthedocs.io/en/stable/guide.html), 
and runs fastqc. It also creates a symlink to the SampleSheet.csv within the panel directory (required for script 2_CRUK.sh).
Trimmed fastqs are output to a directory named trimmed/. The results of selected fastqc tests are parsed and 
whether the sample has passed or failed is printed out to a QC file.


Script 1_CRUK.sh runs once for each sample on the sequencing run.


Once all samples have had adapters trimmed and fastqc run, script 2 can be automatically launched. If this is not required, line 99
can be removed or commented out.

# 2_CRUK.sh script
## Introduction
This script takes fastq files and runs the SMP2 app in the basespace environment for each of the tumour sample blood sample pairs. 


A CentOS or Ubuntu operating system is required with the Illumina BaseSpace Command Line Interface installed and 
configured to access the correct BaseSpace location and username. For further instructions see 
https://help.basespace.illumina.com/articles/descriptive/basespace-cli/.


Script 2_CRUK.sh runs once per sequencing run.


### Required input files
  * The Illumina SampleSheet.csv with the desired project identifier for BaseSpace in the Experiment Name field.

  * Fastq pairs (read 1 and read 2) for each of the samples (pre-trimmed).

  * An optional text file called "not_bs.txt" containing the names of any samples on the Illumina SampleSheet.csv for which
analysis in BaseSpace with the SMP2 app is not required. This should be placed in the same location (directory) as the script.

  * An optional text file containing tumour normal pairs in the format <tumour_sample_id> <tab> <blood_sample_id> with each 
pair on a new line. This is required if the arrangement of samples in the Illumina SampleSheet.csv does not match the expected
order, which is tumour sample then normal sample for each patient in order. An example of this order is: S1 tumour sample for person 
1, S2 blood sample for person 1, S3 tumour sample for person 2, S4 blood sample for person 2, etc. This file can be located anywhere 
on the same computer as the script. The name of the full path to the file, the file name file and extension must be supplied as the 
third command line argument e.g. /path/to/file/pairs.txt.


### Caveats
The script requires project names to be unique. The project name is entered in the Experiment Name field of the Illumina SampleSheet.csv. 

Sample identifiers must be unique within a given project. Sample identifiers are entered in the Sample_ID fields of the Illumina 
SampleSheet.csv.

If using a python virtual environment, the full paths must be entered into lines 10 and 11 of the script. If a virtual environment is not
required these lines should be commented out or removed.



## Instructions for use
### Prerequisites
The Illumina CLI must be correctly set up to point to the required BaseSpace location. A config file with a different name to the default 
can be used by changing the name of the $CONFIG variable in the script.

The SMP2 app must have been imported. Instructions to import apps are available on the Illumina website.

### Changes to the script required for initial set up
  * Check that the fastqs are located in the location in the $FASTQFOLDER variable and check that the $CONFIG variable is set to the name
    of the correct config file for use of the SMP2 v2 app.

  * Ensure that the $APPID variable is set to the correct application id for the imported version of the SMP2 v2 app currently in use.


### Instructions for manually launching the script
If automated launch of the script is disabled in the 1_CRUK.sh file, the script 2_CRUK.sh can be manually launched according to the
following instructions.

  * Pass the full path to the SampleSheet.csv file for the run to be analysed as the first command line argument. The assumption within the
  script by default is that the trimmed fastqs will be located for each sample within a subdirectory called trimmed/ nested within a sample 
  directory relative to the SampleSheet.csv.
  
  If this is not the location of the fastq files, the variable $FASTQFOLDER within the script should be changed to the
  location of the fastq files.

  * Pass the sample name of the negative control sample as the second command line argument.

  * If a manually created file containing the tumour blood pairs is required, place this file on the same computer as the script and
  files to be analysed. Pass the full path to the file, the name of this file and the extension as the third command line argument.
  e.g. /path/to/pairs/file/pairs.txt. 
  
  * If the automatic pair generation option is used (default), the automatically generated SamplePairs.txt file will be created in the
  same location as the SampleSheet.csv.

  * If there are samples which were run, and so are on the sample sheet, that are not required to be analysed using the SMP2 BaseSpace application, 
the names of these samples should be placed in a file called "not_bs.txt" with each name on a new line. The file "not_bs.txt"
should be placed in the same directory as the script.

#### Full example
bash 2_CRUK.sh /path/to/samplesheet/ NEGATIVECONTROL /path/to/pairs/file/pairs.txt

Note that the third argument is optional.

## Creating the tumour blood pairs file
If the sample sheet is not set up with the pattern tumour sample followed by paired blood sample for each patient sequentially, it is necessary
to manually specify the tumour-normal pairs.
Create a text file according to the following pattern with the sample names:

tumour1 tab blood1 newline


tumour2 tab blood2 newline


tumour3 tab blood3 newline


...and so on for each pair of samples belonging to each individual.

This text file can have any name. It can be placed anywhere on the same computer as the script and the full path to the file, the name of the 
file and the extension should be passed as the third command line argument.


Once script 2 has completed, script 3 can be automatically launched. By default it is launched with a delay of 30 minutes. To adjust the delay
time or remove the delay make changes to line 232. If automated launch of script 3 is not required, line 232 can be removed or commented out.


# 3_CRUK.sh script
## Requirements
  * Requires path to Node.js to be installed and the path to the bin directory of the installation to be entered in the NODE variable. Do not 
  include the trailing / in the path.


## Introduction
This script parses the path to Node.js to obtain the path to node_modules and launches the baseSpace.js Node.js script. 

Script 3_CRUK.sh runs once per sequencing run.

### Instructions for manually launching the script
If automated launch of the script 3_CRUK.sh is disabled, the script can be manually launched by typing bash 3_CRUK.sh at the command line. No
command line arguments are required to be supplied, but the NODE variable should be adjusted within the script to point to the bin directory
of the node installation. If the script is not resuming from the previous step of the pipeline, it will be necessary to create config.json and
runConfig.json files according to the instructions below. A file called pairsFn.txt will also need to be created containing the name of the
sample pairs file. This is usually SamplePairs.txt, but could be something else (user's choice) if the pairs file was manually created.


# baseSpace.js script
## Requirements
  * Requires Node.js to be installed. 
  * Requires the Node modules path, request and fs.
  * Requires a config.json file to be created containing the apiServer, apiVersion in use, and accessToken in the json format. 
  An example file is available in this repository (config.example.json).
  * Requires a runConfig file containing projectId, numPairs, and name of the negativeControl in the json format. This file should 
  be automatically generated by script 2_CRUK.sh. In case this step has been missed out for any reason, a runConfig.json file must be 
  manually generated for the baseSpace.js script to run. An example file is available in this repository (runConfig.example.json).


## Introduction
This script polls the status of the application for each of the tumour sample pairs. Once the application has completed for all of the 
pairs, the bam, bai and Excel report are downloaded to a sub-directory of the script called results for each of the pairs.

baseSpace.js runs once per sequencing run.

### Instructions for manually launching the script
Ensure that the files config.json and runConfig.json are set up with the correct variables in the same directory as the script baseSpace.js.
Create a directory in the same directory as the script and call it 'results'.
type /path/to/node/node baseSpace.js /path/to/node_modules/ at the command line to launch the script.
