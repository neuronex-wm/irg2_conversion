function  [nwb, CS] = addSubAna2NWB(nwb, T, CS) 

%% Add anatomical data from histological processing  
CS.CompDataIdx = find(strcmp(T.IDS, CS.cellID));
if ~isempty(CS.CompDataIdx)
   nwb.general_subject = types.core.Subject( ...
    'subject_id', T.SubjectID(CS.CompDataIdx), 'age', num2str(T.Age_years(CS.CompDataIdx)), ...
    'sex', T.Sex(CS.CompDataIdx), 'species', T.Breed(CS.CompDataIdx), ...
    'weight', num2str(T.Weight_Kg(CS.CompDataIdx))     ... 
     );      
   CS.corticalArea = T.TissueOrigin(CS.CompDataIdx);
   CS.initAccessResistance = num2str(T.InitialAccessResistance(CS.CompDataIdx));
else    
    disp('Manual entry data not found')
    CS.noManuTag = 1;
end          

anatomy = types.core.ProcessingModule(...
                     'description', 'Histological processing',...
                     'dynamictable', []  ...
                           );     
Col1 = find(strcmpi(T.Properties.VariableNames,'SomaLayerLoc'));
Col2 = find(strcmpi(T.Properties.VariableNames,'DendriticType'));
table = table2nwb(T(CS.CompDataIdx, [Col1 Col2]));  
anatomy.dynamictable.set('Anatomical data', table);
nwb.processing.set('Anatomical data', anatomy); 
end