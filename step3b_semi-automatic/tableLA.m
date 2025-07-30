function [output_table, measurements] = tableLA(labeledImage, previous_Map, method, parameters)

%Generate virtual microanalytical spot locations with maxLAfiring.m or
%randomLAfiting.m functions

%Created: 29-Sep-2020, M.A.
%Updated: 24-Mar-2025, M.A.

%Input:

%labeledImage: sub-grain labelled image (ROI) after collaging_WMI_affine
%previous_Map: grain labelled image (ROI) after QuPath irregular watershed segmentation 
%method: string determining the firing method ('random', 'max')
%parameters contains:
    %n_spots: maximum number of spots to be tested
    %outboundDist: distance between spot margin and grain boundary
    %proximityDist: distance between 2 spot margins

%Output:

%output_table: simulated spot table (Spot, Grain, Zone, X, Y)
%measurements: sub-grain areas where the simulation run

%Notes: the function follows old 'tableLA.m' script

%%
n_rows1 = size(labeledImage, 1);
n_cols1 = size(labeledImage, 2);

%Simulation parameters

n_spots = parameters.n_spots; %maximum per object
spotDiameter = parameters.spotDiameter;
outboundDist = parameters.outboundDist;
proximityDist = parameters.proximityDist; 
searchRadius = outboundDist + ceil(spotDiameter/2);
spotDist = spotDiameter + 2*outboundDist + proximityDist; %minimum distance

laserParameters.searchRadius = searchRadius;
laserParameters.spotDist = spotDist;

measurements1 = regionprops('table', labeledImage, labeledImage, ...
    'MeanIntensity'); 
measurements2 = regionprops('table', labeledImage, previous_Map, ...
    'MeanIntensity', 'Area', 'Solidity', ...
    'BoundingBox', 'Centroid', 'Image'); 

measurements1 = renamevars(measurements1, ["MeanIntensity"], ["label_zone"]);
measurements2 = renamevars(measurements2, ["MeanIntensity"], ["label_grain"]);
measurements = horzcat(measurements1, measurements2);

measurements(measurements.Area == 0, :) = []; %deleting zeros
n_objects = size(measurements, 1);

tic;

fullSpotCoordinates = cell(1, n_objects);
for i = 1:n_objects
        
    %Ensuring 1 object/bounding box
    temp_binaryImage = measurements.Image{i};
    temp_measurements = regionprops('table', temp_binaryImage, 'Area', 'Image');
    if size(temp_measurements, 1) ~= 1
        [~, I] = max(temp_measurements.Area);
        binaryImage = temp_measurements.Image{I};%pick largest object
    else
        binaryImage = temp_binaryImage;
    end
    bb_size = size(binaryImage);
    
    %Parametrization    
    out = bwferet(binaryImage, 'MinFeretProperties');    
    spotDist_out = (2/n_spots)*out.MinDiameter; %maximum distance       
    
    laserParameters.spotDist_out = spotDist_out;

    %% Score 3D surface
    
    D_boundary = bwdist(~binaryImage); 
    boundary_mask = D_boundary > searchRadius; %boundary distance mask
    
%     if sum(boundary_mask, 'all') ~= 0
        D_boundary(~boundary_mask) = 0; 
        D_boundary1 = max(D_boundary, [], 'all') - D_boundary; %reversed

        [rowVector, colVector] = find(boundary_mask);
        maskedDistance_accum  = zeros(bb_size); %distance accumulator
        for j = 1:sum(boundary_mask, 'all')
            row = rowVector(j);
            col = colVector(j);
            white_point = zeros(bb_size);
            white_point(row, col) = 1;

            D = bwdist(white_point);
            D1 = D.*boundary_mask; 
            %pixel-wise spot distance mask
            spotDistance_mask = (D1 > spotDist) & (D1 <= spotDist_out); 
            D1(~spotDistance_mask) = 0; 

            maskedDistance_accum = maskedDistance_accum + D1.*D_boundary1 + D_boundary1; %score
        end

        DistSurf = max(maskedDistance_accum, [], 'all') - maskedDistance_accum;
        DistSurf_positive = DistSurf.*boundary_mask; %keep positive relief
%     else
%         continue
%     end
    clear D D1 spotDistance_mask
    
    %% Firing 
    % progressively try less spots until they fit with either algorithm
    
    temp_n_spots = n_spots; %updating n_spots
    n_candidates = 50; %for 'random'
    switch method
        case 'max'
            while temp_n_spots > 0
                try
                    laserParameters.n_spots = temp_n_spots;
                    [spotCoordinates] = maxLAfiring(laserParameters, DistSurf_positive);
                    break
                catch
                    temp_n_spots = temp_n_spots-1;
    %                 continue            
                end
            end
    
        case 'random'            
            while temp_n_spots > 0
                try
                    laserParameters.n_spots = temp_n_spots;
                    [spotCoordinates] = randomLAfiring(laserParameters, DistSurf_positive, n_candidates);
                    break
                catch
                    temp_n_spots = temp_n_spots-1;
    %                 continue            
                end
            end       
    end    
    
    %% Converting to full image coordinates   
    
    if exist('spotCoordinates', 'var')

        n_spots = size(spotCoordinates, 1);        
        temp_grain = measurements.label_grain(i, :);
        temp_zone = measurements.label_zone(i, :);
        bbox = measurements.BoundingBox(i, :);

        x1 = ceil(bbox(1));
        y1 = ceil(bbox(2));
        full_x = spotCoordinates(:, 1) + x1 - 1;
        full_y = spotCoordinates(:, 2) + y1 - 1;
        
        temp_grain1 = repelem(temp_grain, n_spots, 1);
        temp_zone1 = repelem(temp_zone, n_spots, 1);
        fullSpotCoordinates{i} = table(temp_grain1, temp_zone1, full_x, full_y, ...
            'VariableNames', {'Grain', 'Zone', 'X', 'Y'});    
    end
    
    clear spotCoordinates
    
end
output_table0 = vertcat(fullSpotCoordinates{:});

t1 = toc;

%Relabelling 
n_zones = length(fullSpotCoordinates);
n_holes = size(output_table0, 1);
output_table = addvars(output_table0, [1:n_holes]', ...
    'NewVariableNames', 'Spot', 'Before', 1);

sprintf('WxH= %dx%d, %d grains, and %d spots \n Computing time= %.1f min', ...
    n_cols1, n_rows1, n_zones, n_holes, t1/60)

%% Optional: plot Score 3D surface
% 
% bb_size = size(image_temp);
% D_boundary = bwdist(~image_temp); 
% boundary_mask = D_boundary > searchRadius; %boundary distance mask
% D_boundary(~boundary_mask) = 0; 
% 
% z = DistSurf_positive(boundary_mask);
% [y, x] = find(boundary_mask);
% sf = fit([x, max(y)-y], z, 'cubicinterp'); %'linearinterp'
% 
% figure(1), 
% set(gcf, 'Position', [80 80 700 700])
% subplot(2, 1, 1)
% plot(sf, [x, max(y)-y], z)
% title('3D scatter plot with cubic interpolation')
% subplot(2, 1, 2)
% surf(double(flipud(DistSurf_positive))) %image has coordinates on top left
% title('Surface plot of probability in bounding box')
% zlim([150, max(DistSurf_positive, [], 'all')])

end