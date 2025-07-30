function writeQupathPoints(filepath)

[destDir1, ~, ~] = fileparts(filepath);
table0 = readtable(filepath);

%finding classification
temp_class = table0.class;
temp_grid = table0.grid;
n_classes = max(temp_class);
n_grids = max(temp_grid);

for i = 1:n_classes
    for j = 1:n_grids
        %% Build input
        
        name = sprintf('class%d_grid%', i, j);
        temp_idx = (temp_class == i) & (temp_grid == j);        
        table1 = table0(temp_idx, :);
            

        point = [table1.x, table1.y];
        grain_numeric = table1.label;
        grain1 = strsplit(sprintf('grain_%05.f,', grain_numeric), ','); %    
        grain1(end) = [];    
        color = string(repmat('-65536', [length(grain1), 1]));
        
        %table
        columnNames = {'x', 'y', 'name', 'color '}; %tab at the end (QuPath convention)
        quPath_points = table(point(:, 1), point(:, 2), grain1', color, ...
            'VariableNames', columnNames);
        
        % Saving TSV
        fileName3 = strcat(name, '_points.csv');
        fileName4 = strrep(fileName3, '.csv', '.tsv');
        fileDest3 = fullfile(destDir1, fileName3); %change by *.tsv 
        fileDest4 = fullfile(destDir1, fileName4);    
        
        writecell(columnNames, fileDest3, 'WriteMode', 'append', 'Delimiter', 'tab') %header
        writetable(quPath_points, fileDest3, 'WriteMode', 'append', 'Delimiter', 'tab') %data
        
        %change file extension
        delete(fileDest4) %
        status = copyfile(fileDest3, fileDest4);
        delete(fileDest3)

    end
end

disp('Ready for QuPath load points')

end