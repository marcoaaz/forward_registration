function plot_population_histograms(age_populations, population_stats, population_kde, formal_name)

n_bins = size(population_stats, 1);
n_interrogation = size(population_stats, 2);

%% Plot histograms

fontSize= 15;
lineWidth = 4;

hFig = figure;
hFig.Position = [459, 43, 1947, 1195];
t = tiledlayout(n_bins, n_interrogation,"TileSpacing","compact", 'Padding','compact'); %row-wise

for ii = 1:n_bins
    for p = 1:n_interrogation
        
        %text
        temp_variable = formal_name{p};
        % temp_variable = interrogation_columns{p};
        % temp_variable = strrep(temp_variable, '_mean', '');
        str_interval = age_populations{ii}; 
        
        %data
        sum_population = population_stats{ii, p}{1};
        counts = population_stats{ii, p}{2}(1, 2:end);
        edges = population_stats{ii, p}{2}(2, :);           

        cell_temp = population_kde{ii, p};
        f1_temp = cell_temp{1};
        xf1_temp = cell_temp{2};

        %plot
        nexttile
        histogram('BinEdges', edges,'BinCounts', counts) %, 'Normalization','probability'
        hold on        

        plot(xf1_temp, f1_temp, 'LineWidth', lineWidth, 'Color', 'black')
        hold off

        %Cosmetics       
        grid on
        
        title(sprintf('n = %.f', sum_population))
        %Axis labels
        if ii == n_bins
            xlabel(temp_variable, 'FontSize', fontSize*.8, 'Interpreter', "none", 'FontWeight','bold');
        end
        if p == 1           
            ylabel(str_interval,'FontSize', fontSize*.8, 'Interpreter', "none", 'FontWeight','bold');
        end
    
        ylim([0, Inf])        
        xlim([edges(1), edges(end)])

    end
end
title(t,'Population histograms and KDE','FontSize', fontSize, 'FontWeight', 'bold')
ylabel(t,'Counts','FontSize', fontSize, 'FontWeight', 'bold')

end