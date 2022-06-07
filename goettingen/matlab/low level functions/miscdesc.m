function [number, patcher, Amp, name, age, sex, species] = miscdesc(varagin)


   % gets input for nwb file
   answer = inputdlg({'Monkey sequential number:', 'Experimenter initials:',...
       'Amp (Heka or NPI):', 'Animal name:', 'Animal age:', 'Animal sex:',...
       'Animal species:'},'General description');
   number = num2str(str2num(answer{1}), '%02.f');
   patcher = upper(answer{2});
   Amp = upper(answer{3});
   name = [upper(answer{4}(1)), lower(answer{4}(2:end))]; % capitalizes first letter
   age = [num2str(answer{5}), ' y'];
   sex = upper(answer{6});
   species = [upper(answer{7}(1)), lower(answer{7}(2:end))]; % capitalizes first letter
end
