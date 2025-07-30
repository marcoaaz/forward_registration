function [temp_tile, centered_corners, coef] = centered_bbox(temp_tile, temp_image_affine_ROI)

%Input:
%temp_tile = pre-allocated image (destination)
%temp_image_affine_ROI = extracted and transformed image (origin)

bb_height = size(temp_tile, 1);
bb_width = size(temp_tile, 2);
temp_rows = size(temp_image_affine_ROI, 1); %bbox_affine(4)
temp_cols = size(temp_image_affine_ROI, 2); %bbox_affine(3)

%% Centering grain on grid tile

cond1 = (temp_cols <= bb_width);
cond2 = (temp_rows <= bb_height);

case1 = cond1 & cond2;
case2 = cond1 & ~cond2; 
case3 = ~cond1 & cond2;
case4 = ~cond1 & ~cond2;

index = [case1, case2, case3, case4];

coef_mtx = [
    0, 1, 0, 1;
    1, 0, 1, 0;
    0, 0, 1, 1;
    1, 1, 0, 0]; 

coef = coef_mtx(:, index);        
%rows= coefficients [h; y; w; x] & cols= cases

%WSI subset
from_x = 1*coef(4) + (1 + abs(floor(temp_cols/2) - floor(bb_width/2)))*(1-coef(4));
to_x = temp_cols*coef(4) + (from_x + bb_width-1)*(1-coef(4));        

from_y = 1*coef(2) + (1 + abs(floor(temp_rows/2) - floor(bb_height/2)))*(1-coef(2));
to_y = temp_rows*coef(2) + (from_y + bb_height-1)*(1-coef(2));

%Grid tile subset
from_w = 1*coef(3) + (1 + abs(floor(bb_width/2) - floor(temp_cols/2)))*(1-coef(3));
to_w = bb_width*coef(3) + (from_w + temp_cols-1)*(1-coef(3));

from_h = 1*coef(1) + (1 + abs(floor(bb_height/2) - floor(temp_rows/2)))*(1-coef(1));
to_h = bb_height*coef(1) + (from_h + temp_rows-1)*(1-coef(1)); 

%Replacing content
temp_tile(from_h:to_h, from_w:to_w, :) = temp_image_affine_ROI(from_y:to_y, from_x:to_x, :);                

centered_corners = [
    from_h, to_h, from_w, to_w; 
    from_y, to_y, from_x, to_x];

end