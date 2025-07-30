function diagram_REE(table_calculations)
% REE spyder diagram

colnames = table_calculations.Properties.VariableNames;

colnames_logical1 = contains(colnames, 'Normalized_fromDB_');
colnames_logical2 = contains(colnames, 'std_');
colnames_logical = colnames_logical1 & ~colnames_logical2;

colnames2 = strrep(colnames(colnames_logical), 'Normalized_fromDB_', '');
colnames2 = strrep(colnames2, 'mean_', '');

%data
y = table_calculations{:, colnames_logical};
x = [1:size(y, 2)] - 1;

%cosmetics
lineWidth_val = 4;
alpha_val = 0.5;
n_lines = size(y, 1);
fontSize = 20;

seed = 1;
rng(seed)
cmap1 = hsv(n_lines);
idx1 = randperm(n_lines, n_lines);
cmap2 = [cmap1(idx1', :), repmat(alpha_val, n_lines, 1)];

%Plot

hFig = figure;
hFig.Position = [100, 100, 1800, 1200];

% plot(x, y, '.-', 'LineWidth', lineWidth_val)
% binscatter(x, y)
% scatter(x, y, 1, 'black', 'filled', ...
%     'MarkerEdgeAlpha', alpha_val, 'LineWidth', lineWidth_val ...
%     )
for i = 1:n_lines
    cmap_temp = cmap2(i, :);

    plot(x, y(i, :), '.-', ...
        'LineWidth', lineWidth_val, Color= cmap_temp, ...
        DisplayName=num2str(i))

    hold on
end

grid on

ax = gca;

set(ax, 'YScale', 'log')
ylim([10^0.01, 10^4])

xticks(x)
xticklabels(colnames2);
ax.XAxis.TickLabelInterpreter = 'none';
ax.XAxis.FontSize = fontSize;
ax.YAxis.FontSize = fontSize;

legend('Location','eastoutside', 'FontSize', fontSize)

%Labels
xlabel('Element')
ylabel('REE (normalised)')
title('REE Spyder diagram: zircon grains', FontSize=fontSize)

hold off
end