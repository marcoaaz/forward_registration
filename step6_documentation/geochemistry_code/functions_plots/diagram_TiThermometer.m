function diagram_TiThermometer(table_calculations, n_bins, pctOut)

%n_bins: binning spatial resolution. Note that 1000 datapoints is not
%pleasant to see with 50 bins

% pctOut = 0.5;

%% Ti-in-zircon thermometer plot

x = table_calculations{:, "Hf"};
y = table_calculations{:, "Ti-temperature"};

hFig = figure;
hFig.Position = [200, 200, 1200, 900];

binscatter(x, y, 'NumBins', n_bins, 'FaceAlpha', 0.8)
colormap('parula')

hold on

%Following Pizarro et al. 2020
x_min = 7000;
x_max = 14000;
y_min = 550;
y_max = 850;

% Draw rectangle.
x1= x_min;
x2= x_max;
y1= y_min;
y2= y_max;
x_square = [x1, x2, x2, x1, x1];
y_square = [y1, y1, y2, y2, y1];
plot(x_square, y_square, 'r-', 'LineWidth', 3);

% Fertility lines
xline(8750, '--', 'Color', [0, 0, 0, 0.3], 'LineWidth', 5)
yline(750, '--', 'Color', [0, 0, 0, 0.3], 'LineWidth', 5)
hold off
grid on 

%Finding plot limits
P_x = prctile(x, [pctOut, 100-pctOut],"all");
P_y = prctile(y, [pctOut, 100-pctOut],"all");

xlim([P_x(1), P_x(2)])
ylim([P_y(1), P_y(2)])
% xlim([7000, 14000])
% ylim([550, 850])

ax = gca;
ax.GridColor = [0.1, 0.1, 0.1]; 
ax.GridAlpha = 0.8;
set(ax,'TickDir','out');

xlabel('Hf (ppm)')
ylabel('Ti-in-zircon temperature (Celcius)')
title('Granite eutectic temperature after Pizarro et al. (2020, Fig. 5 & Fig. 10 top left)')


end