function [dictionary1] = data_completion(data_table, destDir)
%cannot cope with multicolumn variables
%https://www.mathworks.com/help/matlab/ref/table.splitvars.html

%Append and get stats
Variable = data_table.Properties.VariableNames; 
Type = varfun(@class, data_table,'OutputFormat','cell');

%checking doubles
idx1 = strcmp(Type, 'double');
numeric = real(data_table{:, idx1});
idx_positive = (numeric > 0); %real data

%checking str
idx2 = strcmp(Type, 'cell') | strcmp(Type, 'string');
not_numeric = data_table{:, idx2};
idx_empty = strcmp(not_numeric, "");

real_idx = true(size(data_table)); %pre-allocate
real_idx(:, idx1) = idx_positive;
real_idx(:, idx2) = ~idx_empty;

Availability = round(100*sum(real_idx, 1)/size(data_table, 1), 1);

dictionary1 = table(Variable', Type', Availability', ...
    'VariableNames', {'Variable', 'Type', 'Availability'});

%Save
fileDest1 = fullfile(destDir, 'appended_DB_dictionary.xlsx');
fileDest2 = fullfile(destDir, 'appended_DB.xlsx');

writetable(dictionary1, fileDest1, 'WriteMode', 'overwrite');
writetable(data_table, fileDest2, 'WriteMode', 'overwrite');

end