clear
clc

%Dependencies
scriptPath1 = 'E:\Feb-March_2024_zircon imaging\05_zircon geochemical data\functions_plots';
addpath(scriptPath1)

%User Input
% file1 = 'D:\Justin Freeman collab\Marco Zircon_16bit\prototype2_work\qupath_project\output_test2\project_16-Apr_1\Final Pb206-U238 age_mean_1\grid_info.mat';
% file1 = 'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row1\project_16-Apr_1\Final Pb206-U238 age_mean_1\grid_info.mat';
% file1 = 'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row2\project_16-Apr_1\Final Pb206-U238 age_mean_1\grid_info.mat';
% file1 = 'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row3\project_16-Apr_1\Final Pb206-U238 age_mean_1\grid_info.mat';
file1 = 'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row4\project_16-Apr_1\Final Pb206-U238 age_mean_1\grid_info.mat';


%% Script 

load(file1)

DB_sorted = grid_info.DB_sorted;
[folder1, basename1, ~] = fileparts(file1);
file2 = fullfile(folder1, 'fused_table.xlsx');


% filter 1
varTypes = varfun(@class, DB_sorted, 'OutputFormat', 'cell');
cell_idx = strcmp(varTypes, 'cell');

colnames = DB_sorted.Properties.VariableNames;

%filter 2
not_to_include = {
    'MinIntensity', 'MaxIntensity', ...
    'knn_', '_reg', 'short_filename', 'pred_', ...
    'Spot', 'X', 'Y', 'Group', ...
    'BoundingBox', 'Centroid', 'AxisLength', 'Orientation', ...    
    '_CPS_', 'PbTotal_ppm'};

not_idx = contains(colnames, not_to_include);

%filter 3 (exact match)
not_to_include2 = {
    'MeanIntensity', 'Perimeter', 'centroid_x', 'centroid_y', 'class_index'    
    };
idx1 = ismember(colnames, not_to_include2);

%filter 4
to_include = {'Var1', 'filename', 'class_index', 'class', 'score', 'sampleName'};
idx2 = ismember(colnames, to_include);

in_idx = ~(cell_idx | not_idx | idx1) | idx2;

DB1 = DB_sorted(:, in_idx);

%filter 5: not quantitative but numeric
to_convert = {'score', 'class_index'}; %'class_index'
str_array = string(DB1{:, to_convert});
extract = array2table(str_array, 'VariableNames', to_convert);
% extract = array2table(num2cell(DB1{:, to_convert}), 'VariableNames', to_convert);

DB1 = removevars(DB1, to_convert);
DB1 = horzcat(DB1, extract);

close all
%Correlation
[DB2, matrix_input, varNames] = plot_correlationMTX(DB1, 0.3, file2);
[node_table, edge_table] = matrix_to_edges(matrix_input, varNames, folder1);

%% Optional: fuse scan areas (puck 2)

files = {
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row1\project_16-Apr_1\Final Pb206-U238 age_mean_1\fused_table.xlsx';
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row2\project_16-Apr_1\Final Pb206-U238 age_mean_1\fused_table.xlsx';
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row3\project_16-Apr_1\Final Pb206-U238 age_mean_1\fused_table.xlsx';
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row4\project_16-Apr_1\Final Pb206-U238 age_mean_1\fused_table.xlsx'

    };

n_files = length(files);
[folder2, ~, ~] = fileparts(files{end}); %save in the last one
file5 = fullfile(folder2, 'fused_all_areas.xlsx');
fused_tables = [];
for i= 1:n_files
    temp_table = readtable(files{i}, 'VariableNamingRule', 'preserve');
    % size(temp_table)
    fused_tables = [fused_tables; temp_table];
end

fused_tables2 = sortrows(fused_tables, 'Var1', 'ascend');
writetable(fused_tables2, file5, "WriteMode","overwritesheet");
file5

%% Optional: fuse samples (pucks)

file6 = strrep(file5, 'areas.xlsx', 'samples.xlsx');
file7 = strrep(file5, 'areas.xlsx', 'samples_WMCNA.xlsx'); 
%for Gephi software WMCNA

files2 = {
    'D:\Justin Freeman collab\Marco Zircon_16bit\prototype2_work\qupath_project\output_test2\project_16-Apr_1\Final Pb206-U238 age_mean_1\fused_table.xlsx';
    file5 %the last one processed/fused
    };

table1 = readtable(files2{1}, 'VariableNamingRule','preserve');
table2 = readtable(files2{2}, 'VariableNamingRule','preserve');

table1.Sample = repmat("puck 1", size(table1, 1), 1);
table2.Sample = repmat("puck 2", size(table2, 1), 1);

%Appending
colnames = table2.Properties.VariableNames;
fused_samples3 = outerjoin(table2, table1, "Keys", colnames, "MergeKeys",true);

%Sorting columns by variable type
fused_samples4 = sortrows(fused_samples3, 'Final Pb206-U238 age_mean', 'ascend');
varTypes3 = varfun(@class, fused_samples4, 'OutputFormat', 'cell');
double_idx = strcmp(varTypes3, 'double');

fused_samples5 = [fused_samples4(:, ~double_idx), fused_samples4(:, double_idx)];

%Filtering for Correlation Graph
colnames2 = fused_samples5.Properties.VariableNames;

not_to_include = {'_2SE', 'rho', 'Final'}; %contains
not_to_include2 = {'Label', 'class_index'}; %exact match
to_include2 = {'Final Pb206-U238 age_mean', 'Final Pb206-U238 age_2SE(prop)'};

idx1 = contains(colnames2, not_to_include);
idx2 = ismember(colnames2, not_to_include2);
idx3 = ismember(colnames2, to_include2);
in_idx = ~(idx1 | idx2) | idx3;

fused_samples6 = fused_samples5(:, in_idx);

%Correlation
[~, matrix_input2, varNames2] = plot_correlationMTX(fused_samples6, 0.3, file2);

varNames3 = strrep(varNames2, '_ppm_mean', '');
varNames4 = strrep(varNames3, 'Final ', '');

folder2 = fullfile(folder1, 'all_samples_WMCNA');
mkdir(folder2)
[node_table2, edge_table2] = matrix_to_edges(matrix_input2, varNames4, folder2);

%Save
writetable(fused_samples5, file6, "WriteMode","overwritesheet"); %for experts
writetable(fused_samples6, file7, "WriteMode","overwritesheet"); %for Gephi correlation graph
file6