function [landmarks_double, landmarksPath_output] = Landmarks2Array_2D(landmarksPath, z_value)
% Reads in a landmarks file directly to an array while ignoring landmark
% points marked as 'FALSE'. in_file should be the path to the landmark file
% you want to read in

[root, name, ext] = fileparts(landmarksPath);

landmarks_table = readtable(landmarksPath);
n_landmarks = size(landmarks_table, 1);

%Note: variables are 
% Var1='Name', Var2='Active', 
% Var3='mvg-x', Var4='mvg-y', Var5='fix-x', Var6='fix-y'

%medicine
new_col = ones([n_landmarks, 1])*z_value;
landmarks1 = addvars(landmarks_table, new_col, 'before', 'Var5');
landmarks2 = addvars(landmarks1, new_col, 'after', 'Var6');

rows_to_delete = strcmp(landmarks2{:, 2}, 'FALSE') | strcmp(landmarks2{:, 2}, 'false');
landmarks2(rows_to_delete, :) = [];
landmarks_double = table2array( landmarks2(:, 3:8) );

%saving modified tables in other dir
folderPath1 = strcat(root, '_temp');
mkdir(folderPath1)
landmarksPath_output = fullfile(folderPath1, strcat(name, ext));

writetable(landmarks2, landmarksPath_output, 'WriteVariableNames', false);

end

