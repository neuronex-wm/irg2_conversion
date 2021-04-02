#!/bin/env python
import shutil
import os
import argparse
import logging
log = logging.getLogger(__name__)
import pyabf
from ipfx.x_to_nwb.ABFConverter import ABFConverter
from ipfx.x_to_nwb.DatConverter import DatConverter
import h5py
import numpy as np
import pandas as pd
import pynwb
import pynput
import time
import pyperclip

def remove_sweeps(nwb_file, qcsweeps):
  qcsweeps = np.asarray(qcsweeps) #If given a list convert to array
  file_path = nwb_file
  print(f"QC'ing {file_path}")
  with h5py.File(file_path,  "r") as f:
            item = f['acquisition']
            sweeps = len(item.keys())
  qc_names = qcsweeps
  print(qc_names)
  with h5py.File(file_path,  "a") as f:
        item = f['acquisition'] ##Delete the response recording
        print("removing acquistion")
        for p in qc_names:
              try:
                  del item[p] #For whatever reason these deletes try to do it twice ignore the second error message
                  print(f'deleted {p}', end = "\r")
              except:
                  print(f'{p} delete fail')
        item = f['stimulus']['presentation'] #next delete the stimset
        print("removing stimset")
        for p in qc_names:
              try:
                  del item[p]
                  print(f'deleted {p}', end = "\r")
              except:
                  print(f'{p} delete fail')
        item = f['general']['intracellular_ephys']['sweep_table'] #next delete the references in the sweep table, or else the nwbs may break analysis
        ## Since IPFX may go looking for sweeps that are absent
        for key, value in item.items():
              array = value[()]
              ind = np.arange(0, len(array))
              sweep_idx_qc = np.array([x.split('_')[-1] for x in qcsweeps]).astype(np.int64)
              ## for whatever reason table has double
              sweep_idx_qc = np.hstack((sweep_idx_qc, sweep_idx_qc + sweeps))
              bool_mask = np.in1d(ind,sweep_idx_qc, invert=True)
              new_data = array[bool_mask]
              try:
                del item[key]
                item[key] = new_data
                print(f'deleted and rewrote {key}')
              except: 
                print(f'{key} delete fail')

def compute_failing_sweeps(file_path, passing):
    with h5py.File(file_path,  "r") as f:
            item = f['acquisition']
            sweeps = list(item.keys())
            item = f['general']['intracellular_ephys']['sweep_table']
            for key, value in item.items():
              array = value[()]
              ind = np.arange(0, len(array))
              
              #bool_mask = np.in1d(ind,qcsweeps, invert=True)
              #new_data = array[bool_mask]

    if len(passing) < 1:
        failing_sweeps = sweeps
    else:
        inter, ind1, _ = np.intersect1d(sweeps, passing, return_indices=True)
        failing_sweeps = np.delete(sweeps, ind1)


    
    return failing_sweeps
    
def main():
    NHPPath = "C:\\Users\\SMest\\Documents\\NHP_MARM\\210204_Marm_NWB\\"
    sweep_qc = pd.read_csv("C:\\Users\\SMest\\Documents\\NHP_MARM\\sweep_labels_selection.csv", index_col=0)
    sweep_qc = sweep_qc.drop('ID_new', axis=1)
    protocol = []
    cell_list = sweep_qc.index.values
    for r, celldir, f in os.walk(NHPPath):
              for file in f:
                  if '.nwb' in file:
                   #try:
                       cell_name = file.split('.')[0]
                       bool_sweep = np.logical_and(sweep_qc.loc[cell_name].values!='0', sweep_qc.loc[cell_name].values!=0)
                       cell_qc = sweep_qc.loc[cell_name][bool_sweep].to_numpy()
                       file_path = os.path.join(r,file)
                       index_fail = compute_failing_sweeps(file_path, cell_qc)
                       print(f"QC {cell_name}")
                       remove_sweeps(file_path, index_fail)
                   #except:
                    # print('fail')


if __name__ == "__main__":
    main()
