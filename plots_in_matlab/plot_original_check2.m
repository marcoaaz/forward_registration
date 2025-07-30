function plot_original_check2(mountImage, coord_check)
%containing class and grid

hFig = figure;
ax = gca;

hFig.WindowState = 'maximized'; 

imshow(mountImage) %img_ref_fg2
hold on
%inverse
plot(coord_check(:, 4), coord_check(:, 5),'Color', 'red', ...
    'LineStyle','none', 'Marker','.', 'MarkerSize', 20)
text(coord_check(:, 4), coord_check(:, 5), num2str(coord_check(:, 3)), ...
    "FontSize", 15, "Color", 'red');
hold off

end