
function [class_grids, bbXYtable] = slice_WMI_affine(grid_info, studiedImage, ...
    orientation, brightnessOption, pctOut, burnOption)


%Cosmetic 
hexStr = "#CB997E";
colour_textBox = hex2rgb(hexStr);
fontColour = 'white';

%%
DB_sorted = grid_info.DB_sorted;

dim_wmi = grid_info.dim_wmi; %n_rows, n_cols, n_channels
inputType = grid_info.inputType; %8 or 16-bit
if dim_wmi(3) == 1
    burnOption = 0; %default
end

n_classes = grid_info.n_classes;
bb_width = grid_info.bb_width; %tile within grid
bb_height = grid_info.bb_height;
nrows = grid_info.nrows; %number of pannels
ncolumns = grid_info.ncolumns;
gridTotal = grid_info.gridTotal;
nGrids = grid_info.nGrids;
grid_cell = grid_info.grid_cell;

dim_grid_tile = [bb_height, bb_width];                

indices = DB_sorted.Group;

%% Slicing whole-mount image

%pre-allocate
class_grids = cell(1, n_classes); %store mosaic images per class
Mosaic_XY_bb = cell(1, n_classes); %store new bb coordinates

for i = 1:n_classes %for each class    
% for i = 4

    n_grains = sum(indices == i);    
    
    Mosaic_XY_bb_class = cell(1, n_grains); %pre-allocate
    Mosaic_grids = cell(1, nGrids); %pre-allocate grids

    for k = 1:nGrids

        % Mosaic_grids{k} = zeros(nrows*bb_height, ncolumns*bb_width, dim_wmi(3), inputType); 
        Mosaic_grids{k} = 120*ones( ...
            nrows*dim_grid_tile(1), ...
            ncolumns*dim_grid_tile(2), ...
            dim_wmi(3), inputType); 
    end
    
    temp_DB = DB_sorted(indices == i, :);
    
    for j = 1:n_grains %for each grain
    % for j = 20

        k = 1 + floor((j-1)/gridTotal); %grid number

        sprintf("Processing class: %d, grid: %d, grain: %d", i, k, j)
        grain_DB = temp_DB(j, :);        
        
        %% Bounding box within whole-mount image

        bbox = grain_DB.BoundingBox; 
        x1 = ceil(bbox(1)); %top left        
        x2 = floor(x1 + bbox(3)) - 1; %bottom right (-1 to match binary Image)        
        y1 = ceil(bbox(2));
        y2 = floor(y1 + bbox(4)) - 1;
        bbox_step1 = [y1, y2, x1, x2]; 

        temp_image = studiedImage(y1:y2, x1:x2, :); %corresponding image
        
        %corresponding object binary mask
        temp_binary = grain_DB.Image{1};         
        temp_binary2 = repmat(temp_binary, 1, 1, dim_wmi(3));
        % temp_binary2 = cat(3, temp_binary, temp_binary, temp_binary);

        %masking
        temp_image(~temp_binary2) = 0; %second mask (zeroing background)
        n_rows = size(temp_image, 1);
        n_cols = size(temp_image, 2);

        %% Apply similarity transform (A = T*R*S: composed right to left)
        
        angle = grain_DB.Orientation; %X-axis to major-axis [-90, 90]        
        
        switch orientation %[-180, 180>, clockwise        
            case 'vertical'
                val_rotation = angle - 90;
            case 'horizontal'
                val_rotation = angle;
        end

        %image transformation
        val_translation = [0, 0];
        val_scale = 1;
        tform = simtform2d(val_scale, val_rotation, val_translation);        
        
        followOutput = affineOutputView(size(temp_image), tform, "BoundsStyle", "FollowOutput");

        temp_image_affine = imwarp(temp_image, tform, "OutputView", followOutput); %linear interpolation
        temp_binary_affine = imwarp(temp_binary, tform, "OutputView", followOutput);        
        rows_image_affine = size(temp_image_affine, 1);
        cols_image_affine = size(temp_image_affine, 2);
        % figure, imshow(temp_image_affine)
        
        %Frame corners (for 'collaging_WMI_affine.m' reconstruction)        
        val = 0.5;
        tl = [val, val];
        br = [n_cols, n_rows] + val; %+ 0.5

        corners = [tl; [br(1), tl(2)]; br; [tl(1), br(2)]];
        
        size1 = [n_rows, n_cols];
        size2 = [rows_image_affine, cols_image_affine];

        [corners_t1] = corners_affine(tform, corners, size1, size2);
        
        %Bounding box within transformed ROI
        struct_2 = regionprops(temp_binary_affine, 'BoundingBox');                
        bbox_affine = struct_2.BoundingBox; 
        
        y1_a = ceil(bbox_affine(2));
        y2_a = floor(y1_a + bbox_affine(4)) - 1;
        x1_a = ceil(bbox_affine(1)); %top left
        x2_a = floor(x1_a + bbox_affine(3)) - 1; %bottom right (-1 to match binary Image)        
        
        bbox_step2 = [y1_a, y2_a, x1_a, x2_a]; %

        temp_image_affine_ROI = temp_image_affine(y1_a:y2_a, x1_a:x2_a, :);                

        %Pre-allocate new tile (the pre-defined size is empirical)
        temp_tile = zeros(dim_grid_tile(1), dim_grid_tile(2), dim_wmi(3), inputType); 

        [temp_tile, corners_centered, coef] = centered_bbox(temp_tile, temp_image_affine_ROI);       
        
        coef_flat = coef'; %column
        corners_centered2 = reshape(corners_centered.', 1, []); %for saving
        

        %% Editing the content of grid tile
        
        %Readjusting brightness
        switch brightnessOption 
            case 0                           
                % No brightness adjustment. Similar to option 1 in 'extractingBB_labelledWSI_v2.py'
                temp_tile_adjusted = temp_tile;        
            case 1

                %Adjusting brightness (optional). Similar to option 3.
                rangeAdjust = [pctOut, 100-pctOut];
                temp_tile0 = double(temp_tile);
                P = prctile(temp_tile0, rangeAdjust, "all");
                temp_tile2 = rescale(temp_tile0, 0, 255, "InputMin", P(1),"InputMax", P(2));
                temp_tile_adjusted = uint8(temp_tile2);
        end             
               
        %Burning information (red box with grain labels)
        label_no = double(grain_DB.Label);          
        switch burnOption
            case 1             
                
                text_str = [string(label_no)];
                position = [0, 0];                 
                box_color = colour_textBox;
                % fontSize = 25; %px
                fontSize = floor(0.1*min(dim_grid_tile));

                temp_tile_adjusted = insertText(temp_tile_adjusted, position,text_str, ...
                    FontSize= fontSize, TextColor= fontColour, TextBoxColor= box_color, ...
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
            from_grid_w:to_grid_w, :) = temp_tile_adjusted;
        
        %% Respective class-grid-grain-new X-Y (tile top-left corner)
        
        varNames1 = {
            'Class', 'Grid', 'Label', 'y1', 'y2', 'x1', 'x2',...
            'rows_image_affine', 'cols_image_affine', 'y1_a', 'y2_a', 'x1_a', 'x2_a',...
            'from_h', 'to_h', 'from_w', 'to_w', 'from_y', 'to_y', 'from_x', 'to_x',...
            'coef_1', 'coef_2', 'coef_3', 'coef_4', ...
            'from_grid_h', 'to_grid_h', 'from_grid_w', 'to_grid_w'};

        temp_values = [
            i, k, label_no, bbox_step1, ...
            rows_image_affine, cols_image_affine, bbox_step2, ...
            corners_centered2, ...
            coef_flat, ...
            bbox_grid]; %past version: missing X and Y
                
        temp_table = array2table(temp_values, 'VariableNames', varNames1);
        
        corners_t1_cell = cell(1, 1);
        corners_t1_cell{1} = corners_t1;
        temp_table2 = addvars(temp_table, tform, corners_t1_cell, ...
            'NewVariableNames', {'tform', 'corners_t1'});
        
        Mosaic_XY_bb_class{j} = temp_table2;        

    end
    array1 = vertcat(Mosaic_XY_bb_class{:}); %appending

    %storing in master cells
    class_grids{i} = Mosaic_grids;
    Mosaic_XY_bb{i} = array1;

end
bbXYtable = vertcat(Mosaic_XY_bb{:}); %appending

end