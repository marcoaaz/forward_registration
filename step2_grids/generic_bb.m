function [bb_width, bb_height] = generic_bb(array, scale, orientation)
%Grids have a constant size of cell (bounding box). This is defined with a
%criteria (see script) and oriented following the lines below.

% generic grain bounding box
A = ceil(max(array)*scale/100); %default  
B = ceil(A/2); %default
switch orientation
    case 'horizontal'
        bb_height = B;
        bb_width = A;
    case 'vertical'
        bb_height = A;
        bb_width = B;
end

end