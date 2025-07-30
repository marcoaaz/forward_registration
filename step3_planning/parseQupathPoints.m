
function [table_output] = parseQupathPoints(annotationsFile, destDir)
%Description:
%Function to parse qupath annotation metadata (from geojson file) as a
%table. It is dedicated to point annotations. 
% Created: Marco Acevedo, 21-Mar-24

annotationsFile = string(annotationsFile); %fix char
[~, fileName, ~] = fileparts(annotationsFile);

%Parse annotation metadata
S = fileread(annotationsFile);
outStruct = jsondecode(S);

n_annotations = length(outStruct.features);

type = strings(n_annotations, 1);
coordinate = cell(n_annotations, 1);
objectType = strings(n_annotations, 1);
name = strings(n_annotations, 1);
color = cell(n_annotations, 1);
metadata = strings(n_annotations, 1);

for i = 1:n_annotations
    
    objectType(i) = outStruct.features(i).properties.objectType; %annotation/detection    
    type(i) = outStruct.features(i).geometry.type; %point, LineString, MultiPolygon
    
    coordinate{i} = outStruct.features(i).geometry.coordinates; %x, y; all available    
    
    try
        name(i) = outStruct.features(i).properties.name; %edited name (might be empty)
    catch
        name(i) = '';
    end
    try
        color{i} = outStruct.features(i).properties.color; %edited name (might be empty)
    catch
        color{i} = [255; 0; 0]; %red (QuPath default)
    end
    
    try
        metadata{i} = outStruct.features(i).properties.metadata.ANNOTATION_DESCRIPTION; %edited description (might be empty)
    catch
        metadata{i} = '';
    end
end
colorTriplet = [color{:}]';
T = table(name, objectType, type, coordinate, colorTriplet, metadata); %, 'VariableTypes', varTypes
T = splitvars(T);

%% Collecting Points

idx_1 = strcmp(T.type, 'Point');
n_points = sum(idx_1);

path_table = table(repmat(annotationsFile, n_points, 1), 'VariableNames', {'path_geojson'}); 
T1 = [path_table, T(idx_1,:)];

coord_mat = reshape(cell2mat(T1.coordinate), 2, n_points)'; %qupath ; convention
table_points = addvars(T1, coord_mat(:, 1), coord_mat(:, 2), ...
    'NewVariableNames', {'x', 'y'}, 'Before', 'colorTriplet_1');
table_points.coordinate = [];


%% Collecting Multi-points

idx_2a = strcmp(T.type, 'MultiPoint');
idx_2b = isempty(T.coordinate);
idx_2 = idx_2a & idx_2b;
n_mpoints = sum(idx_2);

path_table = table(repmat(annotationsFile, n_mpoints, 1), 'VariableNames', {'path_geojson'}); 
T1 = [path_table, T(idx_2,:)];

temp_cell = cell(n_mpoints, 1);
for j = 1:n_mpoints

    T2 = T1(j, :);
    coord_mat = cell2mat(T2.coordinate);
    n_included = size(coord_mat, 1);
    
    T3 = repelem(T2, n_included, 1);
    T3.coordinate = [];
    T4 = addvars(T3, coord_mat(:, 1), coord_mat(:, 2), ...
        'NewVariableNames', {'x', 'y'}, 'Before', 'colorTriplet_1');
    
    temp_cell{j} = T4;
end
table_mpoints = vertcat(temp_cell{:});

%% Save CSV (as intermediate file)

%appending
table_output = vertcat(table_points, table_mpoints);

fileName3 = strcat(fileName, '.csv');
fileDest3 = fullfile(destDir, fileName3); 
delete(fileDest3) %dont overwrite

columnNames = table_output.Properties.VariableNames;
writecell(columnNames, fileDest3, 'WriteMode', 'append', 'Delimiter', ',')
writetable(table_output, fileDest3, 'WriteMode', 'append', 'Delimiter', ',')

end