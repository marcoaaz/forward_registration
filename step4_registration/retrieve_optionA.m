function [coord_output3] = retrieve_optionA(qupath_dir, bbXYtable_full, destinationFile14)
%Retrieving expert annotations made within Class grids.
%It requires export from special QuPath project folders containing the grid
%annotation exports (following naming convention for regex)

%% Parse QuPath annotation files (*.geojson)

[T3] = collect_pointAnnotations(qupath_dir); %for all contained images

path_temp = T3.path_geojson;
[~, basename, ext] = fileparts(path_temp);
expression1 = '[a-zA-Z]+(?<class>\d+)_[a-zA-Z]+(?<grid>\d+)'; %.tiff
temp_str = regexp(basename, expression1, 'names');
temp_str2 = struct2table([temp_str{:}]);

T4 = addvars(T3, double(temp_str2.class), double(temp_str2.grid), ...
    'NewVariableNames', {'Class', 'Grid'}, 'After','path_geojson');
coord_expert = T4{:, {'x', 'y'}}; %in grid coordinates

%% Loop the grid images (work in progress..)
%Note 1: Option A is normally working with a single large grid (further
%improvements are in progress)

pre_classification = [1, 1]; %search: class, grid

idx1 = (bbXYtable_full.Class == pre_classification(1));
idx2 = (bbXYtable_full.Grid == pre_classification(2));
bbXYtable_sub = bbXYtable_full(idx1 & idx2, :);

%% Montage coordinates

[coord_output3] = collaging_WMI_affine_coord_unlabelled(coord_expert, bbXYtable_sub);
n_annotations = size(coord_output3, 1);

expert_table = array2table([[1:n_annotations]' , coord_output3(:, 3:5)], ...
    "VariableNames", {'Spot', 'Grain', 'X', 'Y'});

%preserving coordinate traceability
expert_table2 = addvars(expert_table, coord_expert(:, 1), coord_expert(:, 2), ...
    'NewVariableNames', {'X_grid', 'Y_grid'});

%Save (all grids of a sample)
writetable(expert_table2, destinationFile14, ...
    'WriteVariableNames', true, 'WriteMode', 'overwritesheet');
destinationFile14

end