function [gridCells] = load_grids_image(gridNames)
%issues:
%cell if >1 length
%not sorted accordingly to filename numbering

if ~iscell(gridNames)
   gridNames = {gridNames};
end

%Load data

n_exports = length(gridNames);
gridCells = cell(1, n_exports);

for i = 1:n_exports %for grids in all classes
    gridCells{i} = imread(gridNames{i});
end

end