function [StimOn,StimOff] = GetStimulusEpoch(input)

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