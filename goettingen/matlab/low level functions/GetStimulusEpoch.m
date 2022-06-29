function [StimOn,StimOff] = GetStimulusEpoch(input)

[n, bins] =  hist(round(input(10000:end),-1), unique(round(input(10000:end),-1)));
[~,idx] = sort(-n);
values = bins(idx);
if values(2) > 0  
    [~, posPeak] = findpeaks(diff(input), 'MinPeakHeight', 1); % changed this to MinPeakHeight because otherwise it didnt work for more files
    [~, negPeak] = findpeaks(-diff(input), 'MinPeakHeight', 1);
else
%     [~, posPeak] = findpeaks(-diff(input),'SortStr','descend','NPeaks',2);
%     [~, negPeak] = findpeaks(diff(input),'SortStr','descend','NPeaks',2);
      [~, posPeak] = findpeaks(-diff(input), 'MinPeakHeight', 1);
      [~, negPeak] = findpeaks(diff(input), 'MinPeakHeight', 1);
end
% the following loop is only for the occasionaly odd thing I dont know
% about why
if isempty(negPeak) || isempty(posPeak) % to find anything if previous failed
    [~, posPeak] = findpeaks(-diff(input),'SortStr','descend','NPeaks',2);
    [~, negPeak] = findpeaks(diff(input),'SortStr','descend','NPeaks',2);
    if length(posPeak) > 1
            if posPeak(end) > negPeak(end)  % replaced all 2s with end
                StimOn = negPeak(end);
                StimOff = posPeak(end);  
            else
                StimOn = posPeak(end);
                StimOff = negPeak(end);
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
% End odd thing

if negPeak(end) >=80000 || posPeak(end)  >=80000 % loop for ramp with variable endpoint 
    Changepoints = find(ischange(input,'linear','Threshold',100000)~=0); % contains all stim on and offs - quite close to findpeaks points
    if length(Changepoints) == 2
        StimOn = Changepoints(1); % 1st one is ramp onset
        StimOff = Changepoints(2); % 2nd one usually off
        disp(['Changepoints length ', num2str(length(Changepoints))])
    elseif length(Changepoints) == 3 % Jenifer's ramps have no test pulse
        StimOn = Changepoints(1); % no test pulse means this is the start
        StimOff = Changepoints(end); % end doesnt matter
        disp(['Changepoints length ', num2str(length(Changepoints))])
    else
        StimOn = Changepoints(3); % 3rd one is ramp onset
        StimOff = Changepoints(4); % 4th one usually off
        disp(['Changepoints length ', num2str(length(Changepoints))])
    end
else
    if length(posPeak) > 1
        if posPeak(end) > negPeak(end)  % replaced all 2s with end
            StimOn = negPeak(end);
            StimOff = posPeak(end);  
        else
            StimOn = posPeak(end);
            StimOff = negPeak(end);
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