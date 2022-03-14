function [StimOn,StimOff] = GetStimulusEpoch(input)

[n, bins] =  hist(round(input(10000:end),-1), unique(round(input(10000:end),-1)));
[~,idx] = sort(-n);
values = bins(idx);
if values(2) > 0  
    [~, posPeak] = findpeaks(diff(input), 'MinPeakHeight', 2); % changed this to MinPeakHeight because otherwise it didnt work for more files
    [~, negPeak] = findpeaks(-diff(input), 'MinPeakHeight', 2);
else
%     [~, posPeak] = findpeaks(-diff(input),'SortStr','descend','NPeaks',2);
%     [~, negPeak] = findpeaks(diff(input),'SortStr','descend','NPeaks',2);
      [~, posPeak] = findpeaks(-diff(input), 'MinPeakHeight', 1);
      [~, negPeak] = findpeaks(diff(input), 'MinPeakHeight', 1);
end
if negPeak(end) >=80000 || posPeak(end)  >=80000 % loop for ramp with variable endpoint 
    Changepoints = find(ischange(input,'linear','Threshold',100000)~=0); % contains all stim on and offs - quite close to findpeaks points
    if length(Changepoints) == 2
        StimOn = Changepoints(1); % 3rd one is ramp onset
        StimOff = Changepoints(2); % 4th one usually off
        disp(['Changepoints length ', num2str(length(Changepoints))])
    else
        StimOn = Changepoints(3); % 3rd one is ramp onset
        StimOff = Changepoints(4); % 4th one usually off
        disp(['Changepoints length ', num2str(length(Changepoints))])
    end
else
    if length(posPeak) > 1
        if posPeak(2) > negPeak(2)
            StimOn = negPeak(2);
            StimOff = posPeak(2);  
        else
            StimOn = posPeak(2);
            StimOff = negPeak(2);
        end
    else
        if posPeak > negPeak % Cap compensation recording
            StimOn = negPeak;
            StimOff = posPeak;
        else
            StimOn = posPeak;
            StimOff = negPeak;
        end
    end
end
end