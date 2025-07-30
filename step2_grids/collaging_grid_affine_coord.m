
function [coord_output] = collaging_grid_affine_coord(coord_labelled, bbXYtable_full)        

%The function applies the forward transform (found at each segmented
%object) to the coordinates of the input points (database, label, X, Y) to place them
%in their virtual locations within the merged class grids.

n_points = size(coord_labelled, 1);
coord_output = zeros(n_points, 6, "double");

for i = 1:n_points
    
% for i = 112
    db_input = coord_labelled(i, 1);
    label_input = coord_labelled(i, 2);
    point = coord_labelled(i, 3:4); %double  
        
    %% Metadata

    idx = (bbXYtable_full.Database == db_input) & (bbXYtable_full.Label == label_input);
    
    grain_bb = bbXYtable_full(idx, :);
    
    %classification
    class_input = grain_bb.Class;
    grid_input = grain_bb.Grid;

    %corresponding metadata
    y1 = double(grain_bb.from_grid_h_input); %source grid
    x1 = double(grain_bb.from_grid_w_input);
    y2 = double(grain_bb.to_grid_h_input);
    x2 = double(grain_bb.to_grid_w_input);
    from_grid_h = double(grain_bb.from_grid_h); %merged grid
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

    tform = grain_bb.tform;     
    
    coef = [coef_1; coef_2; coef_3; coef_4];

    %% Local coordinates (WMI bbox) to Class grid coordinates
        
    val = 0.5; %must
    val2 = 0; 
    val3 = -1; %must     
    
    %top left    
    point_local = point - [x1, y1] + val*[1, 1];       
    
    %Similarity transformation  
    n_rows = y2 - y1 + 1; %original
    n_cols = x2 - x1 + 1;    
    size1 = [n_rows, n_cols];
    size2 = [rows_image_affine, cols_image_affine]; %affine    
    
    [point_local_t1] = corners_affine(tform, point_local, size1, size2);       
    
    point_local2 = point_local_t1 + val2*[1, 1]; %affine ROI    

    %Centering operation: top-left within grid tile ROI intersection           
    
    point_local3 = (point_local2 - ...
        [(1-coef(4))*from_x, (1-coef(2))*from_y] + ...
        [(1-coef(3))*from_w, (1-coef(1))*from_h]);     
    
    %Locating within class grid
    point_local4 = point_local3 + [from_grid_w, from_grid_h] + val3*[1, 1];    

    coord_output(i, :) = [class_input, grid_input, label_input, point_local4, db_input]; 

end

disp('Forward transform applied')
end