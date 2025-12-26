function [intensity_table] = interrogate_spot_area( ...
    table1_labelled, labelled_map, img_cell, img_basename_cell, r)

%Spot area interrogation
%Function to cookie-cut the spot area and measure the intensity

%Input:
%r = radius of squared kernel (in pixels)
%table1_labelled = laser-log table after adding grain labels (Grain, X_reg, Y_reg)
%labelled_map = segmented grains image (labels)
%img_cell = cell containing reference images to interrogate
%img_basename_cell = cell containing 'img_cell' corresponding names.

%Output:
%intensity_table = table containing the measured intensities for the laser
%ablation spot (circle) area (min, max, mean, mode) intersection with the grain.
%When 0 is measured, there is no intersection due to misalignment errors

%Created: 19-Dec-25, Marco Acevedo
%Updated: 


n_img = length(img_cell);
n_spots1 = size(table1_labelled, 1);
array1 = zeros(n_spots1, 1); %common 

stats_4 = [];
for m = 1:n_img
    
    %Load large image
    img_basename = img_basename_cell{m};
    img_reference = img_cell{m};    
    n_channels = size(img_reference, 3);        
    
    stats_3 = [];    
    for i = 1:n_spots1
    
        object = table1_labelled(i, :); %within image   
        temp_label = object.Grain;
        
        %Spot bounding box (square with radius 'r')
        temp = [object.X_reg, object.Y_reg]; %registered centroid
        temp_int = int32(ceil(temp - 0.5));
        from_row = temp_int(2) - r;
        to_row = temp_int(2) + r;
        from_col = temp_int(1) - r;
        to_col = temp_int(1) + r;  
    
        %Extract bounding box
        temp_patch = labelled_map(from_row:to_row, from_col:to_col, :);    
        
        %Masks of the spot-ROI intersect the labelled grain
        mask_label = (temp_patch == temp_label); %spot-ROI
        [mask_spot] = generate_circle_mask(size(temp_patch, 1)); %spot   
        mask = mask_label & mask_spot;    
        array1(i) = sum(mask, "all"); %n_pixels        

        stats_2 = [];
        for k = 1:n_channels
            %Interrogate image
            temp_patch1 = img_reference(from_row:to_row, from_col:to_col, k);           
            
            %object pixels    
            pixels1 = double(temp_patch1(mask)); 
    
            extended_basename = string(sprintf('%s_ch%02d', img_basename, k));            
            stats_1 = calculate_stats(pixels1, extended_basename); %intensity

            stats_2 = [stats_2, stats_1];

        end
        stats_3 = [stats_3; stats_2];        
    
    end
    stats_4 = [stats_4, stats_3];
    
end

%Build table
intensity_table = addvars(stats_4, array1, 'NewVariableNames', 'spot_n_pixels', 'Before', 1);

end