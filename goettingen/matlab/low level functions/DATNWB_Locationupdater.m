csvfolder = uigetdir('E:\Data\MonkeyData\Monkeys','Select folder containing all csvs');
db_builder = DbBuilder(csvfolder);

cellfolder = uigetdir('E:\Data\MonkeyData\Monkeys','Select folder containing all converted cells');
cellList = getCellNames(cellfolder);
fileList = dir([cellfolder,'/*.nwb']);

outputfolder = uigetdir('E:\Data\MonkeyData\Monkeys','Select outputfolder for updated files');

monkey_db = db_builder.OpenMonkeys();
db_a=db_builder.OpenCells('Andreas');
db_s=db_builder.OpenCells('Stefan');

for k = 1:length(fileList)
    nameparts = split(fileList(k).name,'_');
    monkeyID = str2double(nameparts{1}(2:end));
    patcherID = nameparts{2};
    cellID = str2double(nameparts{4}(2:end));
    monkeyName = monkey_db.table.Monkey(monkey_db.table.Number == monkeyID);
    switch patcherID
        case 'AN'
            cellData = db_a.request('Monkey', monkeyName, 'Cell',cellID);
        case 'SP'
            cellData = db_s.request('Monkey', monkeyName, 'Cell',cellID);
        otherwise
            disp 'Error'
            continue
    end
    disp(['detected ' convertStringsToChars(fileList(k).name) ' -- ' ...
        convertStringsToChars(monkeyName) ' ' patcherID ' ' ...
        convertStringsToChars(cellData.PatcherCellName)])
    nwb = nwbRead([fileList(k).folder,'\',fileList(k).name]);
    
    nwb.general_intracellular_ephys.values{1}.location = cellData.Location;
    disp(['Updating ',patcherID,' ', convertStringsToChars(monkeyName),...
            ' Cell', num2str(cellID),' location'])
       
    
    nwb_savepath = fullfile([outputfolder , '\',fileList(k).name]);
    nwbExport(nwb, nwb_savepath);
end