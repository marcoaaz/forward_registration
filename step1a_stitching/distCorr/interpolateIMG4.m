function [img_interp1] = interpolateIMG4(file_route, original_coord, F_c)

%image input
image_temp = imread(file_route);
[rows, cols, n_channels] = size(image_temp);
tile_img = double(image_temp);

%grid
X = original_coord(:, 1);
Y = original_coord(:, 2);

%interpolating
channel_1 = tile_img(:, :, 1);        
F_c.Values = channel_1(:); 
V_r = F_c(Y, X); %or greyscale

if n_channels == 1            
    img_interp = reshape(V_r, [rows, cols]);
    
elseif n_channels == 3        
    g = tile_img(:, :, 2); %ch2
    b = tile_img(:, :, 3); %ch3
            
    F_c.Values = g(:); %reuse interporlant for the rest of channels
    V_g = F_c(Y, X);
    F_c.Values = b(:);
    V_b = F_c(Y, X);        
      
    channels = [V_r, V_g, V_b];        
    img_interp = reshape(channels, [rows, cols, n_channels]);
else 
    disp('Supports 3 channels in 8/16 bits, otherwise modify')
end
% imshowpair(tile_img, img_interp, 'falsecolor'); %alternative: 'diff'

%saving
if isa(image_temp, 'uint8')
    img_interp1 = uint8(img_interp); 
elseif isa(image_temp, 'uint16')
    img_interp1 = uint16(img_interp); 
else
    disp('Supports 8/16-bit images, otherwise modify')
end

end

% imshow(uint8(img_interp))
