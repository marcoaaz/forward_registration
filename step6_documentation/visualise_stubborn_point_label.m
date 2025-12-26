function [table_missing] = visualise_stubborn_point_label(table_input, patch_list, i_list)
%Medicine: visualise missing labels

offset_val = 20; %see wider to understand why is not intersected

close all
n_remaining = size(i_list, 1)

objects_missing = cell(n_remaining, 1);
for m = 1:n_remaining
    %object missing
    objects_missing{m} = table_input(i_list(m, 1), :);

    %enlarge bounding box
    bb = patch_list{i_list(m, 2)};    
    bb1 = bb + offset_val*[-1, 1, -1, 1];
    
    %image
    temp_patch = labelled_map(bb1(1):bb1(2), bb1(3):bb1(4));
    
    %show for quality control
    figure
    imshow(temp_patch, [])
end
table_missing = vertcat(objects_missing{:})
%change equilavent radius and check if still missing

end