function [studiedImage] = collaging_WMI_affine(gridCells, bbXYtable, grid_info, sel_interpolation)

%This function pastes the re-labelled snippets of each grain obtained from
%the segmented class grids and relocates them ('collaging') into their
%original locations in the whole-mount image coordinates. 
%The snippets or patches were labelled in SuperSIAT and re-labelled before
%returning the montage to avoid repeating the labels between segmented
%grids.

%Notes:
%class_grids (unfolded version) = gridCells 
%The remaining issue is the rightwards shift (X-axis) in the reconstructed
%montage
%For imwarp() step, use 'linear'/'cubic' for images & 'nearest' for labels/maps

%Future improvement: 
% It needs fix for precision when registering patches. Modifying the internal
% MatLab function seems to be the way.

%%

DB_sorted = grid_info.DB_sorted;

%Info about grids
info_img = gridCells{1};
channels_grid = size(info_img, 3);

dim_wmi = grid_info.dim_wmi;
mountHeight = dim_wmi(1); %real
mountWidth = dim_wmi(2);
mountChannels = channels_grid; %dim_wmi(3)
inputType = class(info_img); %grid_info.inputType

n_classes = grid_info.n_classes;
bb_width = grid_info.bb_width; %tile within grid
bb_height = grid_info.bb_height;
gridTotal = grid_info.gridTotal;
% dim_grid_tile = [bb_height, bb_width];                

%Reconstruction
indices = DB_sorted.Group;
studiedImage = zeros(mountHeight, mountWidth, mountChannels, inputType);  

w = 0;
for i = 1:n_classes
% for i = 1

    n_grains = sum(indices == i);    
    
    temp_DB = DB_sorted(indices == i, :); %required for instance mask

    index = (bbXYtable.Class == i);
    temp_bbTable = bbXYtable(index, :); 
    temp_labels = temp_bbTable.Label;
    
    for j = 1:n_grains
    % for j = 220        
                
        w = w + 1; %counter
        
        grain_DB = temp_DB(j, :); %follows sorted
        temp_label = grain_DB.Label;
        temp_idx = (temp_labels == temp_label);

        grain_bb = temp_bbTable(temp_idx, :); %full version required                 
        k = grain_bb.Grid;
        
        % k = 1 + floor((j-1)/gridTotal); %grid number
        m = k + (i - 1)*2; %finding grid index 

        sprintf("Processing class: %d, grid: %d, label: %d, loop num.: %d \n", i, k, temp_label, w)                       

        %% Bounding box within class grid
        
        from_grid_h = grain_bb.from_grid_h; %grid
        to_grid_h = grain_bb.to_grid_h;
        from_grid_w = grain_bb.from_grid_w;
        to_grid_w = grain_bb.to_grid_w;
        from_h = grain_bb.from_h; %centering operation
        to_h = grain_bb.to_h;
        from_w = grain_bb.from_w;
        to_w = grain_bb.to_w;
        from_y = grain_bb.from_y;
        to_y = grain_bb.to_y;
        from_x = grain_bb.from_x;
        to_x = grain_bb.to_x;
        rows_image_affine = grain_bb.rows_image_affine; %cropping (after Affine)
        cols_image_affine = grain_bb.cols_image_affine;        
        y1_a = grain_bb.y1_a;
        y2_a = grain_bb.y2_a;
        x1_a = grain_bb.x1_a;
        x2_a = grain_bb.x2_a;

        temp_gridMap = gridCells{m}; %follows GetFileNames sorting        
        temp_tile = temp_gridMap(from_grid_h:to_grid_h, from_grid_w:to_grid_w, :); %adjusted contrast
        
        n_channels2 = mountChannels; %size(temp_tile, 3)
        n_rows2 = y2_a - y1_a + 1;
        n_cols2 = x2_a - x1_a + 1;

        temp_image_affine_ROI = zeros(n_rows2, n_cols2, n_channels2, inputType); %pre-allocate
        temp_image_affine_ROI(from_y:to_y, from_x:to_x, :) = temp_tile(from_h:to_h, from_w:to_w, :);
        
        temp_image_affine = zeros(rows_image_affine, cols_image_affine, n_channels2, inputType); %pre-allocate
        temp_image_affine(y1_a:y2_a, x1_a:x2_a, :) = temp_image_affine_ROI;
        
        %medicine (avoids patch shifting +/- 1 px in reconstruction)
        temp_image_affine = padarray(temp_image_affine, [0 1], 0, 'pre');

        %% Inverse affine transform
               
        % sel_interpolation = 'linear'; %linear

        corners_t1 = grain_bb.corners_t1{1}; %double        
        tform = grain_bb.tform;
        tformInv = invert(tform); %inverse rotation              
        
        A2 = affineOutputView(size(temp_image_affine), tformInv, "BoundsStyle", "FollowOutput"); %best
        temp_image_unwarped = imwarp(temp_image_affine, tformInv, sel_interpolation, "OutputView", A2); %, "OutputView", followOutput
        size1 = size(temp_image_affine);
        size2 = size(temp_image_unwarped);
        
        [corners_t2] = corners_affine(tformInv, corners_t1, size1, size2);
        
        tl_restored = ceil(corners_t2(1, :) + 0.5); % + 0.5 (smaller than it should be)
        br_restored = floor(corners_t2(3, :) - 0.5) + 1; %+1 added (for consistency)    

        temp_image = temp_image_unwarped( ...
            tl_restored(2):br_restored(2), ...
            tl_restored(1):br_restored(1), :);
        
        %test
        % temp_image = padarray(temp_image, [1 1], 0, 'post'); %'post'
       
        %% Bounding box within whole-mount image

        y1 = grain_bb.y1;
        y2 = grain_bb.y2;
        x1 = grain_bb.x1;
        x2 = grain_bb.x2;
        
        %corresponding object binary mask
        temp_binary = grain_DB.Image{1};         
        % temp_binary2 = cat(3, temp_binary, temp_binary, temp_binary);
        temp_binary2 = repmat(temp_binary, [1, 1, channels_grid]);
        
        %corresponding image
        temp_map = studiedImage(y1:y2, x1:x2, :); %sometimes larger 1 px
        
        %% Updating content        

        temp_map(temp_binary2) = temp_image(temp_binary2);

        studiedImage(y1:y2, x1:x2, :) = temp_map; %loop
                       
        % figure,
        % imshowpair(temp_image, test_map, 'falsecolor') %, 'checkerboard'

    end     
end

end