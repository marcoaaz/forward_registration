function plot_population_KDEs(interrogation_columns, age_populations, population_stats, population_kde, formal_name)

n_bins = size(population_stats, 1);
n_interrogation = size(population_stats, 2);

%% Plot KDEs

%cosmetics
lineWidth = 6;
alpha_val = .8;
fontSize = 15;

seed = 3;
rng(seed)
cmap1 = hsv(n_bins);
idx1 = randperm(n_bins, n_bins);
cmap2 = [cmap1(idx1', :), repmat(alpha_val, n_bins, 1)];


nB = n_interrogation; %number of plots
nf = ceil(nB^0.5); %distribution of sub-plots
if nf^2 - nB >= nf
    nrows = nf-1;
    ncolumns = nf;
else 
    nrows = nf;
    ncolumns = nf;
end

hFig = figure;
hFig.Position = [459, 43, 1947, 1195];
t = tiledlayout(nrows, ncolumns, "TileSpacing", "compact", 'Padding', 'compact'); %row-wise

for p = 1:n_interrogation
    
    %text
    temp_variable = interrogation_columns{p};
    % temp_variable_short = strrep(temp_variable, '_mean', '');
    temp_variable_short = formal_name{p};

    nexttile 

    for ii = 1:n_bins
        
        str_interval = age_populations{ii}; 
        
        %data  
        sum_population = population_stats{ii, p}{1};
        cell_temp = population_kde{ii, p};
        f1_temp = cell_temp{1};
        xf1_temp = cell_temp{2};
    
        %plot
        cmap_temp = cmap2(ii, :);

        plot(xf1_temp, f1_temp, 'LineWidth', lineWidth, 'Color', cmap_temp, ...
            'DisplayName', str_interval)        
        hold on 

        %Cosmetics       
        grid on        
        
        text_population = sprintf('n = %.f', sum_population);
        title(temp_variable_short, 'Interpreter','none', 'FontSize', fontSize)
    
        ax = gca;
        ax.XAxis.FontSize = fontSize;
        ax.YAxis.FontSize = fontSize;
    end
    hold off   

    XL = get(ax, 'XLim');
    if XL(1) < 0 & ~strcmp(temp_variable, 'lambda_3')
        xlim([0, Inf])
    else
        xlim([XL(1), XL(2)])
    end

end
lg = legend('FontSize', fontSize, 'Interpreter', 'none');
lg.Layout.Tile = 'East';

title(t, 'Population KDEs', 'FontSize', 1.5*fontSize, 'FontWeight', 'bold')
ylabel(t, 'Counts', 'FontSize', fontSize, 'FontWeight', 'bold')

end