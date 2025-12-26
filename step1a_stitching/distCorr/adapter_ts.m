function adapter_ts(filepath)

[destDir, ~] = fileparts(filepath);

file1 = fullfile(destDir, 'registered2.txt');
file2 = fullfile(destDir, 'registered3.txt'); %name for saving

table1 = readtable(file1);
tileNames = table1.Var1;
x = table1.Var2;
y = table1.Var3;
n_tiles = size(table1, 1);

%Edit
fileID = fopen(file2, 'w');

fprintf(fileID, '%s\n', '# Define the number of dimensions we are working on');
fprintf(fileID, '%s\n', 'dim = 2');
fprintf(fileID, '\n');
fprintf(fileID, '%s\n', '# Define the image coordinates');

for i = 1:n_tiles
    
    fprintf(fileID, '%s; ; (%.14f, %.14f)\n', tileNames{i}, x(i), y(i));
end

fclose(fileID);

end