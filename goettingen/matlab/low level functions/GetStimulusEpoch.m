function [CS] = GetStimulusEpoch(data, CS, xScl)
input = mean(data,2);
[n, bins] =  hist(round(input(10000:end),-1), unique(round(input(10000:end),-1)));
[~,idx] = sort(-n);
values = bins(idx);
if values(2) > 0  
    [~, posPeak] = findpeaks(diff(input), 'Threshold', 5);
    [~, negPeak] = findpeaks(-diff(input), 'Threshold', 5);
else
    [~, posPeak] = findpeaks(-diff(input), 'Threshold', 5);
    [~, negPeak] = findpeaks(diff(input), 'Threshold', 5);
end
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
if CS.StimDuration(CS.swpCt:CS.swpCt-1+size(data,2)) == round(1/xScl(2))
   CS.stimulus_name = 'Long Pulse' ;  
   CS.BinaryLP(CS.swpCt+1:CS.swpCt+size(data,2)) = 1;
   CS.BinarySP(CS.swpCt+1:CS.swpCt+size(data,2)) = 0;
elseif CS.StimDuration(CS.swpCt:CS.swpCt-1+size(data,2)) == round(1/xScl(2)*0.003)
   CS.stimulus_name = 'Short Pulse' ;  
   CS.BinaryLP(CS.swpCt+1:CS.swpCt+size(data,2)) = 0;
   CS.BinarySP(CS.swpCt+1:CS.swpCt+size(data,2)) = 1;
end        