%CfsFilePaths is a list of paths to cfs files

%mainfolder can be ""
function nwb = cfsFiles2NWB(CfsFilePaths,AnimalDesc,cellTag)

    nwbIdentifier = getNwbIdentifier(AnimalDesc,cellTag);
    nwb = initNwb(nwbIdentifier,AnimalDesc);

    sweepAmps = [];
    stimDescs=[];
    sweepNumberEnds=[];
    
    sweepCount = 0;

    cellStartTime = -1;

    ic_elec = -1;

    for f = 1:length(CfsFilePaths)
        file_path = CfsFilePaths(f);
        cfsFile = readCfsCustom(file_path);

        if f==1 
            cellStartTime = datetime([cfsFile.param.fDate(1:end-3), ...
                '/20', cfsFile.param.fDate(end-1:end),' ', cfsFile.param.fTime]...
             ,'TimeZone', 'local');
        end
        ic_elec_name = loadIcElecName([file_path(1:end - 3), 'json']);
    
        [tmpSweepAmps,stimDesc,sweepCount,ic_elec] = cfsFile2NWB(cfsFile, nwb,ic_elec_name, sweepCount, cellStartTime);

        sweepAmps= [sweepAmps,tmpSweepAmps];
        stimDescs=[stimDescs,stimDesc];
        sweepNumberEnds = [sweepNumberEnds,sweepCount];
        
        
    end

    if (sweepCount>5)
        ic_rec_table = createIcRecTable(sweepCount, ic_elec,sweepAmps,stimDescs,sweepNumberEnds);
        nwb.general_intracellular_ephys_intracellular_recordings = ic_rec_table;
    end

end

function Protocols = createProtocols(stimDescriptions,sweepNumberEnds)
    Protocols = cell.empty;
    sweepNumber = 1;
    for file_i = 1:length(stimDescriptions)
        stimDesc = stimDescriptions(file_i);
        
        protocol = {'Unknown'};
        if(strcmp(stimDesc.name,'Long Pulse'))
            protocol = {'LP'};
        elseif(strcmp(stimDesc.name,'Short Pulse'))
            protocol = {'SP'};
        end
        
        sweepNumberStart = 1;
        if(file_i>1)
            sweepNumberStart = sweepNumberEnds(file_i-1)+1;
        end
        for tmp_ = sweepNumberStart:sweepNumberEnds(file_i)
            Protocols(sweepNumber) = protocol;
            sweepNumber=sweepNumber+1; 
        end
    end

end

function [sweep_series_objects_ch1,sweep_series_objects_ch2] = createSweepSeries(sweepNumberEnds)
    sweep_series_objects_ch1 = [];
    sweep_series_objects_ch2 = [];
    sweepNumber = 0;
    for file_i = 1:length(sweepNumberEnds)
        sweepNumberStart = 1;
        if(file_i>1)
            sweepNumberStart = sweepNumberEnds(file_i-1)+1;
        end
        for tmp_ = sweepNumberStart:sweepNumberEnds(file_i)
            sweep_ch2 = types.untyped.ObjectView(['/acquisition/', 'Sweep_', num2str(sweepNumber)]);
            sweep_ch1 = types.untyped.ObjectView(['/stimulus/presentation/', 'Sweep_', num2str(sweepNumber)]);
            sweep_series_objects_ch1 = [sweep_series_objects_ch1, sweep_ch1]; 
            sweep_series_objects_ch2 = [sweep_series_objects_ch2, sweep_ch2];
            sweepNumber=sweepNumber+1; 
        end
    end
end

