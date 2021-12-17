function [nwb, CS] = initNWB(cellList, n, CS)
    cellID = cellList(n).name;
    cellID(cellID=='-') = '_';
    disp(cellID) 
    %% Initializing variables for Sweep table construction 
    CS.noManuTag = 0; CS.swpCt = 1; CS.cellID = cellID;
    CS.filterFreq = 'NA'; CS.brigBal = 0; CS.holdI = 0; CS.capComp = 0;
    CS.PipOffset= []; CS.electOffset = NaN; % both??
    CS.sweep_series_objects_ch1 = []; CS.sweep_series_objects_ch2 = [];
    CS.SweepAmp = []; CS.StimOn = []; CS.StimOff = [];CS.StimDuration = [];

    CS.BinaryLP = []; CS.BinarySP = [];
    CS.corticalArea = 'NA'; CS.initAccessResistance = NaN;
    CS.ic_elec_name = 'unknown'; 
          
    nwb = NwbFile( ...
        'identifier', cellID, ...
        'general_experiment_description', 'Characterizing intrinsic biophysical properties of cortical NHP neurons.', ...
        'session_description', 'A long long experimental day' ...
    );
    nwb.general_source_script = 'custom matlab script using MATNWB';
    nwb.general_source_script_file_name = mfilename;
    nwb.general_subject = types.core.Subject( ...
      'description', 'NA', 'age', 'NA', ...
      'sex', 'NA', 'species', 'NA');
    
end