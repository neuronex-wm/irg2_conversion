function CS = getMCCparameter(CS, fileList, f)

if isfile([CS.mainfolder,'\',CS.cellID,'\', fileList(f).name(1:end-3), 'json'])
  raw = fileread([CS.mainfolder,'\',CS.cellID,'\', fileList(f).name(1:end-3), 'json']); 
  settingsMCC = jsondecode(raw);
  if ~isempty(settingsMCC)
      cellsFieldnames = fieldnames(settingsMCC);               
      CS.ic_elec_name = cellsFieldnames{1, 1}(2:end);
      CS.electOffset = settingsMCC.(cellsFieldnames{1,1}).GetPipetteOffset; 
      CS.filterFreq = num2str(settingsMCC.(['x', CS.ic_elec_name]).GetPrimarySignalLPF);
      CS.PipOffset = settingsMCC.(['x', CS.ic_elec_name]).GetPipetteOffset;  
      if isfield(settingsMCC.(['x', CS.ic_elec_name]),'GetBridgeBalEnable') && ...
              settingsMCC.(['x', CS.ic_elec_name]).GetBridgeBalEnable
         CS.brigBal = settingsMCC.(['x', CS.ic_elec_name]).GetBridgeBalResist;  
      end
      if settingsMCC.(['x', CS.ic_elec_name]).GetHoldingEnable
        CS.holdI = settingsMCC.(['x', CS.ic_elec_name]).GetHolding;
      end
      if isfield(settingsMCC.(['x', CS.ic_elec_name]),'GetNeutralizationCap') && ...
              settingsMCC.(['x', CS.ic_elec_name]).GetNeutralizationEnable  
         CS.capComp = settingsMCC.(['x', CS.ic_elec_name]).GetNeutralizationCap;  
      end    
   end   
end

end