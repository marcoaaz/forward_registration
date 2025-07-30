function [DB_sorted1, populationBand] = sorting_grainDB(stats2, ...
    classifying_variable, n_classes, plotOption)
%Equal population classification (default= Cathodoluminescence intensity)

DB_sorted_in = sortrows(stats2, classifying_variable, 'ascend');

n_grains = size(DB_sorted_in, 1);
populationBand = ceil(n_grains/n_classes);

indices = zeros(n_grains, 1);
for i = 1:n_classes

    from = 1 + populationBand*(i-1);
    if i == n_classes
        
        to = n_grains;
    else
        to = populationBand*i;
    end
    
    indices(from:to) = i;
end

DB_sorted1 = addvars(DB_sorted_in, indices, 'NewVariableNames', 'Group');

%% Plot

if plotOption == 1
    variable = DB_sorted_in{:, classifying_variable}; %intensity (8-bit from QuPath)

    figure
    
    histogram(variable, 'BinLimits', [0, max(variable)]);
    hold on
    line([0, 0], ylim, 'LineWidth', 2, 'Color', 'r');
    for i = 1:n_classes
        line([max(variable(indices == i)), max(variable(indices == i))], ...
            ylim, 'LineWidth', 2, 'Color', 'r');
    end
    title('Classes of equal populations')
    xlabel(classifying_variable, "Interpreter","none")
else
    disp('Activate plot option to see histogram')
end

end