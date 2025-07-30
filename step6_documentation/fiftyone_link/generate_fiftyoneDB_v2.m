function [db_labels_table, newFolder2] = generate_fiftyoneDB_v2(table_Display, first_numeric, ...
    datasetName, pctOut_colour, destDir)

%% Convenient UMAP colourmap (modifying columns for Embedding plot)

n_cols = size(table_Display, 2);
chemical_range = first_numeric:n_cols; %assuming numbers are last columns

chemical_mtx = table_Display{:, chemical_range};
P = prctile(chemical_mtx, [pctOut_colour, 100-pctOut_colour], 1); %2xn_cols

%Capping (to improve colourmaps)
dim4 = size(chemical_mtx);
chemical_mtx_capped = zeros(dim4, 'double');
for f = 1:dim4(2)
    temp_col = chemical_mtx(:, f);    
    
    %percentiles
    temp_min = P(1, f);
    temp_max = P(2, f);
    
    temp_col(temp_col < temp_min) = temp_min;
    temp_col(temp_col > temp_max) = temp_max;
    
    chemical_mtx_capped(:, f) = temp_col;
end

alternative_output = table_Display; %preallocate
alternative_output{:, chemical_range} = chemical_mtx_capped;

%% Building fiftyone dataset

%Update old image paths
n_rows = size(alternative_output, 1);
array_paths = alternative_output.filename; %

%parse filepath
newA = cellfun(@(x) strsplit(x, '\'), array_paths, 'UniformOutput', false); 
newB = cellfun(@(x) strrep(strrep(x(end-2), 'CL_greyscale', 'CL_RGB'), ...
    'CL(RGB)_greyscale', 'CL(RGB)_colour'), ...
    newA, 'UniformOutput', false); %switch folder
newC = cellfun(@(x) strrep(x(1), 'E:', 'D:'), newA, 'UniformOutput', false); %switch disk

for kk = 1:n_rows
    rep1 = newB{kk}{1}; %replacement 1
    rep2 = newC{kk}{1};

    newA{kk}{1, end-2} = rep1;
    newA{kk}{1, 1} = rep2;
end
array2_paths3 = cellfun(@(x) strjoin(x, '\'), newA, 'UniformOutput', false);

%Move images to DB directory
newFolder2 = fullfile(destDir, datasetName, 'data');
[newFolder1, ~, ~] = fileparts(newFolder2);
mkdir(newFolder2)

dest_files = strings(n_rows, 1);
for jj = 1:n_rows
    str_file = array2_paths3{jj};
    [~, basename, ext] = fileparts(str_file);
    str_file_dest = fullfile(newFolder2, strcat(basename, ext));
    
    dest_files(jj) = str_file_dest;

    %Option 1: copy files (squared patches, not grid)
    copyfile(str_file, str_file_dest); 

    % %Option 2: resize/modify
    % img_temp = imread(str_file);
    % img_temp2 = imresize(img_temp, [28, 28]);
    % imwrite(img_temp2, str_file_dest)

end

%Updated paths
[~, c, d] = fileparts(dest_files); %discard absolute paths
dest_files2 = strcat(c, d);

%Append
alternative_output.filename = [];
db_labels_table = addvars( alternative_output, ...
    [1:n_rows]', dest_files2, ...
    'NewVariableNames', {'sort', 'filepath'}, 'Before', 1);

%Save
writetable(db_labels_table, fullfile(newFolder1, 'labels.csv'));

end