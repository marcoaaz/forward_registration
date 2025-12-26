function plot_mds_marco(Y, labels, cmap_1)

fontSize = 14;
pop_size = 8;
available_symbols = 'oooodp'; %Generate symbols
cmap_2 = cmap_1(:, 1:end-1);

%Plot
hFig2 = figure;
hFig2.Position = [150, 150, 900, 900];

h = gscatter(Y(:,1), Y(:,2), labels, cmap_2, available_symbols, pop_size, 'on', 'X-Axis', 'Y-Axis'); %'.'

box on
grid on
axis equal

% Loop through each group handle to set MarkerFaceColor
for i = 1:numel(h)   
    if (i == 5)
        set(h(i), 'MarkerFaceColor', cmap_2(i, :));           
        set(h(i), 'MarkerSize', pop_size);  
        set(h(i), 'DisplayName', sprintf('Population %d age group 1', 2));  
    elseif (i ==6)        
        set(h(i), 'MarkerFaceColor', cmap_2(i, :));           
        set(h(i), 'MarkerSize', pop_size);  
        set(h(i), 'DisplayName', sprintf('Population %d age group 2', 2));  
    else
        set(h(i), 'MarkerFaceColor', 'none');
        set(h(i), 'MarkerEdgeColor', cmap_2(i, :));   
        set(h(i), 'LineWidth', 1.5);
        set(h(i), 'MarkerSize', 0.8*pop_size);  
        set(h(i), 'DisplayName', sprintf('Population %d', i));
    end
end

hold on
xline(0, 'k-', 'LineWidth', 1, 'DisplayName', 'x', 'HandleVisibility', 'off'); % Adds a dashed black line at x=0 (Y-axis)
yline(0, 'k-', 'LineWidth', 1, 'DisplayName', 'y', 'HandleVisibility', 'off');
hold off

l = findobj(gcf, 'tag', 'legend');
set(l, 'Location', 'eastoutside');

xlabel('MDS-1');
ylabel('MDS-2');
title('Multidimensional Scaling (MDS)');

fontsize(fontSize,"points")

ax = gca;
ax.Color = [.7, .7, .7, 0.22]; 

end