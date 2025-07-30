function plotGrains(x1, y1, label1, x2, y2, label2)
    
%Plot
markerSZ = 15;
fontSize = 10;

hFig = figure;
hFig.Position = [100, 100, 2300, 1200];

subplot(1, 2, 1)
s1 = scatter(x1, y1, markerSZ, 'blue', 'filled', 'Clipping','off');
axis equal
ax = gca;
ax.XDir = 'reverse'; %Chromium is inverted
hold on
text(x1, y1, label1, 'horizontal', 'left', 'interpreter', 'none', ...
    'color', [0.3, 0.3, 0.3], 'FontSize', fontSize)
hold off
title('laser-log')
view([1, 90])

subplot(1, 2, 2)
s2 = scatter(x2, y2, markerSZ, 'red', 'filled', 'Clipping','on');
axis equal
hold on
t2 = text(x2, y2, label2, 'horizontal', 'right', 'interpreter', 'none', ...
    'color', [0.3, 0.3, 0.3], 'clipping', 'on', 'FontSize', fontSize);

hold off
title('segmentation (fixed coordinate system)')

end