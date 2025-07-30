function [class_grids, bbXYtable_merged] = collaging_grid_affine( ...
    merged_gridCells, bbXYtable, grid_info, orientation, sel_interpolation, burnOption)

%This function pastes the re-labelled snippets of each grain obtained from
%the segmented class grids and relocates them ('collaging') into sorted 
% locations in a new merged grid. 

%Note 1: For imwarp() step, use 'linear'/'cubic' for images & 'nearest' for labels/maps
%Note 2: The function follows 'slice_WMI_affine.m' and 'collaging_WMI_affine.m'

%Cosmetic 
hexStr = "#CB997E";
colour_textBox = hex2rgb(hexStr);
fontColour = 'white';

%%

DB_sorted = grid_info.DB_sorted;

%Info about grids
info_img = merged_gridCells{1}{1};
inputType = class(info_img);
channels_grid = size(info_img, 3); %must be consistent
if channels_grid == 1
    burnOption = 0; %default
end

n_classes = grid_info.n_classes;
dim_grid = grid_info.dim_grid; %size of grids to build
bb_width = grid_info.bb_width; %tile within grid
bb_height = grid_info.bb_height;
% nrows = grid_info.nrows; %number of pannels
% ncolumns = grid_info.ncolumns;
gridTotal = grid_info.gridTotal;
nGrids = grid_info.nGrids;
grid_cell = grid_info.grid_cell;

dim_grid_tile = [bb_height, bb_width];     

indices = DB_sorted.Group;

%Re-slicing

%pre-allocate
class_grids = cell(1, n_classes); %store mosaic images per class
w = 0;