function ic_rec_table = createIcRecTable(sweepCount, ...
        ic_elec, ...
        SweepAmps,...
        stimDescriptions,...
        sweepNumberEnds... %the end index of the sweepNumber for the individual files
)

    

    % Add protocol type as column of electrodes table

    Protocols = createProtocols(stimDescriptions,sweepNumberEnds);

    [sweep_series_objects_ch1,sweep_series_objects_ch2] = createSweepSeries(sweepNumberEnds);

    stimOn=[];%%StimOn
    stimCount = [];%%StimDuration
    
    for file_i = 1:length(stimDescriptions)
        stimDesc = stimDescriptions(file_i);
        sweepNumberStart = 1;
        if(file_i>1)
            sweepNumberStart = sweepNumberEnds(file_i-1)+1;
        end
        for tmp_ = sweepNumberStart:sweepNumberEnds(file_i)
            stimOn = [stimOn,stimDesc.start_idx];
            stimCount = [stimCount,stimDesc.count];
        end
    end


    %BinaryLP(isnan(BinaryLP)) = 0; % should be accounted for in line 98/99
    %BinarySP(isnan(BinarySP)) = 0;
    stimOn(isnan(stimOn)) = 0;
    %stimOff(isnan(stimOff)) = 0;
    SweepAmps(isnan(SweepAmps)) = 0;

    ic_rec_table = types.core.IntracellularRecordingsTable( ...
        'categories', {'electrodes', 'stimuli', 'responses'}, ...
        'colnames', {'recordings_tag'}, ...
        'description', [ ...
            'A table to group together a stimulus and response from a single ', ...
            'electrode and a single simultaneous recording and for storing ', ...
        'metadata about the intracellular recording.'], ...
        'id', types.hdmf_common.ElementIdentifiers( ...
        'data', int64([0:sweepCount - 1]) ...
    ) ...
    );

    ic_rec_table.electrodes = types.core.IntracellularElectrodesTable( ...
        'description', 'Table for storing intracellular electrode related metadata.', ...
        'colnames', {'electrode'}, ...
        'id', types.hdmf_common.ElementIdentifiers( ...
        'data', int64([0:sweepCount - 1]) ...
    ), ...
        'electrode', types.hdmf_common.VectorData( ...
        'data', repmat(types.untyped.ObjectView(ic_elec), sweepCount, 1), ...
        'description', 'Column for storing the reference to the intracellular electrode' ...
    ) ...
    );

    ic_rec_table.stimuli = types.core.IntracellularStimuliTable( ...
        'description', 'Table for storing intracellular stimulus related metadata.', ...
        'colnames', {'stimulus'}, ...
        'id', types.hdmf_common.ElementIdentifiers( ...
        'data', int64([0:sweepCount - 1]) ...
    ), ...
        'stimulus', types.core.TimeSeriesReferenceVectorData( ...
        'description', 'Column storing the reference to the recorded stimulus for the recording (rows)', ...
        'data', struct( ...
        'idx_start', [stimOn(stimOn ~= 0)'], ...
        'count', [stimCount(stimCount ~= 0)], ...
        'timeseries', [sweep_series_objects_ch1] ...
    ) ...
    ) ...
    );
    ic_rec_table.responses = types.core.IntracellularResponsesTable( ...
        'description', 'Table for storing intracellular response related metadata.', ...
        'colnames', {'response'}, ...
        'id', types.hdmf_common.ElementIdentifiers( ...
        'data', int64([0:sweepCount - 1]) ...
    ), ...
        'response', types.core.TimeSeriesReferenceVectorData( ...
        'description', 'Column storing the reference to the recorded response for the recording (rows)', ...
        'data', struct( ...
        'idx_start', [stimOn'], ...
        'count', [stimCount], ...
        'timeseries', [sweep_series_objects_ch2] ...
    ) ...
    ) ...
    );



    ic_rec_table.categories = [ic_rec_table.categories, {'protocol_type'}];
    ic_rec_table.dynamictable.set( ...
        'protocol_type', types.hdmf_common.DynamicTable( ...
        'description', 'category table for lab-specific recording metadata', ...
        'colnames', {'label'}, ...
        'id', types.hdmf_common.ElementIdentifiers( ...
        'data', int64([0:sweepCount - 2]) ...
    ), ...
        'label', types.hdmf_common.VectorData( ...
        'data', Protocols, ...
        'description', 'Abbreviated Stimulus type: LP= Long Pulse, SP= Short Pulse' ...
    ) ...
    ) ...
    );

    % Add Current amplitude as column of stimulus table
    ic_rec_table.stimuli.colnames = [ic_rec_table.stimuli.colnames {'current_amplitude'}];
    ic_rec_table.stimuli.vectordata.set('current_amplitude', types.hdmf_common.VectorData( ...
        'data', [SweepAmps'], ...
        'description', 'Current amplitude of injected square pulse' ...
    ) ...
    );

end


%% data = 1d array
%%struct StimDescription:
%%      name
%%      start_idx (was called on in early versions)
%%      end_idx (was called off in early versions)
%%      duration
function StimDescription = createStimDescription(data,x_scale)
    StimDescription = struct;
    [start_i,end_i] = GetStimulusEpoch(data);
    StimDescription.start_idx = start_i;
    StimDescription.end_idx = end_i;
    StimDescription.count = (end_i-start_i);

    duration = StimDescription.count * x_scale;


    %%??? see line 120 in cfs2NWBconversionG
    if round(duration,0) == 1 && length(data) == 400000 % length check needed to prevent misslabeling of capacitance recordings as LP
        StimDescription.name='Long Pulse';

    elseif round(duration,3) == 0.003
        StimDescription.name='Short Pulse';
    else
        disp(['Unknown stimulus type with duration of '... includes ramp problem
        , num2str(round(duration,3)), ' s']);
        StimDescription.name='Unknown';
    end

end

function amp = getStimAmplitude(data,stimDesc)
    stim_on_data = data(stimDesc.start_idx:stimDesc.end_idx);
    amp = round(mean(stim_on_data),-1);
end

%%???
%%a=data(:,s,1) %%?? how do you call these channels
%%fTime = D.param.fTime
%%a: Spannungs Kanal
%%b: Strom Kanal
function nwbAddSweep(nwb,sweep_number,electrode,stimulus_name,fTime,...
                     data_a,y_unit_a,start_time_rate_a,...
                     data_b,y_unit_b,start_time_rate_b)

     ccs = types.core.CurrentClampStimulusSeries( ...
            'electrode', electrode, ...
            'gain', NaN, ...
            'stimulus_description', stimulus_name, ...
            'data_unit', y_unit_b, ...
            'data', data_b, ... 
            'sweep_number', sweep_number,...
            'starting_time', seconds(duration(fTime)),...
            'starting_time_rate', start_time_rate_b... %% why different rates?
            );
        
    nwb.stimulus_presentation.set(['Sweep_', num2str(sweep_number)], ccs);    
   
       if On-(0.45/D.param.xScale(1)) < 0 % calculating bias current
                    bias = mean(D.data(1:On,s,2)); % no testpulse or unknown protocols; pA
                else
                    bias = mean(D.data(ceil(On-(0.45/D.param.xScale(1))):On,s,2)); % with test pulse; pA; ceil because matlab throws an error otherwise
                end
                
    nwb.acquisition.set(['Sweep_', num2str(sweep_number)], ...
        types.core.CurrentClampSeries( ...
            'bias_current', [], ... % Unit: Amp
            'bridge_balance', [], ... % Unit: Ohm
            'capacitance_compensation', [], ... % Unit: Farad
            'data', data_a, ...
            'data_unit', y_unit_a, ...
            'electrode', electrode, ...
            'stimulus_description', stimulus_name, ...   
            'sweep_number', sweep_number,...
            'starting_time', seconds(duration(fTime)),...
            'starting_time_rate', start_time_rate_a...
                ));
end



%%json_path = [mainfolder, cellID, '\', fileList(f).name(1:end - 3), 'json']
function ic_elec_name = loadIcElecName(json_path)
    %% load JSON from MCC get settings files if present
    if isfile(json_path)
        raw = fileread(json_path);
        settingsMCC = jsondecode(raw);
        cellsFieldnames = fieldnames(settingsMCC);
        ic_elec_name = cellsFieldnames{1, 1}(2:end);
        %%electOffset = settingsMCC.(cellsFieldnames{1, 1}).GetPipetteOffset;
    else
        ic_elec_name = 'unknown electrode';
        %%electOffset = NaN;
    end
end

function [ic_elec,ic_elec_link] = nwbInitElectrode(nwb,ic_elec_name)

    corticalArea = 'NA'; % Location place holder

    device_name = 'CED digitizer Power 1401 mkII; Amplifier: SEC-05X';  % @Stefan: hier bitte die richtigen

    %% Getting run and electrode associated properties
    nwb.general_devices.set(device_name, types.core.Device());
    device_link = types.untyped.SoftLink(['/general/devices/' device_name]);
    ic_elec = types.core.IntracellularElectrode( ...
        'device', device_link, ...
        'description', 'Properties of electrode and run associated to it', ...
        'filtering', 'unknown', ...
        'initial_access_resistance', 'has to be entered manually', ...
        'location', corticalArea ...
    );
    nwb.general_intracellular_ephys.set(ic_elec_name, ic_elec);
    ic_elec_link = types.untyped.SoftLink(['/general/intracellular_ephys/' ic_elec_name]);
end

function [sweepAmps,stimDesc,sweepNumberEnd,ic_elec] = cfsFile2NWB(CfsFile, ...
        nwb, ...
        ic_elec_name, ...
        sweepNumberStart, ...
        cellStartTime)

    nwb.session_start_time = cellStartTime;

   
    stimDesc = createStimDescription(mean(CfsFile.data(:,:,2),2),CfsFile.param.xScale(2));

    sweepAmps = [];
    
    sweepNumber = sweepNumberStart;

    for s = 1:size(CfsFile.data, 2)

        [ic_elec,ic_elec_link] = nwbInitElectrode(nwb,ic_elec_name);
    
        sweepAmps = [sweepAmps,getStimAmplitude(CfsFile.data(:,s,2),stimDesc)];
    
        nwbAddSweep(nwb,...
                    sweepNumber,...
                    ic_elec_link,stimDesc.name,...
                    CfsFile.param.fTime,...
                    CfsFile.data(:,s,1), CfsFile.param.yUnits{1}, round(1/CfsFile.param.xScale(1)),...
                    CfsFile.data(:,s,2), CfsFile.param.yUnits{2}, round(1/CfsFile.param.xScale(2)));
        
        sweepNumber = sweepNumber+1;

    end
    
    sweepNumberEnd = sweepNumber;
end

function nwb = initNwb(nwbIdentifier,AnimalDesc)
    nwb = NwbFile(...
        'identifier', nwbIdentifier, ...
        'general_lab', 'Jochen Staiger', ...
        'general_institution', 'Institute for Neuroanatomy UMG', ...
        'general_experiment_description', 'Characterizing intrinsic biophysical properties of cortical NHP neurons.', ...
        'session_description', 'One experiment day' ...
    );

    nwb.general_subject = types.core.Subject( ...
        'description', AnimalDesc.name, ...
        'age', AnimalDesc.age, ...
        'sex', AnimalDesc.sex, ...
        'species', AnimalDesc.species ...
    );

end

function ID = getNwbIdentifier(AnimalDesc,CellTag)
    
    MATFXID = ['M',AnimalDesc.number,'_',AnimalDesc.name, '_A1_C', CellTag,'_']; % ID for MatFX naming convention - needs to be expanded on
    ID = [MATFXID,'Goettingen', '_',AnimalDesc.Amp,'_Cell', CellTag];
end


