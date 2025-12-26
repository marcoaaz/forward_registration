function plot_spot_RGB_comparison(data_x, data_y, colors, channels)

common_lims = [0, 200]; %edit manually

%Setup Figure and Tiled Layout
figure('Color', 'w', 'Position', [100, 100, 800, 750]);
% Create a 4x4 grid
tlo = tiledlayout(4, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

%Main Scatter Plot (Spans 3x3 at bottom-left)
% We use tiles (5,6,7, 9,10,11, 13,14,15)
ax_main = nexttile(5, [3, 3]); 
hold on;

for i = 1:3
    scatter(data_x{i}, data_y{i}, 10, colors(i,:), 'filled', ...
        'MarkerFaceAlpha', 1, 'DisplayName', channels{i});
end

% 1:1 Reference Line
all_data = [cell2mat(data_x'); cell2mat(data_y')];
ref_lims = [min(all_data), max(all_data)];
plot(ref_lims, ref_lims, '--', 'LineWidth', 1.5, ...
    'HandleVisibility', 'off' , 'Color', [0.5, 0.5, 0.5, 0.5]);

%appereance
grid on;
ax = gca; % Get current axes handle
set(ax, 'Color', [0.9 0.9 0.9]); % Sets the plot area to light gray

xlabel('Segmented grain (mean itensity)');
ylabel('Spot area (mean intensity)');
legend('Location', 'northwest');
axis tight;
axis equal
xlim(common_lims); ylim(common_lims);

%Top Marginal Distribution (X-axis)
% Spans 1x3 at the top
ax_top = nexttile(1, [1, 3]);
hold on;
for i = 1:3
    histogram(data_x{i}, 'FaceColor', colors(i,:), 'EdgeColor', 'none', ...
        'Normalization', 'pdf', 'FaceAlpha', 0.4);

    % KDE Curve
    [f, xi] = ksdensity(data_x{i});
    plot(xi, f, 'Color', colors(i,:), 'LineWidth', 2);
end
set(ax_top, 'XTickLabel', [], 'YTickLabel', []);
% title('Probability Distribution (X and Y)', 'FontWeight','normal');
axis tight;
xlim(common_lims); 

%Right Marginal Distribution (Y-axis)
% Spans 3x1 at the right
ax_right = nexttile(8, [3, 1]);
hold on;
for i = 1:3
    % Using 'Orientation', 'horizontal' to align with the Y-axis of the main plot
    histogram(data_y{i}, 'FaceColor', colors(i,:), 'EdgeColor', 'none', ...
        'Normalization', 'pdf', 'FaceAlpha', 0.4, ...
        'Orientation', 'horizontal');

    % KDE Curve (Flipped for Y-axis)
    [f, yi] = ksdensity(data_y{i});
    plot(f, yi, 'Color', colors(i,:), 'LineWidth', 2);
end
set(ax_right, 'XTickLabel', [], 'YTickLabel', []);
axis tight;
ylim(common_lims);

%Link Axes (zoom)
linkaxes([ax_main, ax_top], 'x');
linkaxes([ax_main, ax_right], 'y');


% Clean up tile 4 (the empty top-right corner)
nexttile(4); axis off;
fontsize(15, "points")

sgtitle('RGB colour comparison with KDE', 'FontWeight', 'bold')

end