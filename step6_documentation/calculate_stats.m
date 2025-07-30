function [stats2] = calculate_stats(pixels1, basename)

%Edit accordingly
items = {'min', 'max', 'mode'};
colnames = strcat(basename, '_', items);

%cannot be empty input
a = min(pixels1, [], 'all');
b = max(pixels1, [], 'all'); 
[N, edges] = histcounts(pixels1); %automatic binning
[~, idx_max] = max(N);
c = (edges(idx_max) + edges(idx_max + 1))/2; %mode  

stats = [a, b, c];
stats2 = array2table(stats, 'VariableNames',colnames);

end