function abf2NWBcomp(varargin)

%{ 
Converts all abf files in one folder into one nwb file with the same name
First input argument is the path to the folder containing folders with abf
files. Second input argument is the path at which nwb files are saved. If
only one input argument is used the location is used for both input and
output. The NWB schema is 2.4.0
%}
dbstop if error  
check = 0;
count = 1;
for v = 1:nargin
    if check == 0 && (isa(varargin{v}, 'char') || isa(varargin{v}, 'string'))
        mainfolder = varargin{v};
        if endsWith(mainfolder, '\') || endsWith(mainfolder, '/')
          mainfolder(length(mainfolder)) = [];
        end
        cellList = getCellNames(mainfolder);
        check = 1;
    elseif (isa(varargin{v}, 'char') || isa(varargin{v}, 'string'))
        outputfolder = varargin{v};
        if endsWith(outputfolder, '\') || endsWith(outputfolder, '/')
          outputfolder(length(outputfolder)) = [];
        end
        disp('No overwrite mode')
        for k = 1 : length(cellList)
          baseFileName = [cellList(k).name, '.nwb'];
          fullFileName = fullfile(outputfolder, baseFileName);
          fprintf(1, 'Now deleting %s\n', fullFileName);
          delete(fullFileName);
        end
    end
end
sessionTag = 'M00';  

%% Reading Western's manual entry data table
if isfile([mainfolder, '\manual_entry_data.csv'])
  T = readtable([mainfolder, '\manual_entry_data.csv']);
else
    error('No manual entry data detected')
end
%% Cell loop
for n = 1:length(cellList)
    %% Initalizing and general descriptors
    CS = struct();
    CS.mainfolder=mainfolder;
    [nwb, CS] = initNWB(cellList, n, CS);
    nwb.general_institution = 'University of Western Ontario'; 
    nwb.general_lab = 'Martinez-Trujillo/Inoue';  
    nwb.general_devices.set('Amplifier', ...
          types.core.Device('description', 'Axon MultiClamp 700B', ...
                                     'manufacturer', 'Molecular Devices'));                          
    nwb.general_devices.set('Digitizer', ...
         types.core.Device('description', 'Axon Digidata 1440 or 1550', ...
                                     'manufacturer', 'Molecular Devices'));                               
    nwb.general_slices = ...
          'ACSF slightly different to NeuroNex better description follows';                   
    [nwb, CS] = addSubAna2NWB(nwb, T, CS);   
    if CS.noManuTag==0 && cell2mat(T.SlicingSolution(CS.CompDataIdx))=="Choline"
       nwb.general_surgery = 'Bioopsies; Anaesthesia; choline-based slicing solution';     
    end 
    %% loading the abf files
    fileList = dir([mainfolder,'/',cellList(n,1).name,'/*.abf']);
    paths = fullfile({fileList.folder}, {fileList.name});    
    %% files within cell loop 
    for f = 1:length(fileList)
      [data,sample_int,aquiPara] = abfload(paths{1,f},'sweeps','a', ...
                                                           'channels','a');
    %% Getting start date from 1st recording of cell and checking for new session start  
     CS = getMCCparameter(CS, fileList, f);                                % load and assign parameters from settingsMCC
     if f==1             
       CS.cStart = datetime(aquiPara.uFileStartDate, ...
                    'ConvertFrom', 'yyyymmdd' ,'TimeZone', 'local')+ ...
                            seconds(aquiPara.uFileStartTimeMS/1000);                       
       [nwb, CS] = saveCellStart(nwb, CS, sessionTag);   
       [nwb,ic_elec, ICelecLink] = addRunElec2NWB(nwb, CS, T);                      % Getting run and electrode associated properties 
     end     
    %% Data: recreating the stimulus waveform
     stimulus_name = aquiPara.protocolName(...
            find(aquiPara.protocolName=='\',1, 'last')+1:end);
        
      if isempty(aquiPara.DACEpoch) && ~contains(aquiPara.protocolName, ['noise']) ...
                && ~contains(aquiPara.protocolName, ['chirp']) ...
           
        nwb.acquisition.set(['Sweep_', num2str(CS.swpCt-1)], types.core.IZeroClampSeries( ...
              'bridge_balance', CS.brigBal, ... % Unit: Ohm
              'capacitance_compensation', CS.capComp, ... % Unit: Farad
              'data', data, ...
              'data_unit', 'mV', ...
              'electrode', ICelecLink, ...
              'stimulus_description', stimulus_name,...
              'starting_time',aquiPara.uFileStartTimeMS\1000,...
              'starting_time_rate', 1000000/sample_int,...
              'sweep_number', CS.swpCt ...
            ));                           
              
        sweep_ch2 = types.untyped.ObjectView(['/acquisition/', 'Sweep_', num2str(CS.swpCt-1)]);
        CS.sweep_series_objects_ch2 = [CS.sweep_series_objects_ch2, sweep_ch2];
        [CS.StimOff(CS.swpCt,1), CS.SweepAmp(CS.swpCt,1), CS.StimOn(CS.swpCt,1), ...
             CS.BinaryLP(CS.swpCt,1), CS.BinarySP(CS.swpCt,1)] = deal(NaN);
        CS.swpCt =  CS.swpCt + 1;   
              
      elseif ~contains(aquiPara.protocolName, 'noise')  
            stimInd = find(aquiPara.DACEpoch.fEpochLevelInc~=0);   
            stimDuration = aquiPara.DACEpoch.lEpochInitDuration(stimInd);
            SwpsPerFile = size(data,3);
            if  stimDuration*(sample_int/1000) == 1000 
             stimDescrp = 'Long Pulse';  
             CS.BinaryLP(CS.swpCt:SwpsPerFile+CS.swpCt-1,1)  = 1;
             CS.BinarySP(CS.swpCt:SwpsPerFile+CS.swpCt-1,1)  = 0;
            elseif stimDuration*(sample_int/1000) == 3
             stimDescrp = 'Short Pulse';
             CS.BinaryLP(CS.swpCt:SwpsPerFile+CS.swpCt-1,1)  = 0;
             CS.BinarySP(CS.swpCt:SwpsPerFile+CS.swpCt-1,1)  = 1;
            else
             disp(['Unknown stimulus type with duration of '...
                        , num2str(stimDuration*(sample_int/1000)), 'ms'])
            end
            
           CS = GetABFstims(aquiPara, CS, SwpsPerFile, sample_int);          
                                         
           for s = 1:SwpsPerFile
                
                CS.SwpAmp(CS.swpCt,1)  =  aquiPara.DACEpoch.fEpochInitLevel(stimInd)+ ...
                          aquiPara.DACEpoch.fEpochLevelInc(stimInd)*(s-1);
                
                if length(aquiPara.DACEpoch.fEpochInitLevel) > 2  
                CS.testAmp(CS.swpCt,1) = aquiPara.DACEpoch.fEpochInitLevel(stimInd-2);
                end
                
                if  aquiPara.DACEpoch.fEpochLevelInc(stimInd) < 1          % current is in nanoAmp
                    CS.SwpAmp(CS.swpCt,1)= CS.SwpAmp(CS.swpCt,1)*1000;
                    CS.testAmp(CS.swpCt,1) = CS.testAmp(CS.swpCt,1)*1000;
                end
                
                if length(aquiPara.DACEpoch.fEpochInitLevel) > 2 
                   stimData = [zeros(1,aquiPara.DACEpoch.lEpochInitDuration(1)+ ...
                    aquiPara.DACEpoch.firstHolding ), ...
                   ones(1,aquiPara.DACEpoch.lEpochInitDuration(2))*CS.testAmp(CS.swpCt,1) ,...
                   zeros(1,aquiPara.DACEpoch.lEpochInitDuration(3)), ...
                     ones(1,aquiPara.DACEpoch.lEpochInitDuration(4)).*CS.SwpAmp(CS.swpCt,1),...
                       zeros(1,length(data)- CS.StimOff(CS.swpCt,1))]';
                else
                    disp(['No test pulse in file', paths{1,f}])
                 stimData = [zeros(1,aquiPara.DACEpoch.lEpochInitDuration(1)+ ...
                    aquiPara.DACEpoch.firstHolding ), ...
                   ones(1,aquiPara.DACEpoch.lEpochInitDuration(2))*CS.SwpAmp(CS.swpCt,1) ,...
                   zeros(1,length(data)- CS.StimOff(CS.swpCt,1))]';

                end
                
				ccss = types.core.CurrentClampStimulusSeries( ...
                        'electrode', ICelecLink, ...
                        'gain', NaN, ...
                        'stimulus_description', stimDescrp, ...
                        'data_unit', 'pA', ...
                        'data', types.untyped.DataPipe('data', ...
                          stimData,'chunkSize', [1000 1],'axis', 1, ...
                          'dataType', 'double', 'hasShuffle', 1), ...
                        'sweep_number', CS.swpCt,...
                        'starting_time', aquiPara.uFileStartTimeMS/1000,...
                        'starting_time_rate', 1000000/sample_int...
                        );
                    
                nwb.stimulus_presentation.set(['Sweep_', num2str(CS.swpCt-1)], ccss);    

                nwb.acquisition.set(['Sweep_', num2str(CS.swpCt-1)], ...
                    types.core.CurrentClampSeries( ...
                        'bias_current', CS.holdI*1e12, ... % Unit: pAmp
                        'bridge_balance', CS.brigBal/(1e6), ... % Unit: MOhm
                        'capacitance_compensation', CS.capComp*1e12, ... % Unit: pFarad
                        'data', types.untyped.DataPipe('data',...
                          data(:,1,s),'chunkSize', [1000 1],'axis', 1, ...
                           'dataType', 'double', 'hasShuffle', 1), ...
                        'data_unit', aquiPara.recChUnits{:}, ...
                        'electrode', ICelecLink, ...
                        'stimulus_description', stimDescrp, ...   
                        'sweep_number', CS.swpCt,...
                        'starting_time', aquiPara.uFileStartTimeMS/1000,...
                        'starting_time_rate', 1000000/sample_int...
                          ));
                    
                sweep_ch2 = types.untyped.ObjectView(['/acquisition/', 'Sweep_', num2str(CS.swpCt-1)]);
                sweep_ch1 = types.untyped.ObjectView(['/stimulus/presentation/', 'Sweep_', num2str(CS.swpCt-1)]);
                CS.sweep_series_objects_ch1 = [CS.sweep_series_objects_ch1, sweep_ch1]; 
                CS.sweep_series_objects_ch2 = [CS.sweep_series_objects_ch2, sweep_ch2];
                CS.swpCt =  CS.swpCt + 1;   
          end
       end
        count = count +1;
    end        
%% Intracellular Recordings Table  
   nwb = makeICtab(nwb, CS, ic_elec);
   filename = fullfile([outputfolder, '/' ,nwb.identifier '.nwb']);
   nwbExport(nwb, filename);
end
   
end    
