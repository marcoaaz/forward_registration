function [idx_fail_array] = plot_threshold_histograms(input_table, ...
    element_list, element_checks, element_operators)

n_checks = length(element_list);
array = input_table{:, element_list};
n_rows = size(array, 1);

%Cosmetics
pctOut = 1;
value = 0; %for log-scale
fontsize = 18;

nB = n_checks; %number of plots
nf = ceil(nB^0.5); %distribution of sub-plots
if nf^2 - nB >= nf
    nrows = nf-1;
    ncolumns = nf;
else 
    nrows = nf;
    ncolumns = nf;
end

%Plot
hFig = figure;
hFig.Position = [200, 200, 1600, 800];

t= tiledlayout(nrows, ncolumns, "TileSpacing","tight");    
    
idx_fail_array = false(n_rows, n_checks);
for i = 1:n_checks
    
    str_eval = strcat(sprintf('(array(:, %d) ', i), element_operators{i}, sprintf(' element_checks(%d))', i) );
    cond = eval( str_eval );    
    idx_fail_array(:, i) = cond;
    total = sum(cond);    

    temp_array = array(:, i);

    %medicine
    P = prctile(temp_array, [pctOut, 100-pctOut]);    
  
    nexttile
    histogram(temp_array(temp_array> P(1) & temp_array< P(2)) + value)
    xline(element_checks(i) + value, 'red', 'LineWidth', 4)
    
    %text
    xL=xlim; 
    yL=ylim;
    str1 = sprintf('To check= %.f', total);
    text(0.99*xL(2), 0.99*yL(2), str1, 'FontSize', fontsize,...
        'HorizontalAlignment','right','VerticalAlignment','top')
        
    title(element_list{i}, 'interpreter', 'none', 'FontSize', fontsize)
    % set(gca,'Xscale','log')
end
hold off

% close(hFig) %comment to see plot

end