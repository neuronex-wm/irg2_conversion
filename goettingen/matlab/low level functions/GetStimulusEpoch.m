function [StimOn,StimOff] = GetStimulusEpoch(input)

%upper_quantile = quantile(input,0.95);

max_input = max(input);

lower_quantile = quantile(input,0.05);

threshold = max_input*0.5+lower_quantile*0.5;



above_threshold_mask = input>threshold;
diff_of_mask = diff(above_threshold_mask);

left_crossings = find(diff_of_mask==1);

right_crossings = find(diff_of_mask==-1);


max_stim_length = 0;
max_right_idx =-1;
max_left_idx  =-1;

%For debugging
tiledlayout(3,1)
nexttile
plot(input)
yline(threshold);
title("input")




nexttile
plot(above_threshold_mask)
title("above threshold mask")

nexttile
plot(diff_of_mask)
title("diff of mask")

if(length(left_crossings)>50 || length(right_crossings)>50)
    disp("Signal is to noisy");
    StimOn = 1;
    StimOff = 2;
    return;
end


right_i = 1;
for left_i=1:length(left_crossings)
    
    while right_i <= length(right_crossings) && left_crossings(left_i)>right_crossings(right_i)
        right_i= right_i + 1;
        
    end

    if(right_i > length(right_crossings))
        break;
    end

    tmp_stim_length = right_crossings(right_i)-left_crossings(left_i);
    if(tmp_stim_length>max_stim_length)
        max_right_idx = right_i;
        max_left_idx = left_i;
    end
    
    right_i = right_i + 1;

end

StimOn = left_crossings(max_left_idx);
StimOff = right_crossings(max_right_idx);

plot(diff_of_mask);

plot(input)

plot(above_threshold_mask);



end