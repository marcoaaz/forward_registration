function [table_calculations4] = geochemistry_calculation4(data_table, folder_path, script_path)
%Imputation of REE. Following Carrasco-Godoy et al. (2023)
%Criteria for calculation: 
%'Ce', 'Eu' excluded
% HREE included (Lu, Yb, Tm)
% Sm recommended due to uncertainty

minimum_required = {'Nd146', 'Dy163', 'Lu175', 'Yb172'};  %edit

%%
colnames = data_table.Properties.VariableNames;
n_observations = size(data_table, 1);

%Input columns
x_labels_carrasco = {
    'La139', 'Pr141', 'Nd146', 'Gd157', 'Tb159', 'Ho165', 'Er166', ...
    'Tm169', 'Yb172', 'Y89', 'Sm147', 'Lu175', 'Dy163', ...
    'Ce140', 'Eu153'
    };

x_labels = strcat(x_labels_carrasco, '_ppm_mean');
minimum_required2 = strcat(minimum_required, '_ppm_mean'); 

idx_in = contains(colnames, x_labels);
colnames_available = colnames(idx_in);

[idx_available] = ismember(x_labels, colnames_available);

%Output columns
expression2 = '(?<element>[a-zA-Z]+)\d+_ppm_mean';
c = regexp(x_labels, expression2, 'names');
d = [c{:}]; %element name
e = struct2table(d);
colnames_output = e.element;

%data for spyder plot
mtx_requested = data_table{:, idx_in}; 
idx_nan = (mtx_requested < 0);
mtx_requested(idx_nan) = NaN;
table_requested = array2table(mtx_requested);

table_requested.Properties.VariableNames = colnames_output;

id_number = [1:n_observations]';
table_requested2 = addvars(table_requested, id_number, 'Before', 1);

%Extra information (to better understand the estimate)
[required_idx, ~] = ismember(x_labels, minimum_required2);
idx_and = (~idx_nan).*required_idx(idx_available);
total_relevant = sum(idx_and, 2);
total = sum(~idx_nan, 2);

table_requested3 = addvars(table_requested2, total, 'After', 1);
table_requested3 = addvars(table_requested3, total_relevant, 'After', 2);
table_requested3 = sortrows(table_requested3, "total", 'ascend'); %for debugging

%Medicine: mandatory input (enable depending on data quality/unavailability)
% Ho = 0.1*ones(n_observations, 1);
% Tm = 0.1*ones(n_observations, 1);
% Tb = 0.1*ones(n_observations, 1);
% table_requested3 = addvars(table_requested3, Ho, Tm, Tb);

idx_sum = table_requested3.("total_relevant") >= 4; %info
sprintf('There are %.f irrelevant and excluded rows', sum(~idx_sum))

table_requested4 = sortrows(table_requested3, "id_number", 'ascend'); 
%Note: a model won't be calculted for irrelevant rows

filepath = fullfile(folder_path, 'input_Carrasco.csv');
writetable(table_requested4, filepath)


%% Execute R code
%Note: manually edit path

% system('Rscript "C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\test.R" --verbose')

str1 = "Rscript";
str2 = script_path;
str3 = folder_path;

command = strjoin([str1, ' "', str2, '" "', str3 '" --verbose'], '');

[status1, cmdout1] = system(command);
if status1 == 1    
    disp(command)
    disp(cmdout1)
end

%% Reload

table_calculations_R = readtable(fullfile(folder_path, 'output_Carrasco.csv'), ...
    'VariableNamingRule','preserve');
table_calculations4 = removevars(table_calculations_R, 'id_number');

end