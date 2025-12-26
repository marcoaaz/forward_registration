function [circle_mask] = generate_circle_mask(imageSizeX)

imageSizeY = imageSizeX;
centerX = floor( (imageSizeX + 1)/2 ); 
centerY = floor( (imageSizeY + 1)/2 ); 
radius = floor( (imageSizeX/2) ); % This is the radius in pixels

[columnsInImage, rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
circle_mask = (rowsInImage - centerY).^2 + (columnsInImage - centerX).^2 <= radius.^2;


end