function plotGrains_show(img_reference, fileName, x_reg, y_reg, label1, x2, y2, label2)

%Plot 
markerSZ = 20;
fontSize = 12;


imshow(img_reference)
hold on
%fixed
s2 = scatter(x2, y2, markerSZ, ...
    'red', 'filled', 'Clipping', 'on', 'DisplayName', 'Fixed (segmentation)');
axis equal
t2 = text(x2, y2, label2, 'horizontal', 'right', ...
    'interpreter', 'none', 'color', [1, 0, 0], 'clipping', 'on', ...
    'FontSize', fontSize);

%moving registered
s1 = scatter(x_reg, y_reg, markerSZ, ...
    'green', 'filled', 'Clipping', 'on', 'DisplayName', 'Registered (laser log)');
axis equal
t1 = text(x_reg, y_reg, label1, 'horizontal', 'left', ...
    'interpreter', 'none', 'color', [0, 1, 0], 'clipping', 'on', ...
    'FontSize', fontSize);

hold off
title(sprintf('Registration of %s', fileName), 'Interpreter','none')
legend


end