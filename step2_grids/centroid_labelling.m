function [coord_labelled] = centroid_labelling(coord_input, labelled_map2, r)
%function to label coordinate inputs (X, Y) from labelled image

%find point labels
coord_input2 = ceil(coord_input - 0.5); 
coord_labels = labelled_map2(sub2ind( size(labelled_map2), ...
    coord_input2(:,2), coord_input2(:,1)));
coord_labelled = [double(coord_labels), coord_input]; %no Class and Grid
 
%Complete missing labels (medicine), assumes convex objects
idx_missing = (coord_labelled(:, 1) == 0);
search = find(idx_missing);
for i = search'    

    temp = coord_input(i, :);

    %Squared ROI search
    temp_int = ceil(temp - 0.5);
    from_row = temp_int(2) - r;
    to_row = temp_int(2) + r;
    from_col = temp_int(1) - r;
    to_col = temp_int(1) + r;
    
    temp_patch = labelled_map2(from_row:to_row, from_col:to_col, :);
    temp_label = mode(temp_patch, 'all');
    
    coord_labelled(i, 1) = temp_label;
end

end