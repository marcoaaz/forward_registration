function [data_full] = read_scancsv(filePath)

[workingDir, fileName, ~] = fileparts(filePath);

fileID = fopen(filePath, 'r');
text_char = fscanf(fileID, '%c');

expression4 = '\n+'; %data with new line char(10)
expression1 = '(?<scanType>\w*),(?<description>.*),(?<selected>\d),(?<lockEdit>\d),(?<vertexCount>\d),(?<vertexList>.*),(?<preablationSettings>.*),(?<ablationSettings>.*),(?<data>.*)';
expression2 = 'Dosage=(?<dosage>\d*);DwellTime=(?<dwellTime>\d+\.?\d*);LineSpacing=(?<lineSpacing>\d+\.?\d*);Laser[.]Output=(?<laserOutput>\d+\.?\d*);Laser[.]Fluence=(?<laserFluence>\d+\.?\d*);LineScanMode=(?<lineScanMode>\d*);PassCount=(?<passCount>\d*);Laser[.]RepRate=(?<laserRepRate>\d+\.?\d*);ScanSpeed=(?<scanSpeed>\d+\.?\d*);PassEnabled=(?<passEnabled>\d*);ShotCount=(?<shotCount>\d*);SpotSpacing=(?<spotSpacing>\d+\.?\d*);Laser[.]SpotSize=(?<laserSpotSize>\w*\s\w*);Laser[.]SpotRotation=(?<laserSpotRotation>\d+\.?\d*);ZDepth=(?<zDepth>\d+\.?\d*)';
expression3 = '(?<x>\d+\.?\d*),(?<y>\d+\.?\d*),(?<z>\d+\.?\d*)';

text_rows = regexp(text_char, expression4, 'split');
header = strsplit(text_rows{1}, ',');
text_rows2 = text_rows(2:end-1);
n_spots = length(text_rows2);

text_cell_one = regexp(text_rows2, expression1, 'names');
text_cell_two = regexp(text_rows2, expression2, 'names');

table_cell = cell(n_spots);
for i = 1:n_spots
    data1 = struct2table(text_cell_one{1, i});
    
    data2_str = data1.vertexList;    
    data2 = struct2table(regexp(data2_str, expression3, 'names'));  
    
    data3 = struct2table(text_cell_two{1, i}(1)); %preablation
    data4 = struct2table(text_cell_two{1, i}(2)); %ablation
    data4_varNames = data4.Properties.VariableNames;
    data4.Properties.VariableNames = strcat(data4_varNames, '2');
    
    table_cell{i} = [data1(:, 1:5), data2, data3, data4];
end
data_full = vertcat(table_cell{:});

%Saving
fileName1 = strcat(fileName, '_table.csv');
fileDest1 = fullfile(workingDir, fileName1);
writetable(data_full, fileDest1)

end