%% Firing (option 1): using regional maxima

function [spotCoordinates] = maxLAfiring(laserParameters, scoreSurface)

%'maxLAfiring.m'

%Generates probability regional maxima pixels (similar to skeletonisation) 
%within curve mask and rank them by value. The n_spots are allocated
%sequentially at the closest possible location (>spotDist) in each
%iteration.

%Created: 29-Sep-2020, M.A.
%Updated: 
% 18-Sep-2024, M.A.
% 24-Mar-2025

%input
%scoreSurface: surface that represent where to shoot the next spot

%%
n_spots = laserParameters.n_spots; %number of LA spots
spotDist = laserParameters.spotDist; %parameter (long formulation)

bw_max1 = imregionalmax(scoreSurface); %somewhat similar to skeletonization
curveMask = scoreSurface ~= 0; 

if sum(curveMask, 'all') ~= 0 %There is at least 1 pixel within boundary mask

    [row_max, col_max] = find(bw_max1); %location
    values_max = scoreSurface(bw_max1); %value    
    curveCrest = [values_max, row_max, col_max];
    curveCrest1 = curveCrest; 

    curveMax = zeros(n_spots, 3);
    for i = 1:n_spots

        [M, I] = max(curveCrest1(:, 1));
        curveMax(i, :) = [M, curveCrest1(I, 3), curveCrest1(I, 2)]; %[value, x, y]
        
        %Find next spot between candidates (from a filtered bw_max1)
        pairwiseDistance = pdist2(curveCrest1(I, 2:3), curveCrest1(:, 2:3), ...
            'euclidean'); 
        index = pairwiseDistance > spotDist; %not recommended: (D1 <= spotDist_out)
        
        curveCrest1 = curveCrest1(index, :);    
    end

    %Note: In a future version, the selection of the first spot should be
    %more natural than picking the maximum peak and move laterally from
    %there

end
spotCoordinates = curveMax(:, [2, 3]); %[col, row]

end