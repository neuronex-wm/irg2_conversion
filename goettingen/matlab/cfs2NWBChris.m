

% for debugging
% mainfolder = 'F:\uni\nebenjob\data\NPI Neuroanatomy - Raw Data CFS-Files\Eisenherz_01032022\Jenifer_20220301';
% outputfolder = 'F:\uni\nebenjob\output\cfs';

mainfolder = uigetdir('E:\Data\MonkeyData\Monkeys','Select main folder containing all cell folders'); % select individual folders at start
outputfolder = uigetdir(mainfolder,'Select output folder'); 

% %for debugging
% desc = struct;
% desc.number = '1';
% desc.patcher = 'T';
% desc.Amp = 'T';
% % capitalizes first letter
% desc.name = 'Test'; 
% desc.age ='1y';
% desc.sex = 'T';
% % capitalizes first letter
% desc.species = 'T'; 

desc = getAnimalDesc();

cellList = getCellNames(mainfolder);

for n = 1:length(cellList)
    cellID = cellList(n).name;
    disp(cellID);
    cellTag = num2str(n, '%02.f');
    fileList = dir([mainfolder,'/',cellList(n,1).name,'/*.cfs']);

    pathList = strcat({fileList.folder},{'/'},{fileList.name});

    pathList = string(pathList);

    nwb = cfsFiles2NWB(pathList,desc,cellTag);

    nwb_savepath = fullfile([outputfolder , '\',nwb.identifier '.nwb']);
    nwbExport(nwb, nwb_savepath);

end