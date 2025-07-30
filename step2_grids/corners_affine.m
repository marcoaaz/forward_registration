function [corners_output] = corners_affine(tform, corners_input, size1, size2)

%Following: 
%https://au.mathworks.com/matlabcentral/answers/421999-how-can-i-get-the-new-coordinates-of-a-point-after-rotation-of-an-image-2d
%https://au.mathworks.com/help/images/image-coordinate-systems.html

%ensuring precision
corners_input = double(corners_input);
size1 = double(size1);
size2 = double(size2);

ImCenterA = (1 + size1(1:2))/2; % Center of the main image
ImCenterB = (1 + size2(1:2))/2; % Center of the transformed image

corners_centered = corners_input - fliplr(ImCenterA);

[x, y] = transformPointsForward(tform, ...
    corners_centered(:, 1), corners_centered(:, 2));

corners_output = [x, y] + fliplr(ImCenterB);

end