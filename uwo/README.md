# irg2_conversion
 conversion scripts for IRG2 labs from X - > NWB

## UWO IRG2 Lab conversion

This sub directory consists of scripts utilized to convert data from IRG2 group @ uwo to NWB. Contained here are three scripts adapted heavily from the allen institutes IPFX package.
as such these scripts are subject to the same license as the IPFX repo.

### TODO 
- Documentation
- Update to use new X_to_nwb package

### Usage
To fully convert is a multistep process:
1. run_bulk_to_nwb_conversion.py
2. run_add_metadata.py
-- Matlab QC Code --
3. run_sweep_qc.py

#### Intial conversion
for a more indepth tutorial see here: https://www.smestern.com/abf2nwb_pipeline.html

For our experiments, each cell had several recordings (ABF files) associated with it. For our purposes, we needed each NWB file to represent a single cell. So, we sought to convert a collection of ABF files into a single NWB file. The script assumes that all ABF files found in a single folder represent a single cell (and subsequently builds an NWB file based on that folder). Therefore it is handy to organize your abf files like so:
```
|- Main folder
|-|----Cell_1
|-|----|---Cell_1_file1.abf
|-|----|---Cell_1_file2.abf
|-|----Cell_2
|-|----|---Cell_2_file1.abf
|-|----|---Cell_2_file2.abf
```
With the cells organized like this you can simply run

```
python run_bulk_to_nwb_conversion.py \Main Folder\
```
The script has a number of additional settings. In short you can also specifiy a metadata file with `--additionalMetadata`.
This will add the same metadata to each NWB and does not support specifying metadata for individual NWB's. An example usage might be anonymization the data.

#### Add specific metadata
The next step is to utilize `run_add_metadata.py`. This script adds additional metadata not yet captured by any other script to the NWB.
As an input the script should be directed towards the freshly converted NWBS from above. 
In addition the argument `--metadata` should be directed towards a csv (//TODO JSON) that contains metadata needed for each NWB. The first column of the CSV should contain the file names (without extension) of the NWB's that the data will be added to. The remaining columns should value of the respective key-value pairs to be added to the NWB. The column titles will be used as the key for the data added to the NWB. 
An example CSV may look like:

```
| IDS | TEMP | MEMBRANE RESIST | INTIAL ACCESS |
------------------------------------------------
| Cell1 | 30 | 300 GIGA OHM    | 10            |
------------------------------------------------
| Cell2 | 29 | 310 GIGA OHM    | 13            |
------------------------------------------------
```

Which will be added to the NWB as such:
```
Cell1.nwb
-->General
    |--> TEMP => 30
    |--> MEMBRANE RESIST => 300 
    |--> INTIAL ACCESS => 10

Cell2.nwb
-->General
    |--> TEMP => 29
    |--> MEMBRANE RESIST => 310
    |--> INTIAL ACCESS => 13
```
* Note the current implementation is quite brute force, and goes against the NWB conventions. This need to be eventually replaced*


#### remove sweeps that fail QC
TODO