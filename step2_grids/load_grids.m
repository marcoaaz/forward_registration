function [gridCells, newMapCells] = load_grids(gridNames, mapNames, ...
    featureTableNames, fileDest1)

%Generate grid filename series (SuperSIAT convention)
B = regexp(featureTableNames,'\d*','Match'); 
Num = zeros(length(B), 2); 
for ii= 1:length(B)
  if ~isempty(B{ii})
      Num(ii, :)=str2double(B{ii}); 
  else
      Num(ii, :)=NaN;
  end
end
max_class = max(Num(:, 1));
max_grid = max(Num(:, 2));
n_exports = size(Num, 1); %max_class*max_grid

%Load data
gridCells = cell(1, n_exports);
mapCells = cell(1, n_exports);
tableCells = cell(1, n_exports);

for i = 1:n_exports %for grids in all classes
    %images
    gridCells{i} = imread(gridNames{i});
    mapCells{i} = imread(mapNames{i});
    
    %table
    opts = detectImportOptions(featureTableNames{i}, "VariableNamingRule", "preserve");
    opts = setvartype(opts, opts.SelectedVariableNames, 'double');
    temp_table = readtable(featureTableNames{i}, opts); 
    temp_table(temp_table.ID == 0, :) = []; %removing ID == 0 (background)
    %temp_table(temp_table.area == 0, :) = []; %Optional: removing '-1.#IO' rows
    
    temp_table.Class(:) = Num(i, 1);
    temp_table.Grid(:) = Num(i, 2);
    tableCells{i} = temp_table;
end

%Reorganizing
referenceTable = vertcat(tableCells{:}); %appending all tables
referenceTable.NewID = [1:size(referenceTable, 1)]';
firstColumns = {'Class', 'Grid', 'ID', 'NewID'};
removedColumns = {'ClassID'}; %redundant
referenceTable = movevars(referenceTable, firstColumns, 'Before', 'mean 1');
referenceTable = removevars(referenceTable, removedColumns);

writetable(referenceTable, fileDest1); %Saving

%Relabelling object-based segmentation (< 4 min)
k = 0;
newMapCells = cell(1, n_exports);
for i = 1:max_class
    for j = 1:max_grid
        k = k + 1;
        temp_map = mapCells{k}; 
        
        index = (referenceTable.Class == i) & (referenceTable.Grid == j);
        temp_referenceTable = referenceTable(index, :);
        for m = 1:sum(index)
            temp_map(temp_map == temp_referenceTable.ID(m)) = temp_referenceTable.NewID(m);
            %the loop requires setting background = 0 for all grids
        end
        newMapCells{k} = temp_map;
    end
end

end