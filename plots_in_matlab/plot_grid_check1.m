function plot_grid_check1(class_grids, coord_output, sel1, sel2)
%with class and grid

idx1 = (coord_output(:, 1) == sel1);
idx2 = (coord_output(:, 2) == sel2);
idx = idx1 & idx2;
coord_subset = coord_output(idx, :);

figure,
imshow(class_grids{sel1}{sel2})
hold on
plot(coord_subset(:, 4), coord_subset(:, 5),'Color', 'yellow', ...
    'LineStyle','none', 'Marker','.', 'MarkerSize', 20)
text(coord_subset(:, 4), coord_subset(:, 5), num2str(coord_subset(:, 3)), ...
    "FontSize", 10, "Color", 'red');
hold off

end