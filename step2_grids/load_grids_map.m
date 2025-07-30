function [gridCells, newMapCells, referenceTable] = load_grids_map(gridNames)

%, mapNames, featureTableNames, fileDest1
n_exports = length(gridNames); %max_class*max_grid

%Load data
gridCells = cell(1, n_exports);
mapCells = cell(1, n_exports);
tableCells = cell(1, n_exports);
array = [];
for i = 1:n_exports %for grids in all classes
    
    file0 = gridNames{i};
    [a, b, c] = fileparts(file0);  

    d = dir (fullfile(a, b, '*.shp')); %avoids typos
    e = dir (fullfile(a, b, '*.tif'));
    file1 = fullfile(d.folder, d.name);
    file2 = fullfile(e.folder, e.name);         
    
    %image
    temp_grid_name = imread(file0);
    image_area = size(temp_grid_name, 1)*size(temp_grid_name, 2);
    
    %Label map (32-bit), objects and classes
    label_maps_SS = imread(file2);

    %index (1= merged bilevel scaleset blocks) (2=  separate blocks)
    label_map = double(label_maps_SS(:, :, 1)); %+ 1 to avoid indexing issues 
    
    %table for relabelling (S not required)
    S = shaperead(file1); %Geometry, BoundingBox, X, Y, FID        
    temp_table = struct2table(S);
    n_objects = size(temp_table, 1);
    
    %Parsing folder names
    temp_str = regexp(b, 'class(?<class>\d+)_grid(?<grid>\d+)', 'names');   
    
    temp_1 = str2double( string( temp_str.class ));
    temp_2 = str2double( string( temp_str.grid ));    
    array = [array; [temp_1, temp_2]];    
    
    temp_table2 = addvars(temp_table, ...
        repmat(temp_1, n_objects, 1), repmat(temp_2, n_objects, 1), ...
        'NewVariableNames', {'Class', 'Grid'}, 'Before', 1);
    
    %Filter background w/ Area
    filter_array = zeros(n_objects, 1, 'logical');
    for k = 1:n_objects
        bb = temp_table2{k, 'BoundingBox'}{1};
        area = prod( bb(2, :) - bb(1, :), 2); %criteria

        filter_array(k) = (area < 0.5*image_area); %filter background
    end
    temp_table3 = temp_table2(filter_array, :);    

    %Store
    gridCells{i} = temp_grid_name;
    mapCells{i} = label_map;
    tableCells{i} = temp_table3;
end
referenceTable = vertcat(tableCells{:}); %appending all tables
referenceTable.NewID = [1:size(referenceTable, 1)]';
size(referenceTable)

%% Relabelling object-based segmentation (< 4 min)
newMapCells = cell(1, n_exports);
for i = 1:n_exports
    
    temp_map = mapCells{i}; 
    temp_newMap = zeros(size(temp_map), 'double'); %finite

    class_val = array(i, 1);
    grid_val = array(i, 2);
    index = (referenceTable.Class == class_val) & (referenceTable.Grid == grid_val);
    temp_referenceTable = referenceTable(index, :);

    for m = 1:sum(index)
        old_label = temp_referenceTable.FID(m);
        new_label = temp_referenceTable.NewID(m);
        
        object_mask = (temp_map == old_label);

        temp_newMap(object_mask) = new_label;
        %the loop requires setting background = 0 for all grids
    end
    newMapCells{i} = temp_newMap;

end

end