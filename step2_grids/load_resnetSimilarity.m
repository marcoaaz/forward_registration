function [sorting_table4, resnet_status] = load_resnetSimilarity(filename_9)
%Option: Adding ResNet50 feature vectors sorted by k-NN similarity (from Python)
%pre-requisite: run 'classifyFolder_wVectors_v4.ipynb'

try
    sorting_table = readtable(filename_9, 'VariableNamingRule','preserve');
    
    %parse grain number
    path_temp = sorting_table.filename; 
    [~, basename9, ~] = fileparts(path_temp);
    expression9 = '.+_(?<grain>\d+)_\[.+\]';
    temp_str = regexp(basename9, expression9, 'names');
    temp_str2 = struct2table([temp_str{:}]);
    sorting_table2 = addvars(sorting_table, double(string(temp_str2.grain)), ...
        'NewVariableNames', {'grain'}, 'Before', 1);
    
    %medicine: rectify idx_knn_#
    varNames = sorting_table2.Properties.VariableNames;
    varIdx_1 = contains(varNames, 'vector_'); %not used
    varIdx_2 = contains(varNames, 'idx_knn_');
    varIdx = ~(varIdx_1 | varIdx_2);
    sorting_table3 = sorting_table2(:, varIdx); %used
    
    knn_mtx = sorting_table2{:, varIdx_2} + 1; %python table row idx
    grain_array = sorting_table3.grain;
    n_sorted = length(grain_array);
    knn_mtx_update = zeros(size(knn_mtx), 'double');
    for i = 1:n_sorted
        temp_grain = grain_array(i);
        replacement_mask = (knn_mtx == i);
        knn_mtx_update(replacement_mask) = temp_grain;
    end
    knn_cols = strcat('knn_', string(1:n_sorted-1));
    knn_table = array2table(knn_mtx_update, 'VariableNames', knn_cols);
    
    sorting_table4 = [sorting_table3, knn_table]; %uses grain numbers
    
    resnet_status = 1;
catch ME
    
    display(ME.message);
    resnet_status = 0;
    sorting_table4 = [];
end

end