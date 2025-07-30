function [grid_info, logSheet] = grid_configuration_custom(grid_info, nrows, nGrids)

%nrows: number of grid patches/tile rows
%nGrids: number of grids per class

populationBand = grid_info.populationBand;
bb_height = grid_info.bb_height;
bb_width = grid_info.bb_width;
sel_type = grid_info.sel_pattern(1);
sel_order = grid_info.sel_pattern(2);

%Grid configuration
gridTotal = ceil(populationBand/nGrids); %patch per grid (equally sized)
ncolumns = ceil(gridTotal/nrows);
topSize_rows = nrows*bb_height;
topSize_cols = ncolumns*bb_width;

dim_grid = [topSize_rows, topSize_cols];
dim_tiles = [nrows, ncolumns];

grid_cell = cell(1, nGrids);
for k = 1:nGrids
    
    [referenceGrid, tiling_name] = gridNumberer(dim_tiles, sel_type, sel_order);
    
    grid_cell{k} = gridTotal*(k-1) + referenceGrid; %custom indexing           
end
tiling_name %print info

grid_info.nrows = nrows; %number of panels
grid_info.ncolumns = ncolumns;
grid_info.gridTotal = gridTotal;
grid_info.nGrids = nGrids;
grid_info.grid_cell = grid_cell;
grid_info.dim_grid = dim_grid;

logSheet = table(bb_width, bb_height, nrows, ncolumns, ...
    'VariableNames', {'tileWidth', 'tileHeight', 'nRows', 'nColumns'}); %readable in Excel


end