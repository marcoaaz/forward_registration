clear
clc

%User input
%scan csv parent (from 'imageRegistration_v7.m')
sourceFolder = 'D:\Justin Freeman collab\Marco Zircon_16bit\prototype2_work\qupath_project\output_test2\project_1-Feb';
intermediateFile_1 = fullfile(sourceFolder, 'registration_intermediateFiles\spot_reg3.csv');  
folder1 = 'E:\Feb-March_2024_zircon imaging\02_John Caulfield_files\CA-24MR_chemical data\puck 1';
file1 = '250328_CA24MR-1_firstpuck_25_UPb_GJ189.xlsx';
file2 = '250328_CA24MR-1_firstpuck_25_TE_GJ189.xlsx';
str = 'UNK';

%Script
filepath1 = fullfile(folder1, file1);
filepath2 = fullfile(folder1, file2);
filepath3 = strrep(filepath1, '.xlsx', '_matlab.xlsx');
filepath4 = fullfile(folder1, 'scan_list_output.xlsx');

%Import
scan_list = readtable(intermediateFile_1, 'VariableNamingRule','preserve'); %scan list parent 

table1 = readtable(filepath1, 'ReadVariableNames',true, ...
    VariableNamingRule='preserve', Sheet='Data');

table2 = readtable(filepath2, 'ReadVariableNames',true, ...
    VariableNamingRule='preserve', Sheet='Data');

%Parse
[table1_subset] = table_data(table1, str);
[table2_subset] = table_data(table2, str);

%Appending laser data
table_output = innerjoin(table1_subset, table2_subset, 'Keys', {'Var1', 'Si29_CPS_mean'});

%medicine: column names are later used to define paths
colnames = table_output.Properties.VariableNames;
colnames_rdy = strrep(colnames, '/', '-'); 
table_output.Properties.VariableNames = colnames_rdy;

%Appending with scan list parent (after two-step registration)
laser_data = innerjoin(table_output, scan_list, 'LeftKeys', {'Var1'}, 'RightKeys', {'newName'});

%saving
write(table_output, filepath3);
write(laser_data, filepath4);
filepath4 %to open in 'prototype_optionA_v2.m' for custom grid sorting

function [table_subset] = table_data(table1, str)

table1(:, all(ismissing(table1)))=[]; %medicine

%interpreter (edit)
idx_from = find(strcmp(table1.Var1, str)) + 1;
idx_blanks = find(strcmp(table1.Var1, ''));

try
    a = find(idx_blanks > idx_from);
    idx_to = idx_blanks(a(1)) - 1;
catch
    idx_to = size(table1, 1);
end

table_subset = table1(idx_from:idx_to, :);

end
