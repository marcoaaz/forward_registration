function spot_plotPath(X_sorted, initial_xy, corners, temp_str3)

n_spots2 = size(X_sorted, 1);
pointSize = 30;
fontSize = 9;
text_offset = 50;

hFig = figure('units', 'normalized', 'outerposition', [0 0 1 1]);

plot(X_sorted(1:n_spots2, 1), X_sorted(1:n_spots2, 2), ...
    'x', 'Color', 'black', 'MarkerSize', 20, 'Marker', '.',...
    'DisplayName', 'Spots')

hold on
plot(X_sorted(1:n_spots2, 1), X_sorted(1:n_spots2, 2), ...
    '-', 'Color', [0, 0, 1, 0.4], 'LineWidth', 2, ...
    'DisplayName', 'Optimal path')

plot(corners(:, 1), corners(:, 2), ...
    'x', 'Color', 'red', 'MarkerSize', pointSize*0.8, 'DisplayName', 'available corners')
plot(initial_xy(:, 1), initial_xy(:, 2), ...
    '+', 'Color', 'green', 'MarkerSize', pointSize, 'DisplayName', 'start')
plot([X_sorted(1, 1); X_sorted(end, 1)], ...
    [X_sorted(1, 2), X_sorted(end, 2)], ...
    '.', 'Color', 'magenta', 'MarkerSize', pointSize*1.2, 'DisplayName', 'Start-End')

text(X_sorted(1:n_spots2, 1) + text_offset, X_sorted(1:n_spots2, 2), temp_str3, ...
    "FontSize", fontSize, 'HorizontalAlignment', 'left', 'Color', 'blue')

hold off
grid on
pbaspect([1 1 1])

legend('Location','eastoutside', 'FontSize', fontSize*2)
title('Optimal path with Google OR Tools')

end