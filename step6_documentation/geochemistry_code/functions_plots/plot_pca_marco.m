function plot_pca_marco(coeff, score, var_names, labels, cmap_1)

fontSize = 14;
pop_size = 8;

hFig = figure;
hFig.Position = [120, 120, 900, 900];

h = biplot(coeff(:,1:2), 'scores', score(:,1:2), 'varlabels', var_names, ...
    'MarkerSize', 18); %'Marker', 'none', 
box on

axis equal

% Identify each handle
hID = get(h, 'tag'); 
hPt = h(strcmp(hID,'obsmarker')); % Isolate handles to scatter points

% Identify cluster groups
grp = findgroups(labels); 
grp(isnan(grp)) = max(grp(~isnan(grp)))+1; 
n_groups = max(grp);
grpID = 1:n_groups; 

clrMap = cmap_1;
for i = 1:n_groups
    cmap_2 = clrMap(i, 1:end-1);

    if i <= 4
        set(hPt(grp==i), 'Color', clrMap(i,:), ...
            'DisplayName', sprintf('Population %d', grpID(i)), ...
            'Marker', 'o', 'MarkerSize', 0.8*pop_size, 'MarkerFaceColor', 'none');
    elseif i == 5
        set(hPt(grp==i), 'Color', clrMap(i,:), ...
            'DisplayName', sprintf('Population %d age group 1', 2), ...
            'Marker', "diamond", 'MarkerSize', pop_size, 'MarkerFaceColor', clrMap(i, 1:end-1))
    elseif i == 6
        set(hPt(grp==i), 'Color', clrMap(i,:), ...
            'DisplayName', sprintf('Population %d age group 2', 2), ...
            'Marker', "pentagram", 'MarkerSize', pop_size, 'MarkerFaceColor', clrMap(i, 1:end-1))
    end
end

% The first set of handles are for the variable lines
numVars = size(coeff, 1);
varLineHandles = h(1:numVars);
for i = 1:length(varLineHandles)
    varLineHandles(i).Color = [0.3 0.3 0.3];
    varLineHandles(i).LineWidth = 1;    
    varLineHandles(i).LineStyle = '--'; 
    varLineHandles(i).Marker = 's';
    varLineHandles(i).MarkerSize = 3;
    varLineHandles(i).MarkerEdgeColor = 'black'; %MarkerFaceColor
end

fontsize(fontSize, "points")

%Second set of handles are the variable markers
set(h(numVars+1 : 2*numVars), 'Marker', 'none'); 

% The text handles are the third set of handles returned by biplot
text_handles = h(size(coeff, 1)*2 + 1 : size(coeff, 1)*3);
set(text_handles, 'Interpreter', 'latex');
set(text_handles, 'HorizontalAlignment', 'right'); %center
set(text_handles, 'VerticalAlignment', 'middle'); %top
set(text_handles, 'FontSize', fontSize*0.8);

% add legend to identify cluster
[~, unqIdx] = unique(grp); %grp
legend(hPt(unqIdx), 'Location', 'eastoutside')

xlabel('PC-1');
ylabel('PC-2');
title('Principal Component Analysis');



ax = gca;
ax.Color = [.7, 0.7, .7, 0.2]; 

end