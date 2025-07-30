
function [grid_info] = save_burned_patches(grid_info, class_grids, bbXYtable_merged, ...
    prev_coord_output, prev_spot_info, spot_diameter, spotOption, labelOption, destinationFolder2)
%Note: ImageJ > Cannot be re-saved in JPG if topSize > 65500

mkdir(destinationFolder2)

%Edit
spot_radius = spot_diameter/2;
n_steps = 30; %points for drawing spots

%Import
DB_sorted = grid_info.DB_sorted;
n_patches_total = size(DB_sorted, 1);

n_classes = grid_info.n_classes;
nGrids = grid_info.nGrids;
dim_grid = grid_info.dim_grid;
n_rows1 =  dim_grid(1); %assumes similar grids
n_cols1 =  dim_grid(2);

m = 0;
grid_files = cell(1, n_patches_total);
for i = 1:n_classes    
    for j = 1:nGrids        
        
        %Image
        classImage = class_grids{i}{j}; %class grids (uint16)
        
        %Spots (in merged grid coordinates)
        idx = (prev_coord_output(:, 1) == i) & (prev_coord_output(:, 2) == j);
        output_table = prev_coord_output(idx, :); %class, grid, grain, x, y, database
        text_str = prev_spot_info(idx); %info
        n_holes = size(output_table, 1);

        temp_image = classImage;
        
        if spotOption == 1

            mask_2D = zeros(n_rows1, n_cols1, 'logical');        
            position = [];  
            reach = n_holes; %n_holes
            for k = 1:reach 
            
                x_temp = output_table(k, 4);
                y_temp = output_table(k, 5);                       
                    
                %Spot mask            
                theta = linspace(0, -360, n_steps);    
                factor = 0.9; %circumference thickness
                x1 = factor*spot_radius * cosd(theta) + x_temp; %interior
                y1 = factor*spot_radius * sind(theta) + y_temp;                       
                x2 = spot_radius * cosd(theta) + x_temp;  %exterior
                y2 = spot_radius * sind(theta) + y_temp;  
                mask1 = poly2mask(x1, y1, n_rows1, n_cols1);         
                mask2 = poly2mask(x2, y2, n_rows1, n_cols1);     
                mask = mask2 & ~mask1;
                %circumference
                mask_2D = mask_2D | mask;
                    
                position = [position; [x_temp, y_temp]];             
            end
    
            %Drawing spots
            n_pixels = sum(mask_2D, 'all');
            mask_3D = repmat(mask_2D, [1, 1, 3]);
            a = repmat(reshape([255, 255, 0], 1, 1, 3), n_pixels, 1); %yellow = [255, 255, 0]
            temp_image(mask_3D) = a(:);
            
        elseif spotOption == 0
            disp('Spots will not drawn in patches')
        end
        
        %Burn text
        if labelOption == 1 %most time consuming, 3 to 12 min
            box_color = {"black"};
            temp_image2 = insertText( temp_image, position, text_str(1:reach), ...
                FontSize= 35, TextColor= "white", ...
                TextBoxColor= box_color, BoxOpacity= .7);

        elseif labelOption == 0
            temp_image2 = temp_image;
        end

        %% Split in patches
        %assumes same order as grid patches

        temp_class = bbXYtable_merged.Class;
        temp_grid = bbXYtable_merged.Grid;
        idx_bb = (temp_class == i) & (temp_grid == j);
        n_patches = sum(idx_bb);

        DB_sorted_sub = DB_sorted(idx_bb, :); %contains filenames
        bbXYtable_sub = bbXYtable_merged(idx_bb, :); %grid bounding boxes        
        
        %filename
        [~, basename_array, ext_array] = fileparts(DB_sorted_sub.filename);
        filename_array = strcat(basename_array, ext_array);
        
        from_grid_h = double(bbXYtable_sub.from_grid_h); %merged grid        
        to_grid_h = double(bbXYtable_sub.to_grid_h); 
        from_grid_w = double(bbXYtable_sub.from_grid_w);        
        to_grid_w = double(bbXYtable_sub.to_grid_w);
        
        for p = 1:n_patches
            m = m + 1;
            
            temp_filename = fullfile(destinationFolder2, filename_array{p});
            grid_files{m} = temp_filename;            

            temp_patch = temp_image2( ...
                from_grid_h(p):to_grid_h(p), ...
                from_grid_w(p):to_grid_w(p), :);
            %issue: the larger the image, the slower it gets            

            %Save
            imwrite(temp_patch, temp_filename)        
        end

    end     
end
grid_info.patch_files_burned = grid_files;

end