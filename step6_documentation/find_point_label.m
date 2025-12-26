function [coord_labelled3, patch_list, i_list] = find_point_label(labelled_map, table_input, r)

%Finds the integer label of the corresponding object underneath a point.

%Function developed for 'backward' registration pipeline (not in the
%'forward' registration paper) Works in concert with
%'grains_cpRegistration_v6.m' script

%Created: 19-Dec-25

dim = size(labelled_map);

coord_input = [table_input.X_reg, table_input.Y_reg]; %double
coord_input2 = int32(ceil(coord_input - 0.5)); %for pixel interrogation

%pixel interrogation
coord_labels = double(labelled_map( sub2ind( dim, ...
    coord_input2(:,2), coord_input2(:,1))));

coord_labelled = [coord_labels, coord_input]; 
%label is used for matching (no Class and Grid)

idx_missing = (coord_labelled(:, 1) == 0);
n_missing = sum(idx_missing, "all")

%Medicine: Find missing labels

patch_list = cell(1, n_missing);
coord_labelled2 = coord_labelled;
search = find(idx_missing)';

i_list = [];
k = 0;
for i = search 
    k = k + 1;

    temp_int = coord_input2(i, :);     
    
    %Search within square
    from_row = temp_int(2) - r;
    to_row = temp_int(2) + r;
    from_col = temp_int(1) - r;
    to_col = temp_int(1) + r;    
    
    %bounding boxes
    patch_list{k} = double([from_row, to_row, from_col, to_col]); %for reuse

    %images 
    temp_patch = labelled_map(from_row:to_row, from_col:to_col, :);
    
    %getting grain label
    temp_label_proposed = mode(temp_patch, 'all'); %smallest most frequent
        
    if temp_label_proposed == 0 %bounding box might be too small        
        
        %Medicine: exclude zero being the mode
        try 
            [counts, groupnames] = groupcounts(temp_patch(:));     
            counts2 = counts(~(groupnames == 0)); %exclude zero
            groupnames2 = groupnames(~(groupnames == 0));
            [~, idx_sort] = sort(counts2, 'descend');

            groupnames3 = groupnames2(idx_sort);
            temp_label = groupnames3(1); %most frequent >0    
            
        catch
            temp_label = 0;
            i_list = [i_list; i, k]; %stubborn list

        end   
    else
        temp_label = temp_label_proposed;

    end
    
    coord_labelled2(i, 1) = temp_label;     
end

coord_labelled3 = array2table(coord_labelled2, ...
    "VariableNames", {'Grain', 'X_reg', 'Y_reg'});

end