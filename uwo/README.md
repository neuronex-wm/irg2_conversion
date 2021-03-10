# irg2_conversion
 conversion scripts for IRG2 labs from X - > NWB

## UWO IRG2 Lab conversion

This sub directory consists of scripts utilized to convert data from IRG2 group @ uwo to NWB. Contained here are three scripts adapted heavily from the allen institutes IPFX package.
as such these scripts are subject to the same  liscence as the IPFX repo.

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
