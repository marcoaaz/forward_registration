function [grid_info, logSheet] = grid_configuration(grid_info, topSize, canvas_aspectR)

%canvas_aspectR: W/H = 16/9 power point; controls nrows (tiles). 
%topSize: maximum allowed size on either grid side.

populationBand = grid_info.populationBand;
bb_height = grid_info.bb_height;
bb_width = grid_info.bb_width;

%Grid configuration
if canvas_aspectR > 1
    topSize_cols = topSize;
    topSize_rows = topSize/canvas_aspectR;
else
    topSize_rows = topSize;
    topSize_cols = topSize*canvas_aspectR;
end

nrows = floor(topSize_rows/bb_height);
ncolumns = floor(topSize_cols/bb_width);
gridTotal = nrows*ncolumns; %patch per grid
nGrids = ceil(populationBand/gridTotal); %grid per class
dim_grid = [nrows*bb_height, ncolumns*bb_width];

grid_cell = cell(1, nGrids);
for k = 1:nGrids
    from = 1 + gridTotal*(k-1);
    to = gridTotal*k;

    grid_reference = zeros(nrows, ncolumns);
    grid_reference(:) = from:to; %linear indexing
    grid_cell{k} = grid_reference; %used in composition
end

grid_info.nrows = nrows; %number of panels
grid_info.ncolumns = ncolumns;
grid_info.gridTotal = gridTotal;
grid_info.nGrids = nGrids;
grid_info.grid_cell = grid_cell;
grid_info.dim_grid = dim_grid;

logSheet = table(bb_width, bb_height, nrows, ncolumns, ...
    'VariableNames', {'tileWidth', 'tileHeight', 'nRows', 'nColumns'}); %readable in Excel


end