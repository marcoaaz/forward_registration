function [labeled_RGB2] = save_burned_image(labeled_RGB1, output_table, spotDiameter, destinationFile10)
%for labelled

n_rows1 = size(labeled_RGB1, 1);
n_cols1 = size(labeled_RGB1, 2);
n_holes = size(output_table, 1);

spot_radius = spotDiameter/2;
n_steps = 30; %points for drawing spots
labeled_RGB2 = labeled_RGB1;
mask_2D = zeros(n_rows1, n_cols1, 'logical');

position = [];
text_str = [];
for i = 1:n_holes
    % i 

    x_temp = output_table{i, 'X'};
    y_temp = output_table{i, 'Y'};
    spot_temp = output_table{i, 'Spot'};
    grain_temp = output_table{i, 'Grain'};
    label_temp = output_table{i, 'Zone'};
        
    %Spot mask
    theta = linspace(0, -360, n_steps);    
    x = spot_radius * cosd(theta) + x_temp; 
    y = spot_radius * sind(theta) + y_temp;  
    mask = poly2mask(x,y, n_rows1, n_cols1);         
    mask_2D = mask_2D | mask;
        
    position = [position; [x_temp, y_temp]]; 
    text_str = [text_str; string(sprintf('N.%d, Zone%d', spot_temp, label_temp))];
    % text_str = [text_str; string(sprintf('N.%d, Grain%d, Zone%d', ...
    %     spot_temp, grain_temp, label_temp))];         
end
%Drawing spots
n_pixels = sum(mask_2D, 'all');
mask_3D = repmat(mask_2D, [1, 1, 3]);
a = repmat(reshape([0, 0, 0], 1, 1, 3), n_pixels, 1); %yellow = [255, 255, 0]
labeled_RGB2(mask_3D) = a(:);

%Label
box_color = {"black"};
labeled_RGB2 = insertText( labeled_RGB2, position, ...
    text_str, FontSize= 45, TextColor= "white", ...
    TextBoxColor= box_color, BoxOpacity= .7); %time consuming (3 min)

imwrite(labeled_RGB2, destinationFile10)


end