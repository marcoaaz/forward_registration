
function [grid_info] = save_burned_grids(grid_info, class_grids, ...
    prev_coord_output, prev_spot_info, spot_diameter, suffix, labelOption)

%ImageJ > Cannot be re-saved in JPG if topSize > 65500

format = '.tiff';
spot_radius = spot_diameter/2;
fontSize = 15; %35, 60 (paper)
%Note: fontSize improvement opportunity checking slide_WMI_affine.m

n_classes = grid_info.n_classes;
nGrids = grid_info.nGrids;
destinationFolder = grid_info.dest_folder_grid;
dim_grid = grid_info.dim_grid;
n_rows1 =  dim_grid(1); %assumes similar grids
n_cols1 =  dim_grid(2);

n_steps = 30; %points for drawing spots

m = 0;
grid_files = cell(1, n_classes*nGrids);
for i = 1:n_classes    
    for j = 1:nGrids
        m = m + 1;
        
        %Image
        classImage = class_grids{i}{j}; %class grids (uint16)                

        fileName1 = strcat('class', num2str(i), '_grid', num2str(j), ...
            '_', suffix, format);        
        destinationFile1 = fullfile(destinationFolder, fileName1);
        grid_files{m} = destinationFile1;
        
        %Spots
        idx = (prev_coord_output(:, 1) == i) & (prev_coord_output(:, 2) == j);
        output_table = prev_coord_output(idx, :); %class, grid, grain, x, y
        text_str = prev_spot_info(idx); %info
        n_holes = size(output_table, 1);

        temp_image = classImage;
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
        
        %Burn text
        if labelOption == 1 %most time consuming, 3 to 12 min
            box_color = {"black"};
            temp_image2 = insertText( temp_image, position, text_str(1:reach), ...
                FontSize= fontSize, TextColor= "white", ...
                TextBoxColor= box_color, BoxOpacity= .7);

        elseif labelOption == 0
            temp_image2 = temp_image;
        end

        %Save
        imwrite(temp_image2, destinationFile1)        
    end     
end
grid_info.grid_files_burned = grid_files;

end