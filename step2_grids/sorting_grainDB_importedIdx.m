function [DB_sorted1, populationBand] = sorting_grainDB_importedIdx( ...
    DB_sorted_in, n_classes)
%Equal population classification (default= Cathodoluminescence intensity)

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

end