for i = 1:n_classes
% for i = 1
    
    n_grains = sum(indices == i);    
        
    Mosaic_XY_bb_class = cell(1, n_grains); %pre-allocate
    Mosaic_grids = cell(1, nGrids); %pre-allocate grids

    for k = 1:nGrids

        % Mosaic_grids{k} = zeros(nrows*bb_height, ncolumns*bb_width, dim_wmi(3), inputType); 
        Mosaic_grids{k} = 120*ones(dim_grid(1), dim_grid(2), channels_grid, inputType); 
    end

    temp_DB = DB_sorted(indices == i, :); %required for instance mask        
    
    temp_bbTable = bbXYtable(indices == i, :); 
    temp_labels = temp_bbTable.Label;
    temp_databases = temp_bbTable.Database;
        
    for j = 1:n_grains
    % for j = 220        
                
        w = w + 1; %counter        
        
        grain_DB = temp_DB(j, :); %follows sorted
        temp_label = double(grain_DB.Label);
        temp_database = double(grain_DB.Database);        
        temp_idx = (temp_labels == temp_label) & (temp_databases == temp_database);
        
        grain_bb = temp_bbTable(temp_idx, :); %full version required                 
        temp_class = grain_bb.Class; %i
        temp_grid  = grain_bb.Grid; %k
                
        m_input = temp_grid + (temp_class - 1)*2; %finding grid index 
        
        k = 1 + floor((j-1)/gridTotal); %grid number        

        % sprintf("Processing database: %d, loop num.: %d \n", temp_database, w)                       

        %% Bounding box within class grid
        
        from_grid_h_input = grain_bb.from_grid_h; %grid
        to_grid_h_input = grain_bb.to_grid_h;
        from_grid_w_input = grain_bb.from_grid_w;
        to_grid_w_input = grain_bb.to_grid_w;
        
        bbox_step1 = [
            from_grid_h_input, to_grid_h_input, ...
            from_grid_w_input, to_grid_w_input];

        temp_gridMap = merged_gridCells{temp_database}{m_input};

        temp_tile_input = temp_gridMap( ...
            bbox_step1(1):bbox_step1(2), ...
            bbox_step1(3):bbox_step1(4), :); %adjusted contrast
        
        input_dim = size(temp_tile_input);
        cond1 = input_dim(1) > input_dim(2); %verticality
        
        %% Custom rotation
        
        switch orientation %[-180, 180>, clockwise        
            
            case 'vertical'
                if cond1
                    val_rotation = 0;
                else
                    val_rotation = 90;
                end
            case 'horizontal'
                if cond1
                    val_rotation = 90;
                else
                    val_rotation = 0;
                end
        end

        %image transformation
        val_translation = [0, 0];
        val_scale = 1;
        tform = simtform2d(val_scale, val_rotation, val_translation);  

        followOutput = affineOutputView(size(temp_tile_input), tform, "BoundsStyle", "FollowOutput");

        temp_tile_input2 = imwarp(temp_tile_input, tform, sel_interpolation, "OutputView", followOutput); %linear interpolation
        rows_image_affine = size(temp_tile_input2, 1);
        cols_image_affine = size(temp_tile_input2, 2);

        %%Pre-allocate new tile (the pre-defined size is empirical)
        temp_tile_output = zeros(dim_grid_tile(1), dim_grid_tile(2), channels_grid, inputType); 
        
        [temp_tile_output, corners_centered, coef] = centered_bbox(temp_tile_output, temp_tile_input2);               

        coef_flat = coef'; %column
        corners_centered2 = reshape(corners_centered.', 1, []); %for saving
        
        %% Editing the content of grid tile
        
        %Burning information (red box with grain labels)
        label_no = double(grain_DB.Label);          
        switch burnOption
            case 0
                
                temp_tile_output2 = temp_tile_output;

            case 1             
                
                text_str = [string(label_no)];
                position = [0, 0];                 
                box_color = colour_textBox;

                temp_tile_output2 = insertText(temp_tile_output, position,text_str, ...
                    FontSize= 45, TextColor= fontColour, TextBoxColor= box_color, ...
                    BoxOpacity= 1); %auto-converts to 3-channel
            
        end

        %% Bounding box within grid image
        
        [index_r, index_c] = find(grid_cell{k} == j);

        from_grid_h = 1 + bb_height*(index_r - 1);
        to_grid_h = bb_height*index_r;
        from_grid_w = 1 + bb_width*(index_c - 1);
        to_grid_w = bb_width*index_c;
        
        bbox_grid = [from_grid_h, to_grid_h, from_grid_w, to_grid_w];   

        %% Replacement

        Mosaic_grids{k}(from_grid_h:to_grid_h, ...
            from_grid_w:to_grid_w, :) = temp_tile_output2;

        %% Respective class-grid-grain-new X-Y (tile top-left corner)     

        varNames1 = {
            'Class', 'Grid', 'Database', 'Label', ...
            'rows_image_affine', 'cols_image_affine', ...
            'from_grid_h_input', 'to_grid_h_input', 'from_grid_w_input', 'to_grid_w_input',...            
            'from_h', 'to_h', 'from_w', 'to_w', 'from_y', 'to_y', 'from_x', 'to_x',...
            'coef_1', 'coef_2', 'coef_3', 'coef_4', ...
            'from_grid_h', 'to_grid_h', 'from_grid_w', 'to_grid_w'};

        temp_values = [
            i, k, temp_database, temp_label, ...
            rows_image_affine, cols_image_affine, ...
            bbox_step1, ...            
            corners_centered2, ...
            coef_flat, ...
            bbox_grid]; %past version: missing X and Y
        
        temp_table = array2table(temp_values, 'VariableNames', varNames1);
        
        temp_table2 = addvars(temp_table, tform, ...
            'NewVariableNames', {'tform'});       
        
        Mosaic_XY_bb_class{j} = temp_table2;        

        %%

        % figure,
        % imshowpair(temp_image, test_map, 'falsecolor') %, 'checkerboard'

    end    
    array1 = vertcat(Mosaic_XY_bb_class{:}); %appending

    %storing in master cells
    class_grids{i} = Mosaic_grids;
    Mosaic_XY_bb{i} = array1;
end
bbXYtable_merged = vertcat(Mosaic_XY_bb{:}); %appending

end