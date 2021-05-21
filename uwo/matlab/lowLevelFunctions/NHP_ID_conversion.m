function f = NHP_ID_conversion(input)
      str = [input(2:3), sprintf('%d', ...
          double(input(5:6))), input(12:13), '00'];                        %creates a string from monkey number, experimenter initals and cell number like 02JS07 and adds '00' as lab ID number at the end
      rng(str2double(str)); % the string is converted into a number and set as seed for the rng
      f = randi([1000000 9999999]); % returns a random but deterministic 7 digit integer with unique correspondance to original ID
end