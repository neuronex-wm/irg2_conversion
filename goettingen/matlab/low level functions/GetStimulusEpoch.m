function [StimOn,StimOff] = GetStimulusEpoch(input)

[n, bins] =  hist(round(input(10000:end),-1), unique(round(input(10000:end),-1)));
[~,idx] = sort(-n);
values = bins(idx);
if values(2) > 0  
    [~, posPeak] = findpeaks(diff(input), 'MinPeakHeight', 2); % changed this to MinPeakHeight because otherwise it didnt work for more files
    [~, negPeak] = findpeaks(-diff(input), 'MinPeakHeight', 2);
else
    [~, posPeak] = findpeaks(-diff(input), 'MinPeakHeight', 2);
    [~, negPeak] = findpeaks(diff(input), 'MinPeakHeight', 2);
end
if length(posPeak) > 1 & length(negPeak) > 1 % hmm sometimes ramp runs in here
    StimOn = posPeak(2);
    StimOff = negPeak(2);
elseif length(posPeak) > 1 & length(negPeak) == 1 % If ramp is aborted you have two posPeaks but only one negPeak
    StimOn = negPeak;
    StimOff = posPeak(2);    
    
elseif length(posPeak) == 1 & length(negPeak) > 1 % Temp fix added to work with Ramp - not ideal but will do for the moment
    StimOn = posPeak;
    StimOff = negPeak(2);    
else
    StimOn = posPeak;
    StimOff = negPeak;
end