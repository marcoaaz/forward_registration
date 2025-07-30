function [table_calculations3] = geochemistry_calculation3(data_table, folder_path, environment_path)
% Calculate REE pattern coefficients. Following  Anenburg and Williams (2022)

colnames = data_table.Properties.VariableNames;
n_observations = size(data_table, 1);

%Input columns
x_labels_anenburg = {
    'La139', 'Ce140', 'Pr141', 'Nd146', 'Sm147', 'Eu153', 'Gd157', ...
    'Tb159', 'Dy163', 'Ho165', 'Er166', 'Tm169', 'Yb172', ...
    'Lu175'
    };

x_labels = strcat(x_labels_anenburg, '_ppm_mean');
idx_in = contains(colnames, x_labels);

%Output columns
expression2 = '(?<element>[a-zA-Z]+)\d+_ppm_mean';
c = regexp(x_labels, expression2, 'names');
d = [c{:}]; %element name
e = struct2table(d);
colnames_output = e.element;

%Build table
mtx_requested = data_table{:, idx_in}; 
idx_nan = (mtx_requested < 0);%zeroing
mtx_requested(idx_nan) = 0; 
table_requested = array2table(mtx_requested);

table_requested.Properties.VariableNames = colnames_output;

id_number = [1:n_observations]';
table_requested2 = addvars(table_requested, id_number, 'Before', 1);

filepath = fullfile(folder_path, 'input_Anenburg.csv');
writetable(table_requested2, filepath)

%% Execute Python code
%Note: manually edit path

str1 = fullfile(environment_path, "Scripts\python.exe"); %Note: edit with environment name
[script_folder, ~] = fileparts(environment_path);
str2 = fullfile(script_folder, "script_Anenburg.py");
str3 = folder_path;

command = strjoin(['"', str1, '" "', str2, '" --input "', str3 '"'], '');

[status1, cmdout1] = system(command);
if status1 == 1    
    disp(command)
    disp(cmdout1)
end

%% Reload

table_calculations_python = readtable(fullfile(folder_path, 'output_Anenburg.csv'), ...
    'VariableNamingRule','preserve');
table_calculations3 = removevars(table_calculations_python, 'id_number');

end