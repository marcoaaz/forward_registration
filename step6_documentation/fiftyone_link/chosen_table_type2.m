function [table_UMAP, table_Display, first_numeric] = chosen_table_type2(data_table, path_dictionary, trial_name)
%subset accordingly. The dictionary sorting follows column ordering in B_sorted_in

%Note 1: UMAP changes with input column order. If not satisfied with the order, change it outside this function
%Note 2: The variables to produce the Fish plot followed the Iolite output default
%Note 3: Ages are always first in the Iolite output (default)

%Script
dictionary_table = readtable(path_dictionary, VariableNamingRule="preserve"); %edited by expert
dictionary_table1 = sortrows(dictionary_table, 'Type');
varTypes = dictionary_table1.Type;
varNames = dictionary_table1.Variable;

col2 = strcat(trial_name, '_UMAP');
col1 = strcat(trial_name, '_Display');
val2 = (dictionary_table1{:, col2} == 1);
val1 = (dictionary_table1{:, col1} == 1); 

%Medicine to fix first_numeric (entering percentile rescaling):
string_vals = {
    'Database', 'idx_', 'age_isoplot', ...
    'aspectRatio', 'Convexity', 'MaxFeretDiameter',...
    'MeanIntensity_V'
    }; %, 'age_isoplot', Final Pb206-U238 age_mean
idx_string = contains(varNames, string_vals);

%For UMAP input
% idx_numeric = strcmp(varTypes, 'uint16') | strcmp(varTypes, 'double');
idx_numeric = ~idx_string & (strcmp(varTypes, 'uint16') | strcmp(varTypes, 'double'));
dictionary_table_UMAP = dictionary_table1(idx_numeric & val2, :);

%For fiftyone GUI and UMAP plot colourmap
string_find = find(~idx_numeric & val1);
numeric_find = find(idx_numeric & val1);

col_find = [string_find; numeric_find];
first_numeric = length(string_find) + 1; %fix manually (if failing)

dictionary_table_Display = dictionary_table1(col_find, :);

table_UMAP = data_table(:, dictionary_table_UMAP.Variable);
table_Display = data_table(:, dictionary_table_Display.Variable);

end