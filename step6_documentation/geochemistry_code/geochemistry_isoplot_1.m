function [table_calculations6] = geochemistry_isoplot_1(data_table, folder_path, script_path)
%Save for Isoplot-R. https://github.com/pvermees/IsoplotR?tab=readme-ov-file
%Following Vermeesch P. (2018)

names_isoplot = {
    'Pb207U235', 'sePb207U235', ...
    'Pb206U238', 'sePb206U238', ...
    'Pb207Pb206', 'sePb207Pb206', ...
    'rXY', 'rYZ', ...    
    'comment',...
    };

requested_cols = {
    'Final Pb207-U235_mean', 'Final Pb207-U235_2SE(prop)', ...
    'Final Pb206-U238_mean', 'Final Pb206-U238_2SE(prop)', ...    
    'Final Pb207-Pb206_mean', 'Final Pb207-Pb206_2SE(prop)', ...    
    'rho 206Pb-238U v 207Pb-235U', 'rho 207Pb-206Pb v 238U-206Pb', ...
    'Var1',...
    };


%'rho 206Pb-238U v 207Pb-235U', 'rho 207Pb-206Pb v 238U-206Pb', ...
%x75, y 68, z 76, XY (75 68) YZ (68 76); not sure it is reciprocal

%Not used:
%'Final Pb208-Th232_mean', 'Final Pb208-Th232_2SE(prop)', ...

data_table2 = data_table(:, requested_cols);

%Optional: Search failed ages
% no_signal = [24, 76, 108, 200];
no_signal = [];
spot_array = data_table2.("Var1");

expression1 = 'spot_(?<spot_str>\d+)';
struct1 = regexp(spot_array, expression1, 'names');
struct2 = [struct1{:}];
struct3 = struct2table(struct2);
spot_double = str2double(struct3.spot_str);
[idx_no_signal] = ismember(spot_double, no_signal);

temp1 = strings(size(data_table2, 1), 1); %colour
temp2 = strings(size(data_table2, 1), 1); %omit
temp2(idx_no_signal) = 'x'; %visualised but not calculated

%Append
data_table3 = addvars(data_table2,  temp1, temp2, ...
    'newVariableNames', {'C', 'omit'}, 'Before', 'Var1');

%Rename columns
data_table4 = renamevars(data_table3, requested_cols, names_isoplot);
% data_table4 = renamevars(data_table3, "Var1", "comment");

filepath = fullfile(folder_path, 'input_UPb.csv'); %for Isoplot-R
writetable(data_table4, filepath)

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

table_calculations5 = readtable(fullfile(folder_path, 'output_Age.csv'), ...
    'VariableNamingRule','preserve');

%Medicine
threshold_age = 900; %Ma; same as within 'script_isoplot_v2.R'
temp68 = table_calculations5.("t.68");
temp76 = table_calculations5.("t.76");

idx68 = (temp68 < threshold_age); %cutoff.76
idx76 = (temp68 >= threshold_age);
age_isoplot = zeros(size(temp68), 'double');
age_isoplot(idx68) = temp68(idx68);
age_isoplot(idx76) = temp76(idx76);

table_calculations6 = [table_calculations5, array2table(age_isoplot)];

end