try:
    import pyCEDFS
except:
    print(" Conversion in python requires pyCEDFS please install using 'pip install git+https://github.com/smestern/pyCEDFS.git'")
    raise
import shutil
import os
import argparse
import logging
log = logging.getLogger(__name__)
import pynwb
import pynput
import time
import numpy as np

def main():
    parser = argparse.ArgumentParser()

    common_group = parser.add_argument_group(title="Common", description="Options which are applicable to both ABF and DAT files")
    abf_group = parser.add_argument_group(title="ABF", description="Options which are applicable to ABF")
    dat_group = parser.add_argument_group(title="DAT", description="Options which are applicable to DAT")

    feature_parser = common_group.add_mutually_exclusive_group(required=False)
    feature_parser.add_argument('--compression', dest='compression', action='store_true', help="Enable compression for HDF5 datasets (default).")
    feature_parser.add_argument('--no-compression', dest='compression', action='store_false', help="Disable compression for HDF5 datasets.")
    parser.set_defaults(compression=True)

    common_group.add_argument("--overwrite", action="store_true", default=False,
                               help="Overwrite the output NWB file")
    common_group.add_argument("--outputMetadata", action="store_true", default=False,
                               help="Helper for debugging which outputs HTML/TXT files with the metadata contents of the files.")
    common_group.add_argument("--log", type=str, help="Log level for debugging, defaults to the root logger's value.")
    common_group.add_argument("filesOrFolders", nargs="+",
                               help="List of ABF files/folders to convert.")
    common_group.add_argument("--additionalMetadata", default=None,
                              help="Pointed towards additonal JSON file which will be added to each NWB")
    common_group.add_argument("--amplifierSettings", default=None,
                              help="Pointed towards additonal JSON file which will be added to each NWB")

    abf_group.add_argument("--protocolDir", type=str,
                            help=("Disc location where custom waveforms in ATF format are stored."))
    abf_group.add_argument("--fileType", type=str, default=None, choices=[".abf"],
                            help=("Type of the files to convert (only required if passing folders)."))
    abf_group.add_argument("--outputFeedbackChannel", action="store_true", default=False,
                        help="Output ADC data to the NWB file which stems from stimulus feedback channels.")
    abf_group.add_argument("--realDataChannel", type=str, action="append",
                        help=f"Define additional channels which hold non-feedback channel data.")

    dat_group.add_argument("--multipleGroupsPerFile", action="store_true", default=False,
                           help="Write all Groups from a DAT file into a single NWB file. By default we create one NWB file per Group.")

    args = parser.parse_args()

    if args.log:
        numeric_level = getattr(logging, args.log.upper(), None)

        if not isinstance(numeric_level, int):
            raise ValueError(f"Invalid log level: {args.log}")

        logger = logging.getLogger()
        logger.setLevel(numeric_level)


    
    root_path = args.filesOrFolders
    if args.additionalMetadata is not None:
        if os.path.isfile(args.additionalMetadata):
            meta = args.additionalMetadata
            bmeta = True
        else:
            bmeta = False
    else:
        bmeta = False

    for path in root_path:
        for r, celldir, f in os.walk(path):
              
              for c in celldir: ##Walks through each folder (cell folder) in the root folder

                  c = os.path.join(r, c) ##loads the subdirectory path
                  ls = os.listdir(c) ##Lists the files in the subdir
                  abf_pres = np.any(['.cfs' in x for x in ls]) #Looks for the presence of at least one abf file in the folder (does not check subfolders)
                  if abf_pres:
                       if bmeta == True: ##If the user provided an additonal json file, we copy that into the subfolder
                            shutil.copy(meta,c) 
                            
                       print(f"Converting {c}")
                       nwb = pyCEDFS.CFSConverter(c, outFile=c+'.nwb')
                       if bmeta== True:
                            os.remove(os.path.join(c,os.path.basename(meta)))

if __name__ == "__main__":
    main()