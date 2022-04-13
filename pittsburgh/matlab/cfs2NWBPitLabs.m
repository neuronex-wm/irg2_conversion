function cfs2NWBPitLabs(varargin)

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

for n = 1:length(cellList)
    CS = struct();
    CS.mainfolder=mainfolder;
    T = table();
    [nwb, CS] = initNWB(cellList, n, CS); 
    nwb.general_institution = 'University of Goettingen';
    nwb.general_devices.set('Amplifier', ...
          types.core.Device('description', '?????', ...
                                     'manufacturer', 'npi'));                          
    nwb.general_devices.set('Digitizer', ...
         types.core.Device('description', '?????', ...
                                     'manufacturer', 'Cambridge electronic design'));      %% loading the matlab converted cfs files
    fileList = dir([mainfolder,'/',cellList(n,1).name,'/*.mat']);
    paths = fullfile({fileList.folder}, {fileList.name});
    for f = 1:length(fileList)
       load(paths{f})     
%% Getting start date from 1st recording of cell and checking for new session start 
     if f==1             
       CS.cStart = datetime([D.param.fDate(1:end-3), '/20', ...
                            D.param.fDate(end-1:end),' ', D.param.fTime]...
                                                     ,'TimeZone', 'local');                      
       [nwb, CS] = saveCellStart(nwb, CS, sessionTag);   
       [nwb,ic_elec, ICelecLink] = addRunElec2NWB(nwb, CS, T);                      % Getting run and electrode associated properties 
     end     
    %% Data: recreating the stimulus waveform
     CS = GetStimulusEpoch(D.data(:,:,2), CS, D.param.xScale);       
     for s = 1:size(D.data,2) % looping through sweeps
                
      CS.SwpAmp(CS.swpCt) = round(mean(D.data(CS.StimOn(CS.swpCt)...
                                       :CS.StimOff(CS.swpCt),s,2)),-1);
                
      ccs = types.core.CurrentClampStimulusSeries( ...
                        'electrode', ICelecLink, ...
                        'gain', NaN, ...
                        'stimulus_description', CS.stimulus_name, ...
                        'data_unit', D.param.yUnits{2}, ...
                        'data', D.data(:,s,2), ...
                        'sweep_number', CS.swpCt-1,...
                        'starting_time', seconds(duration(D.param.fTime)),...
                        'starting_time_rate', round(1/D.param.xScale(2))...
                        );
                    
     nwb.stimulus_presentation.set(['Sweep_', num2str(CS.swpCt-1)], ccs);    
                
     nwb.acquisition.set(['Sweep_', num2str(CS.swpCt-1)], types.core.CurrentClampSeries( ...
                        'bias_current', [], ... % Unit: Amp
                        'bridge_balance', [], ... % Unit: Ohm
                        'capacitance_compensation', [], ... % Unit: Farad
                        'data', D.data(:,s,1), ...
                        'data_unit', D.param.yUnits{1}, ...
                        'electrode', ICelecLink, ...
                        'stimulus_description', CS.stimulus_name, ...   
                        'sweep_number', CS.swpCt-1,...
                        'starting_time', seconds(duration(D.param.fTime)),...
                        'starting_time_rate', round(1/D.param.xScale(1))...
                          ));
                    
      sweep_ch2 = types.untyped.ObjectView(['/acquisition/', 'Sweep_', ...
                                                        num2str(CS.swpCt-1)]);
      sweep_ch1 = types.untyped.ObjectView(['/stimulus/presentation/', ...
                                              'Sweep_', num2str(CS.swpCt-1)]);
      CS.sweep_series_objects_ch1 = [CS.sweep_series_objects_ch1, sweep_ch1]; 
      CS.sweep_series_objects_ch2 = [CS.sweep_series_objects_ch2, sweep_ch2];
      CS.swpCt =  CS.swpCt + 1;   
     end    % end of sweep loop 
  end     % end of file loop
  nwb = makeICtab(nwb, CS, ic_elec); 
  filename = fullfile([outputfolder , 'Pittsburgh_',nwb.identifier '.nwb']);
  nwbExport(nwb, filename);
end% end of cell loop
