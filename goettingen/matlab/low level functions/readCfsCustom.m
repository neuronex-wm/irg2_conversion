% Script for reading CED CFS files
% 
% Based on the script 
% written by William Collins, May 2021

%name readCfs already taken by irg2_conversion/goettingen/matlab/third party/matcfs32/readCfs
function CfsFile = readCfsCustom(fullfilename)
    if(isa(fullfilename,'string'))
        fullfilename = convertStringsToChars(fullfilename);
    end
    disp(fullfilename);
    LSTR = 7;
    DSVAR = 1;
    READ = 0;
    
    % choose files to convert
    
    fHandle = matcfs64c('cfsOpenFile',fullfilename,READ,0);
    
    if (fHandle < 0)
        error(['File opening error: ' int2str(fHandle)]);
    end
    
    CfsFile = struct; % initialise Matlab output structure
    
    
    % read file parameters
    [CfsFile.param.fTime,CfsFile.param.fDate,CfsFile.param.fComment] = matcfs64c('cfsGetGenInfo',fHandle);
    [CfsFile.param.channels,fileVars,DSVars,CfsFile.param.dataSections] = matcfs64c('cfsGetFileInfo',fHandle);
    
    % loop over all trials (data sections)
    
    for dsCount = 1:CfsFile.param.dataSections

        flagSet = matcfs64c('cfsDSFlags', fHandle, dsCount, READ);  % setit = 0 to read
        dSbyteSize = matcfs64c('cfsGetDSSize',fHandle,dsCount);
        
        % loop over all channels
        
        for chCount = 1:CfsFile.param.channels
            
            % read trace parameters
            [CfsFile.param.tOffset(chCount),points, ...
                CfsFile.param.yScale(chCount), ...
                CfsFile.param.yOffset(chCount), ...
                CfsFile.param.xScale(chCount), ...
                CfsFile.param.xOffset(chCount)] = ...
                matcfs64c('cfsGetDSChan',fHandle,chCount-1,dsCount);
            [CfsFile.param.channelName{chCount}, ...
                CfsFile.param.yUnits{chCount},CfsFile.param.xUnits{chCount}, ...
                dataType,dataKind,spacing,other] = ...
                matcfs64c('cfsGetFileChan',fHandle,chCount-1);
            
            % zero corresponds to EQUALSPACED, or normal adc data as 
            % opposed to matrix data, which in Signal usually designates
            % markers, or subsidiary data
            if (dataKind == 0)
                % read actual data
                CfsFile.data(:,dsCount,chCount) = ...
                    matcfs64c('cfsGetChanData',fHandle, ...
                    chCount-1,dsCount,0,points,dataType);
                CfsFile.data(:,dsCount,chCount) = ...
                    (CfsFile.data(:,dsCount,chCount) * CfsFile.param.yScale(chCount)) + ...
                    CfsFile.param.yOffset(chCount);
            end
        end % for chCount
    end  % for dsCount

    ret = matcfs64c('cfsCloseFile',fHandle); % close the CFS file 

    
end