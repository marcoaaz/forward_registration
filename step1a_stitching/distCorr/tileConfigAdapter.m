
cd 'E:\Justin Freeman collab\Marco Zircon\LayersData\Layer\output_combined_BSE_t-position_withBSE\SIFT_aligned_MIP_std'

fileName = 'TileConfiguration.registered.txt'; %'TileConfiguration.registered.txt'
filetext = fileread(fileName);

% tile002.tif; ; (1190.6957431730725, -2.450216078414541)
expression = [
    '(?<fileName>\S+)'...
    ';\s+;\s+'...
    '\('...
    '(?<x>[-+0-9\.]+)'...
    ',\s*'...  
    '(?<y>[-+0-9\.]+)'...
    '\s*\)'     
    ]; 
parsed_struct = regexp(filetext, expression, 'names');
parsed_table = struct2table(parsed_struct);
% temp_zeros = zeros();
temp_zeros = repmat('0.0', size(parsed_table, 1), 1);
parsed_table1 = addvars(parsed_table, temp_zeros, 'NewVariableNames', {'Layers'});

%%
fileName = 'import_trakem2_registered.txt'; %name for saving
% fileID = fopen(fileName, 'w');
writetable(parsed_table1, fileName, 'Delimiter', 'tab', 'WriteVariableNames', 0);