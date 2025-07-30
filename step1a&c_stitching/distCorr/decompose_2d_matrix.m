function [result] = decompose_2d_matrix(mat)
%author: Frederic Wang (Dec 1, 2013)

%required order of transforms: skew, scale, rotate, translate.
a= mat(1); b= mat(2); c= mat(4); d= mat(5); e= mat(7); f= mat(8);
delta = a*d - b*c; %determinant of linear transformation

result.translation = [e, f];
result.rotation = 0;
result.scale = [0, 0];
result.skew = [0, 0];

%QR-like decomposition.
if (a ~= 0 || b ~= 0)  %Gram-Schmidt process with delta?0
    r = sqrt(a*a + b*b);%r?0
    if b > 0
        result.rotation =  acos(a/r);
    elseif b < 0
        result.rotation = -acos(a/r);
    end
    result.scale = [r, delta/r];
    result.skew = [atan((a*c + b*d)/(r*r)), 0];
elseif (c ~= 0 || d ~= 0)
    s = sqrt(c*c + d*d);
    if d > 0
        result.rotation = pi/2 - acos(-c/s);
    elseif d < 0
        result.rotation = pi/2 - (-acos(c/s));
    end
    result.scale = [delta/s, s];
    result.skew = [0, atan((a*c + b*d)/(s*s))];
else
    disp('a = b = c = d = 0') %scale(0,0)
end
  
end
