function [node_table, edge_table] = matrix_to_edges(matrix_input, varNames, folder1)

correl_mtx_0 = corrcoef(matrix_input);
correl_mtx = abs(correl_mtx_0);
min_val = min(correl_mtx, [], 'all'); %might need adjustment for Gephi

idx = ones(size(correl_mtx)); %mask
low_triangular = ~triu(idx, 0);

ind = find(low_triangular);
[row, col] = ind2sub(size(correl_mtx), ind);
sub = [row, col];
n_edges = length(ind);
n_variables = size(correl_mtx, 1);

sign_cell = cell(n_edges, 1);
table_cell = cell(n_edges, 1);
for i = 1:n_edges
    sub_temp = sub(i, :);
    idx1 = sub_temp(1);
    idx2 = sub_temp(2);
    
    type = "Undirected"; %"Undirected" in Gephi edges
    node1 = idx1;
    node2 = idx2;
    edge_val = correl_mtx(idx1, idx2);
    original_val = correl_mtx_0(idx1, idx2);
    if original_val > 0
        sign_val = "Positive";
    else
        sign_val = "Negative";
    end

    table_cell{i} = table(node1, node2, type, edge_val, sign_val, ...
        'VariableNames', {'Source', 'Target', 'Type', 'Weight', 'Sign'});
end
edge_table = vertcat(table_cell{:});

id_array = [1:n_variables]';
node_table = table(id_array, varNames', ...
    'VariableNames', {'Id', 'Label'});

%% Saving

folder1
file3 = fullfile(folder1, 'node_table.xlsx');
file4 = fullfile(folder1, 'edge_table.xlsx');

writetable(node_table, file3, 'WriteMode','overwrite')
writetable(edge_table, file4, 'WriteMode','overwrite')

end