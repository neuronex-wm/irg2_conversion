function [nwb,ic_elec,ICelecLink] = addRunElec2NWB(nwb, CS, T)
 
if any(strcmp('Temperature',T.Properties.VariableNames))
    Temperature = num2str(T.Temperature(CS.CompDataIdx));
else
    Temperature = 'not documented';
end
device_link = types.untyped.SoftLink(['/general/devices/', 'Amplifier']);
ic_elec = types.core.IntracellularElectrode( ...
           'device', device_link, ...
           'description', 'Properties of electrode and run associated to it',...
           'filtering', CS.filterFreq ,...
           'initial_access_resistance',CS.initAccessResistance,...
           'location', CS.corticalArea,...
           'slice', ['Temperature ',Temperature ]...
        );
nwb.general_intracellular_ephys.set(CS.ic_elec_name, ic_elec);
ICelecLink = types.untyped.SoftLink(['/general/intracellular_ephys/' CS.ic_elec_name]); 

end