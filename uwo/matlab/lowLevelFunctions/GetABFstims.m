function [StimOn, StimOff] = GetABFstims(aquiPara, StimOn, BinaryLP, ...
                            StimOff, sweepCount, SweepsPerFile, sample_int)                       
             
if    length(aquiPara.DACEpoch.lEpochInitDuration) > 2                     
      
    tempOn = sum(aquiPara.DACEpoch.lEpochInitDuration(1:3))+ ...               % First three epoch intervalls are Rest-Testpulse-Rest
                     aquiPara.DACEpoch.firstHolding;
else
    tempOn = aquiPara.DACEpoch.lEpochInitDuration(1) + ...
        aquiPara.DACEpoch.firstHolding;
end
        
StimOn(sweepCount:sweepCount+SweepsPerFile-1,1) = tempOn;

if BinaryLP(sweepCount,1)
    StimOff(sweepCount:sweepCount+SweepsPerFile-1,1) = ...
       StimOn(sweepCount:sweepCount+SweepsPerFile-1,1) + (1000000/sample_int);
else
    StimOff(sweepCount:sweepCount+SweepsPerFile-1,1) = ...
       StimOn(sweepCount:sweepCount+SweepsPerFile-1,1) + (3000/sample_int);   
end   
end