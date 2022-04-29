% modified for nwb 2.4.0
% ongoing issues Dec. 2021:
% - Intracellulare recordings table length check in abf2?
% - Temperature
% - Correct Rs
% - StimData length if check?
% - Why is stimduration better than protocol names?
% - Eliminate stimduration and use StimDuration
% - Check if gain works correctly
% - Check Data unit dependency
% - Protocol vector cell or normal array?
% - Current amp relative to holding!
% - Species data
% - TuneCfast causes problems due to DAC_0 at line 117

clear

mainfolder = uigetdir('','Select main folder'); % select individual folders at start
outputfolder = uigetdir(mainfolder,'Select output folder');  

%fileList = dir(fullfile(mainfolder,'**\*.dat*')); % With subfolders
fileList = dir(fullfile(mainfolder,'\*.dat*')); % Without subfolders
CellCounter = 0;
deleteList = dir(fullfile(outputfolder,'*Goettingen*.nwb'));

global sname % globals as a way to see if dialog was already run once - if it errors out
global snumber
[snumber, name, devID, sname, sage, ssex, sspecies] = miscdesc(); % added this for description of animal and ID generation

for k = 1 : length(deleteList) % loop deletes old converted files in the folder 
  baseFileName = [deleteList(k).name];
  fullFileName = fullfile(outputfolder, baseFileName);
  fprintf(1, 'Now deleting %s\n', fullFileName);
  delete(fullFileName);
end

