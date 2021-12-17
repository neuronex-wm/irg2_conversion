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