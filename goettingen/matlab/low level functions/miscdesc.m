function [number, patcher, Amp, name, age, sex, species, area, weight] = miscdesc(varagin)


   % gets input for nwb file
   answer = inputdlg({'Monkey sequential number:', 'Experimenter initials:',...
       'Amp (Heka or NPI):', 'Animal name:', 'Animal age:', 'Animal sex:',...
       'Animal species:', 'Area:', 'Weight:'},'General description');
   number = num2str(str2num(answer{1}), '%02.f');
   patcher = upper(answer{2});
   Amp = upper(answer{3});
   name = [upper(answer{4}(1)), lower(answer{4}(2:end))]; % capitalizes first letter
   age = answer{5};
   sex = upper(answer{6});
   species = [upper(answer{7}(1)), lower(answer{7}(2:end))]; % capitalizes first letter
   area = upper(answer{8});
   weight = answer{9};
end
