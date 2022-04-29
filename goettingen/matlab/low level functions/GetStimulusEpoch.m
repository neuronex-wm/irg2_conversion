function [CS] = GetStimulusEpoch(data, CS, xScl)
input = mean(data,2);
[~, posPeak] = findpeaks(diff(input), 'NPeaks', 1,'SortStr', 'descend');
[~, negPeak] = findpeaks(-diff(input), 'NPeaks', 1,'SortStr', 'descend');
if length(posPeak) > 1
    StimOn = posPeak(2);
    StimOff = negPeak(2);
else
    StimOn = posPeak;
    StimOff = negPeak;
end
CS.StimOn(CS.swpCt:CS.swpCt-1+size(data,2)) = StimOn;
CS.StimOff(CS.swpCt:CS.swpCt-1+size(data,2)) = StimOff;       
CS.StimDuration(CS.swpCt:CS.swpCt-1+size(data,2)) = ...
              unique(CS.StimOff(CS.swpCt:CS.swpCt-1+size(data,2))) - ...
                           CS.StimOn(CS.swpCt:CS.swpCt-1+size(data,2));
if CS.StimDuration(CS.swpCt:CS.swpCt-1+size(data,2)) > round(0.49/xScl(2))
   CS.stimulus_name = 'Long Pulse' ;  
   CS.BinaryLP(CS.swpCt:CS.swpCt+size(data,2)-1) = 1;
   CS.BinarySP(CS.swpCt:CS.swpCt+size(data,2)-1) = 0;
elseif CS.StimDuration(CS.swpCt:CS.swpCt-1+size(data,2)) == round(1/xScl(2)*0.003)
   CS.stimulus_name = 'Short Pulse' ;  
   CS.BinaryLP(CS.swpCt:CS.swpCt+size(data,2)-1) = 0;
   CS.BinarySP(CS.swpCt:CS.swpCt+size(data,2)-1) = 1;
end        