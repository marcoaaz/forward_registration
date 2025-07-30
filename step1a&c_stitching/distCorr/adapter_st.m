
function adapter_st(filepath)
%This function saves a 'TileConfiguration.registered.txt' from Stitching
%plugin into a TrakEM2 readable format for input images.

[destDir, ~] = fileparts(filepath);
filetext = fileread(filepath);

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


fileName_output = fullfile(destDir, 'registered1.txt'); %name for saving
% fileID = fopen(fileName, 'w');
writetable(parsed_table1, fileName_output,'Delimiter', 'tab', 'WriteVariableNames', 0);

end