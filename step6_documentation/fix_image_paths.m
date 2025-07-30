function [alternative_output2] = fix_image_paths(alternative_output, newFolder2)
%Image pathches might have old paths that need to be updated with this
%function. Edit accordingly.

mkdir(newFolder2)

%Information to build fiftyone dataset

n_rows = size(alternative_output, 1);
array_paths = alternative_output.filename; 
alternative_output.filename = [];

%Medicine: Edit old paths
newA = cellfun(@(x) strsplit(x, '\'), array_paths, 'UniformOutput', false); %parse filepath
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

%% Move image patches
dest_files = strings(n_rows, 1);
for jj = 1:n_rows
    str_file = array2_paths3{jj};
    [~, basename, ext] = fileparts(str_file);
    str_file_dest = fullfile(newFolder2, strcat(basename, ext));
    
    dest_files(jj) = str_file_dest;

    % %Option 1: copy files
    % copyfile(str_file, str_file_dest);

    % %Option 2: resize/modify
    % img_temp = imread(str_file);
    % img_temp2 = imresize(img_temp, [28, 28]);
    % imwrite(img_temp2, str_file_dest)

end

%Update paths
[~, c, d] = fileparts(dest_files); %discard absolute paths
dest_files2 = strcat(c, d);

%Label data for building database (includes colourmaps)
alternative_output2 = addvars( alternative_output, dest_files2, ...
    'NewVariableNames', {'filename'}, 'Before', 1); %filepath (default)

end