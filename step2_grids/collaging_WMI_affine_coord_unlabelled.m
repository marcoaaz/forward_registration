function [coord_output] = collaging_WMI_affine_coord_unlabelled(coord_input, bbXYtable_sub)

%The function applies the inverse transform (found at each segmented
%object) to the coordinates of the unlabelled input points (X, Y) to place them
%in their original locations within the whole-mount image.

%classification = [Class, Grid]

val = 0.5;
array_from_grid_h = double(bbXYtable_sub.from_grid_h) - val; %grid
array_to_grid_h = double(bbXYtable_sub.to_grid_h) + val;
array_from_grid_w = double(bbXYtable_sub.from_grid_w) - val;
array_to_grid_w = double(bbXYtable_sub.to_grid_w) + val;
array2 = [array_from_grid_h, array_to_grid_h, array_from_grid_w, array_to_grid_w];

n_points = size(coord_input, 1);
coord_output = zeros(n_points, 5, "double");

for i = 1:n_points
% for i = 112
    
    point_local4 = coord_input(i, 1:2); %double  
    
    %% Estimating label

    idx_a = (point_local4(2) >= array2(:, 1)) & (point_local4(2) < array2(:, 2)); %row
    idx_b = (point_local4(1) >= array2(:, 3)) & (point_local4(1) < array2(:, 4)); %col
    idx = idx_a & idx_b;
    
    grain_bb = bbXYtable_sub(idx, :);
    label_input = grain_bb.Label;

    %% Metadata    
    
    %classification
    class_input = grain_bb.Class;
    grid_input = grain_bb.Grid;

    %corresponding metadata
    from_grid_h = double(grain_bb.from_grid_h); %grid
    from_grid_w = double(grain_bb.from_grid_w);
    from_h = double(grain_bb.from_h); %centering operation
    from_w = double(grain_bb.from_w);
    from_y = double(grain_bb.from_y);
    from_x = double(grain_bb.from_x);
    coef_1 = double(grain_bb.coef_1);
    coef_2 = double(grain_bb.coef_2);
    coef_3 = double(grain_bb.coef_3);
    coef_4 = double(grain_bb.coef_4);    
    rows_image_affine = double(grain_bb.rows_image_affine); %cropping (after Affine)
    cols_image_affine = double(grain_bb.cols_image_affine);        
    y1_a = double(grain_bb.y1_a);
    x1_a = double(grain_bb.x1_a);    
    tform = grain_bb.tform;
    y1 = double(grain_bb.y1); %WSI
    y2 = double(grain_bb.y2);
    x1 = double(grain_bb.x1);
    x2 = double(grain_bb.x2);
    
    coef = [coef_1; coef_2; coef_3; coef_4];
    tformInv = invert(tform); %inverse rotation      

    %% Class grid coordinates to Local coordinates (WMI bbox)

    val = 0.5; %must
    val2 = 0; 
    val3 = -1; %must  

    point_local3 = point_local4 - [from_grid_w, from_grid_h] - val3*[1, 1];

    point_local2 = (point_local3 + ...
        [(1-coef(4))*from_x, (1-coef(2))*from_y] - ...
        [(1-coef(3))*from_w, (1-coef(1))*from_h]);
     
    point_local_t1 = point_local2 + [x1_a, y1_a] - val2*[1, 1];
    
    %Inverse affine transformation
    n_rows = y2 - y1 + 1; %original
    n_cols = x2 - x1 + 1;    
    
    size1 = [rows_image_affine, cols_image_affine]; %affine   
    size2 = [n_rows, n_cols];

    [point_local] = corners_affine(tformInv, point_local_t1, size1, size2);

    point = point_local + [x1, y1] - val*[1, 1]; 
    
    coord_output(i, :) = [class_input, grid_input, label_input, point];

end

disp('Inverse transform applied')
end