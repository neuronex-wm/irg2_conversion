function [CS] = GetABFstims(aquiPara, CS, SweepsPerFile, sample_int)                       
             
if    length(aquiPara.DACEpoch.lEpochInitDuration) > 2                     
      
    tempOn = sum(aquiPara.DACEpoch.lEpochInitDuration(1:3))+ ...               % First three epoch intervalls are Rest-Testpulse-Rest
                     aquiPara.DACEpoch.firstHolding;
else
    tempOn = aquiPara.DACEpoch.lEpochInitDuration(1) + ...
        aquiPara.DACEpoch.firstHolding;
end
        
CS.StimOn(CS.swpCt:CS.swpCt+SweepsPerFile-1,1) = tempOn;

if CS.BinaryLP(CS.swpCt,1)
    CS.StimOff(CS.swpCt:CS.swpCt+SweepsPerFile-1,1) = ...
       CS.StimOn(CS.swpCt:CS.swpCt+SweepsPerFile-1,1) + (1000000/sample_int);
else
    CS.StimOff(CS.swpCt:CS.swpCt+SweepsPerFile-1,1) = ...
       CS.StimOn(CS.swpCt:CS.swpCt+SweepsPerFile-1,1) + (3000/sample_int);   
end   
end