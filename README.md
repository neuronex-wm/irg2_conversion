# Conversion of raw intracellular recording to NWB format for IRG2


## Overview
This repository contains code in MATLAB and python for converting intracellular recording in various formats (abf, cfs, dat) obtained in various laboratories. 


## Additonal Requirements
The MATLAB code has been developed in MATLAB2020b and requires the MATNWB repository in form of release v2.4, you find it [here](https://github.com/NeurodataWithoutBorders/matnwb)

## Organization
There is a function converting files for each lab (with their different documentation practices, hardward and so on). So far there is code for:

**1) under \uwo\... MATLAB and python code to convert data obtained at the University of Western Ontario (Martinez and Inoue group): which is for data obtained in Clampex. Optionally, the conversion uses two additional sources of metadata: 
***1) from the python script mcc_get_settings.py developed from the Allen Brain Insitute. You can find it [here (https://github.com/AllenInstitute/ipfx/tree/master/ipfx/bin). 
***2) a csv file containing data recorded manually for initial access resistance (read from the membrane test feature of Clampex) and temperature.

**2)  \goettingen\.. contains MATLAB code to convert data obtained from the Neef and Staiger lab: this folder contains code to convert from both dat and cfs format. 

**3)  \pittsburgh\.. contains MATLAB and python code to convert data obtained from the Lewis/Gonzalez-Burgos group: this folder contains code to convert from the cfs format

**4)  \MATLAB_backbone\ contains several functions that are used across different conversion pipelines are hence not part of any of the previous folders  
