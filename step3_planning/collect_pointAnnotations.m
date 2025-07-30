function [T3] = collect_pointAnnotations(qupath_dir)

destDir = fullfile(qupath_dir, 'geojson_csv');
mkdir(destDir)

%Grids (assumes names are sorted)
structure_temp = struct2table(dir(fullfile(qupath_dir, '*.geojson')));
folder_temp = fullfile(structure_temp.folder, structure_temp.name); %cell if >1 length
% file_temp = structure_temp.name;

%medicine
if ischar(folder_temp)
    test = convertCharsToStrings(folder_temp);
    folders_temp = cellstr(test);
else
    folders_temp = folder_temp;
end

n_files = length(folders_temp);

cell1 = cell(n_files, 1);
for i = 1:n_files

    annotationsFile = string(folders_temp{i});

    cell1{i} = parseQupathPoints(annotationsFile, destDir);   
    
end
T3 = vertcat(cell1{:});

end