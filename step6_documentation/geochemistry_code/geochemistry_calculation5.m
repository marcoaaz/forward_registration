function [table_calculations5] = geochemistry_calculation5(data_table, folder_path, environment_path)
% Calculate CLR compositions following Aitchison (1984)

colnames = data_table.Properties.VariableNames;
n_observations = size(data_table, 1);

%Input columns
idx_in = contains(colnames, '_ppm_mean');
idx_out = contains(colnames, 'PbTotal');
idx_participate = idx_in & ~idx_out;
colnames_output = data_table(:, idx_participate).Properties.VariableNames;

%Build table
mtx_requested = data_table{:, idx_participate}; 
mtx_requested1 = mtx_requested; %pre-allocate

%capping based on zircon std 91500 La ppm (micrograms/gram) = 5 ppb
%due to the analysed gas background data reduction artefact
capping_val = 0.005; 
idx_negative = (mtx_requested <= capping_val); 
mtx_requested1(idx_negative) = capping_val; 

table_requested = array2table(mtx_requested1);
table_requested.Properties.VariableNames = colnames_output;
id_number = [1:n_observations]';
table_requested2 = addvars(table_requested, id_number, 'Before', 1);

filepath = fullfile(folder_path, 'input_CLR.csv');
writetable(table_requested2, filepath)

%% Execute Python code
%Note: manually edit path

str1 = fullfile(environment_path, "Scripts\python.exe");
[script_folder, ~] = fileparts(environment_path);
str2 = fullfile(script_folder, "script_CLR.py");
str3 = folder_path;

command = strjoin(['"', str1, '" "', str2, '" --input "', str3 '"'], '');

[status1, cmdout1] = system(command);
if status1 == 1    
    disp(command)
    disp(cmdout1)
end

%% Reload

table_calculations5 = readtable(fullfile(folder_path, 'output_CLR.csv'), ...
    'VariableNamingRule','preserve');

end