function bivariate_element_plot(x, y, n_bins, label_x, label_y, plotOption)

pctOut = 1;
markerSize = 30;
fontSize = 20;

%Percentile
P_x = prctile(x, [pctOut, 100-pctOut]);
P_y = prctile(y, [pctOut, 100-pctOut]);

%Capping
x(x < P_x(1)) = P_x(1);
x(x > P_x(2)) = P_x(2);
y(y < P_y(1)) = P_y(1);
y(y > P_y(2)) = P_y(2);



%Plot
hFig = figure;
hFig.Position = [150, 150, 1200, 1000];

switch plotOption
    case 1 
        %Point colourmap
        [N, Yedges, Xedges]  = histcounts2(y, x, [n_bins, n_bins]);
        
        val1 = ceil(rescale(x, 0, n_bins, 'InputMin', Xedges(1), 'InputMax', Xedges(end)));
        val2 = ceil(rescale(y, 0, n_bins, 'InputMin', Yedges(1), 'InputMax', Yedges(end)));
        
        idx_nan = isnan(x) | isnan(y);
        pos = [val1(~idx_nan), val2(~idx_nan)];
        ind_1 = sub2ind(size(N), pos(:, 2), pos(:, 1));
        density_array = N(ind_1);
        
        c = nan(size(x));
        c(~idx_nan) = density_array;

        scatter(x, y, markerSize, c, 'filled')
        colormap("turbo")
        colorbar
        
        grid on
        xlabel(label_x, 'Interpreter','none', FontSize=fontSize);
        ylabel(label_y, 'Interpreter','none', FontSize=fontSize);
        xlim([P_x(1), P_x(2)]) %[0, 100]
        ylim([P_y(1), P_y(2)]) %[0, 4]


    case 2        
        binscatter(x, y, n_bins)
        colormap("turbo")
        grid on
        xlabel(label_x, 'Interpreter','none', FontSize=fontSize);
        ylabel(label_y, 'Interpreter','none', FontSize=fontSize);
        xlim([P_x(1), P_x(2)]) %[0, 100]
        ylim([P_y(1), P_y(2)]) %[0, 4]

    case 3        
        plot(x, y, '.', 'MarkerSize', markerSize)
        grid on
        xlabel(label_x, 'Interpreter','none', FontSize=fontSize);
        ylabel(label_y, 'Interpreter','none', FontSize=fontSize);
        xlim([P_x(1), P_x(2)]) %[0, 100]
        ylim([P_y(1), P_y(2)]) %[0, 4]

    case 4        
        
        nbins= n_bins*[1 1]; %150
        [N, C] = hist3([y, x], nbins);
        contourf(C{2}, C{1}, N, 'FaceAlpha', 0.5)
        grid on
        xlabel(label_x, 'Interpreter','none', FontSize=fontSize);
        ylabel(label_y, 'Interpreter','none', FontSize=fontSize);
        xlim([P_x(1), P_x(2)]) %[0, 100]
        ylim([P_y(1), P_y(2)]) %[0, 4]



end