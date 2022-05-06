function AnimalDesc = getAnimalDesc()
     % gets input for nwb file
   answer = inputdlg({'Monkey sequential number:', 'Experimenter initials:',...
       'Amp (Heka or NPI):', 'Animal name:', 'Animal age:', 'Animal sex:',...
       'Animal species:'},'General description');

   AnimalDesc.number = num2str(str2num(answer{1}), '%02.f');
   AnimalDesc.patcher = upper(answer{2});
   AnimalDesc.Amp = upper(answer{3});
   % capitalizes first letter
   AnimalDesc.name = [upper(answer{4}(1)), lower(answer{4}(2:end))]; 
   AnimalDesc.age = [num2str(answer{5}), ' y'];
   AnimalDesc.sex = upper(answer{6});
   % capitalizes first letter
   AnimalDesc.species = [upper(answer{7}(1)), lower(answer{7}(2:end))]; 
end