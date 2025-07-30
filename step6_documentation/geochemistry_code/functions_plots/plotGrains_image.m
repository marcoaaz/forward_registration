function plotGrains_image(image_reference, x1, y1, label1, x2, y2, label2)
    
%Plot

markerSZ = 15;
fontSize = 10;
colour0 = 'cyan';
colour1 = 'yellow';
colour2 = 'red';

hFig = figure;
hFig.Position = [100, 100, 2300, 1200];
tiledlayout(1, 2);

%Moving
% subplot(1, 2, 1)
nexttile

s1 = scatter(x1, y1, markerSZ, colour0, 'filled', 'Clipping','off');
axis equal
ax = gca;
ax.XDir = 'reverse'; %Chromium is inverted
ax.Color = 'k';

hold on
text(x1, y1, label1, 'horizontal', 'left', 'interpreter', 'none', ...
    'color', colour1, 'FontSize', fontSize)
hold off
title('laser-log')
view([1, 90])

%Fixed
% subplot(1, 2, 2)
nexttile

imshow(image_reference)
hold on
s2 = scatter(x2, y2, markerSZ, colour0, 'filled', 'Clipping','on');
% axis equal

t2 = text(x2, y2, label2, 'horizontal', 'right', 'interpreter', 'none', ...
    'color', colour2, 'clipping', 'on', 'FontSize', fontSize);

hold off
title('segmentation (fixed coordinate system)')

end