for f = 1:length(fileList)
    SweepAmp = [];StimOff = []; StimOn = []; BinaryLP = []; BinarySP = [];
    datFile = HEKA_Importer(fullfile(mainfolder, fileList(f).name)); % changed to work with uigetdir
    sessionStart = datetime(datFile.trees.dataTree{1, 1}.RoStartTimeMATLAB);
    posCount = 1;
    for p = 1:size(datFile.trees.ampTree,1) % Gathers amp traces
      if ~isempty(datFile.trees.ampTree{p, 3})
          ampPos(posCount) = p;
          posCount = posCount+1;
      end
    end 
    if length(ampPos) > height(datFile.RecTable) % For doulbe amplifiers, it checks whether there are more ampstates than recordings, which amplies there are unused headstages  
       %ampPos = ampPos(1:2:length(ampPos)); % Headstage 1
       ampPos = ampPos(2:2:length(ampPos)); % Headstage 2
    end
    CellCounter = CellCounter + 1; % increseas cell counter for the next cell/for loop
    labels = regexp(fileList(f).name, '_', 'split'); % dissects file name but unused so far
    User = datFile.trees.dataTree{3, 3}.SeUsername; % Extracted from the first recording assuming that one user does all the recordings on one day  
    CellTag = num2str(CellCounter, '%02.f'); % writes internal cell tag & pads single digits with a zero
    
    MATFXID = ['M',snumber,'_',cellfun(@(a) a(1),strsplit(User)), '_A1_C', CellTag,'_']; % ID for MatFX naming convention - needs to be expanded on
    ID = [MATFXID,'Goettingen', '_', devID,'_Cell', CellTag]; % unique identifier would be helpful - maybe date from labels or ampstate?
    disp(['New cell found, ID: ', ID])     
    %% Initializing variables for Sweep table construction
    sweepCount = 0;
    sweep_series_objects_ch1 = []; sweep_series_objects_ch2 = [];        
    %% Initializing nwb file and adding first global descriptors
    nwb = NwbFile('session_description', 'A long experiment day', ... project description - should be automated for mice&nhps
        'identifier', ID, ... file name for nwb
        'session_start_time', sessionStart, ... recording date
        'general_experimenter', User,... 
        'general_lab', 'Staiger/Neef', ... maybe unnecessary
        'general_experiment_description', 'Characterizing intrinsic biophysical properties of cortical NHP neurons.', ...
        'general_institution', 'Institute for Neuroanatomy UMG / CIDBN University of Goettingen'...
        );
     
    disp('Manual entry data not found') % Species data
    %noManuTag = 1;
    nwb.general_subject = types.core.Subject( ...
        'description', sname, ...
        'age', sage, ...
        'sex', ssex, ...
        'species', sspecies ...
    );
    corticalArea = 'NA'; 

    
    device_name = [datFile.trees.ampTree{1, 1}.RoAmplifierName];  % Hardcoded amp name   
    nwb.general_devices.set(device_name, types.core.Device('description', ['Single or Double; Patchmaster version ' datFile.trees.ampTree{1, 1}.RoVersionName], ...
        'manufacturer', 'Heka'));
    device_link = types.untyped.SoftLink(['/general/devices/' device_name]); %amplifier device
    
    
    %ic_elec_name = 'Electrode 1';  
    ic_elec_name = 'Electrode 2';  
    temp_vec = []; % creates temperature vector
    dur = duration.empty(height(datFile.RecTable.TimeStamp),0); % creates empty duration vector
    for i = 1:height(datFile.RecTable.TimeStamp) 
      dur(i) = datFile.RecTable.TimeStamp{i,1}(...
         length(datFile.RecTable.TimeStamp{i,1})) - datFile.RecTable.TimeStamp{i,1}(1);   % calculates duration by looking at the number of time stamps for each recording and substracting the first from the last: Last time stamp in the list - first time stamp in the list
      temp_vec(i) = datFile.RecTable.Temperature(i)+2.5; % on average the center of the chamber is at least + 2 degrees warmer
    end
    Temperature = sum(temp_vec.*(dur/sum(dur,'omitnan')),'omitnan'); % Nansum is not recommmended anymore and part of a toolbox.
    %% Getting run and electrode associated properties  

    ic_elec = types.core.IntracellularElectrode( ...
        'device', device_link, ...
        'description', 'Properties of electrode and run associated to it',...
        'filtering', num2str(datFile.trees.ampTree{ampPos(1),3}.AmAmplifierState.sF2Bandwidth),... bandwidth of the amplifier filter 2 with reference to filter 1 fixed at 10 kHz; taken from the amptree of the first recording
        'initial_access_resistance', ...
                  num2str(datFile.RecTable.Rs_uncomp{1,1}{1, 1}(1)/1.0e+06) ,... THIS VALUE IS SOMEWHAT OFF - NEED TO TALK WITH SUPPORT, NOV 2021
        'location', corticalArea, ...
         'slice', ['Temperature ', num2str(Temperature)]...
   );

    nwb.general_intracellular_ephys.set(ic_elec_name, ic_elec);
    ic_elec_link = types.untyped.SoftLink([ ...
                         '/general/intracellular_ephys/' ic_elec_name]);   
    for e = 1:height(datFile.RecTable)      % number of rows in RecTable = number of recordings 
         for s = 1:datFile.RecTable.nSweeps(e) % goes through each sweep
             if ~contains(datFile.RecTable.Stimulus(e), 'sine') & ~contains(datFile.RecTable.Stimulus(e), 'Tune')  % used to ignore dynamic gain protocols & Tune protocol           
                
                 stimData = datFile.RecTable.stimWave{e,1}.DA_2(:,s); % stimulus data for each sweep %% ORIGINAL
                 
                 if length(stimData) < 9900
                   SweepAmp(sweepCount+1,1) = round(1000*mean(nonzeros(stimData)));  % for short recordings? But at 50 kHz this amounts to about 200 ms - only removes the depol at the beginning               
                 else
                   SweepAmp(sweepCount+1,1) = round(1000*mean(nonzeros(stimData(9900:end)))); %check if this works for non-relative holding 
                 end
                 if SweepAmp(sweepCount+1,1) <= 0 % defines stimulus on and off by differentiating and looking for f' peaks --> inflection points or rather impuls for square wave
                    [~, temp] = findpeaks(diff(stimData));
                    StimOff(sweepCount+1,1) = temp(length(temp));
                    [~, temp] = findpeaks(diff(-stimData));
                    StimOn(sweepCount+1,1) = temp(length(temp));
                 else % It is quite remarkable that this works for the RAMP and probably only because of the way HEKA encodes the Waveform
                    [~, temp] = findpeaks(diff(stimData)); % for positive stimuli, on & off points are flipped pointers
                    StimOn(sweepCount+1,1) = temp(length(temp));
                    [~, temp] = findpeaks(diff(-stimData));
                    StimOff(sweepCount+1,1) = temp(length(temp));
                 end

                stimDuration = StimOff(sweepCount+1,1)-StimOn(sweepCount+1,1); % length of stimulus at 50kHz sampling rate
                if  stimDuration/round(datFile.RecTable.SR(e)) == 1 % WHY IS THIS BETTER THAN IF from before?
                 stimDescrp = 'Long Pulse';  
                 BinaryLP(sweepCount+1,1)  = 1;
                 BinarySP(sweepCount+1,1)  = 0;
                elseif stimDuration/round(datFile.RecTable.SR(e)) == 0.003
                 stimDescrp = 'Short Pulse';
                 BinaryLP(sweepCount+1,1) = 0;
                 BinarySP(sweepCount+1,1)  = 1;
                else
                 disp(['Unknown stimulus type with duration of '...
                            , num2str(stimDuration/round(datFile.RecTable.SR(e))), 's'])
                 BinaryLP(sweepCount+1,1) = 0;
                 BinarySP(sweepCount+1,1)  = 0;                    
                end


                 ampState = datFile.trees.ampTree{ampPos(e), 3}.AmAmplifierState; % captures the amplifier state with all recording properties
                 t = datFile.RecTable.TimeStamp{e,1}(s); % time of recording start from first entry in timestamp list
                 startT = seconds(hours(t.Hour)+ minutes(t.Minute)+seconds(t.Second)); %converts date into separate duration vectors before wrting as sum of seconds              

                 ccs = types.core.CurrentClampStimulusSeries( ... %generates the stimulus in nwb; separate for each sweep
                        'electrode', ic_elec_link, ...
                        'gain', ampState.sCurrentGain*1e-12, ... gain is referenced to A for some reason in the amptree; this converts it back to pA/mV
                        'stimulus_description', datFile.RecTable.Stimulus(e), ... % protocol name
                        'data_unit', cell2mat(datFile.RecTable.stimUnit{2,1}(1)), ...% hard coded reference of second sweep! CHECK!!
                        'data', stimData, ...
                        'sweep_number', sweepCount,...
                        'starting_time', startT,...
                        'starting_time_rate', round(datFile.RecTable.SR(e))...
                        );

                 nwb.stimulus_presentation.set(['Sweep_', num2str(sweepCount)], ccs); % sets the stimulus with correct name     

                 nwb.acquisition.set(['Sweep_', num2str(sweepCount)], ... % generates the response to stimulus in nwb - currentclampseries; could be put in separate variable
                      types.core.CurrentClampSeries( ...
                        'bias_current', datFile.RecTable.Vhold{e,1}{1, 2}(s), ... % Unit: Amp
                        'bridge_balance', ampState.sRsValue , ... % Unit: Ohm; TO be decided whether this is the correct Rs value
                        'capacitance_compensation', ampState.sCFastAmp2+ampState.sCFastAmp1, ... % Unit: Farad
                        'data', datFile.RecTable.dataRaw{e,1}{1, 2}(:,s), ... % writes single sweeps
                        'data_unit', cell2mat(datFile.RecTable.ChUnit{2,1}(2)), ... % voltage Channel unit
                        'electrode', ic_elec_link, ...
                        'stimulus_description', datFile.RecTable.Stimulus(e), ... % protocol name   
                        'sweep_number', sweepCount,...
                        'starting_time', startT,...
                        'starting_time_rate', round(datFile.RecTable.SR(e))...
                          ));

                    sweep_ch2 = types.untyped.ObjectView(['/acquisition/', 'Sweep_', num2str(sweepCount)]);
                    sweep_ch1 = types.untyped.ObjectView(['/stimulus/presentation/', 'Sweep_', num2str(sweepCount)]);
                    sweep_series_objects_ch1 = [sweep_series_objects_ch1, sweep_ch1]; %growing objectview
                    sweep_series_objects_ch2 = [sweep_series_objects_ch2, sweep_ch2];
                    sweepCount =  sweepCount + 1;   
             end
         end
    end
    
    %% IntracellularRecordingsTable
    %Michael checks here for the SweepCount length although I dont know
    %why?
    StimDuration = [];
    StimDuration = StimOff - StimOn;
    
    ic_rec_table = types.core.IntracellularRecordingsTable( ...
     'categories', {'electrodes', 'stimiuli', 'responses'}, ...
     'colnames', {'recordings_tag'}, ... % What does this do?
     'description', [ ...
         'A table to group together a stimulus and response from a single ', ...
         'electrode and a single simultaneous recording and for storing ', ...
         'metadata about the intracellular recording.'], ...
     'id', types.hdmf_common.ElementIdentifiers( ...
         'data', int64(0:sweepCount-1)... Why is that - 2 originally at Michaels script?
         ) ...  
    );
    
    ic_rec_table.electrodes = types.core.IntracellularElectrodesTable( ...
        'description', 'Table for storing intracellular electrode related metadata.', ...
        'colnames', {'electrode'}, ...
        'id', types.hdmf_common.ElementIdentifiers( ...
            'data', int64(0:sweepCount-1) ...
        ), ...
        'electrode', types.hdmf_common.VectorData( ...
            'data', repmat(types.untyped.ObjectView(ic_elec), sweepCount, 1), ... Whatch out for correct sweepCount
            'description', 'Column for storing the reference to the intracellular electrode' ...
        ) ...
    );

    ic_rec_table.stimuli = types.core.IntracellularStimuliTable( ...
        'description', 'Table for storing intracellular stimulus related metadata.', ...
        'colnames', {'stimulus'}, ...
        'id', types.hdmf_common.ElementIdentifiers( ... Uniqure identifier for rows in table
            'data', int64([0:sweepCount-1])  ...
        ), ...
        'stimulus', types.core.TimeSeriesReferenceVectorData( ...
            'description', 'Column storing the reference to the recorded stimulus for the recording (rows)', ...
            'data', struct( ...
                'idx_start', [StimOn(StimOn~=0)'], ... Non zero to eliminate the gap free recording?
                'count', [StimDuration(StimDuration~=0)], ...
                'timeseries', [sweep_series_objects_ch1] ... Presentation/stimulus series link
            )...
        )...
    );

    ic_rec_table.responses = types.core.IntracellularResponsesTable( ...
        'description', 'Table for storing intracellular response related metadata.', ...
        'colnames', {'response'}, ...
        'id', types.hdmf_common.ElementIdentifiers( ...
            'data', int64([0:sweepCount-2]) ...
        ), ...
        'response', types.core.TimeSeriesReferenceVectorData( ...
            'description', 'Column storing the reference to the recorded response for the recording (rows)', ...
            'data', struct( ...
                'idx_start', [StimOn'], ... non zero is missing here? Will that add gap free without a corresponding stimulus?
                'count', [StimDuration], ...
                'timeseries', [sweep_series_objects_ch2]...
            )...
        )...
    );

% Add protocol type as column of electrodes table

    Protocols = cell.empty; % Not sure why  this must be cell?

    Protocols(logical(BinaryLP)) = {'LP'}; % fills protocol vector with corresponding types
    Protocols(logical(BinarySP)) = {'SP'};
    Protocols(logical(~BinarySP)&logical(~BinaryLP)) = {'unknown'};

    ic_rec_table.categories = [ic_rec_table.categories, {'protocol_type'}];
    ic_rec_table.dynamictable.set( ...
        'protocol_type', types.hdmf_common.DynamicTable( ...
            'description', 'category table for lab-specific recording metadata', ...
            'colnames', {'label'}, ...
            'id', types.hdmf_common.ElementIdentifiers( ...
                'data', int64([0:sweepCount-1]) ...
            ), ...
            'label', types.hdmf_common.VectorData( ...
                'data', Protocols, ...
                'description', 'Abbreviated Stimulus type: LP = Long Pulse, SP = Short Pulse' ...
            ) ...
        ) ...
    );

% Add Current amplitude as column of stimulus table
    ic_rec_table.stimuli.colnames = [ic_rec_table.stimuli.colnames {'current_amplitude'}]; 
    ic_rec_table.stimuli.vectordata.set('current_amplitude', types.hdmf_common.VectorData( ...
        'data', [SweepAmp'], ...
        'description', 'Current amplitude of injected square pulse' ... % relative to holding
        ) ...
    );

nwb.general_intracellular_ephys_intracellular_recordings = ic_rec_table; % Writes the intracellular recordings table to the nwb file

%%    

    %sessionTag = cell2mat(T.SubjectID(idx)); Doesnt do anything in abf2?
    filename = fullfile(outputfolder ,[nwb.identifier '.nwb']);
    nwbExport(nwb, filename); 
    
end
