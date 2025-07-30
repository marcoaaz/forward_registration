
function [labelled_map2, BW3, stats3] = imported_Watershed(labelled_map0, img_ref, size_TH, ...
    destinationFile1, destinationFile2, destinationFile3)

dtype = class(img_ref);
n_channels = size(img_ref, 3);
labelled_map = labelled_map0(:, :, 1);

%% Filtering objects

BW = (labelled_map > 0);
CC = bwconncomp(BW); 
stats = regionprops("table", CC, "Area", "BoundingBox"); %criteria
area = stats.Area;
selection = (area > size_TH); %edit
BW2 = cc2bw(CC, ObjectsToKeep = selection); %always 1 channel

BW3 = repmat(BW2, 1, 1, n_channels);

%Masking
labelled_map2 = labelled_map; %foreground 
labelled_map2(~BW2) = 0;
img_ref_fg = img_ref; %to interrogate
img_ref_fg(~BW3) = 0;

%Saving for reproducibility
imwrite(img_ref_fg, destinationFile3);
imwrite(BW3(:, :, 1), destinationFile2);

%% Calculate object properties

%Ensuring QuPath IDs are preserved (use MeanIntensity, MinIntensity, or MaxIntensity)
stats_mask = regionprops('table', BW2, labelled_map2, 'all');
%Note: regionprops expects labelled_map to be serial 1, 2, 3, (none missing)

%Interrogate channels
stats_accum = [];
for i = 1:n_channels
%Note: If the input is 16-bit, the main script can only read 1 channel 

    stats_ref = regionprops('table', BW2, img_ref_fg(:, :, i), 'MeanIntensity'); 
    
    name_temp = {sprintf('MeanIntensity_ch%d', i)};
    stats_ref.Properties.VariableNames = name_temp;
    
    stats_accum = [stats_accum, stats_ref];
end

%% Calculating new variables

%HSV colour space
if (n_channels == 3) & ( strcmp(dtype, 'uint8') )

    rgb = stats_accum{:, {'MeanIntensity_ch1', 'MeanIntensity_ch2', 'MeanIntensity_ch3'}}/255; 
    hsv = rgb2hsv(rgb);
    
    stats_accum2 = addvars(stats_accum, hsv(:, 1), hsv(:, 2), hsv(:, 3), ...
        'NewVariableNames', {'MeanIntensity_H', 'MeanIntensity_S', 'MeanIntensity_V'});
elseif n_channels == 1
        
    stats_accum2 = stats_accum;
end
colNames1 = stats_accum2.Properties.VariableNames; %channel names

%Append
stats_filtered = [stats_mask, stats_accum2];
n_items = size(stats_filtered, 1);

%Grains
label = uint16(stats_filtered.MeanIntensity); %grain label
centroids = cat(1, stats_filtered.Centroid); %X and Y for plot

%Aspect ratio
ar1 = stats_filtered.MajorAxisLength./stats_filtered.MinorAxisLength; %equivalent ellipse
ar2 = (1 - 1./ar1);

%Convexity (surface texture)
perimeter2 = stats_filtered.Perimeter;
perimeter1 = zeros(n_items, 1, "double");
% stats_filtered
for k = 1:n_items
    
    temp_binary = stats_filtered{k, 'ConvexImage'}{1};
    % temp_binary
    
    perimeter1(k) = regionprops(temp_binary, 'Perimeter').Perimeter;
end
convexity = perimeter1./perimeter2;

%in disuse
% shapeIndexes = stats_filtered.Perimeter./sqrt(stats_filtered.Area); %~smoothness and integrity
% n_inclusions = 1 - (stats_filtered.EulerNumber); %EulerNumber = 1 - number of holes

%New table
newColumns = {'Label', 'centroid_x', 'centroid_y', 'aspectRatio', 'Convexity'};

stats2 = addvars(stats_filtered, ...
    label, centroids(:, 1), centroids(:, 2), ar2, convexity, ...
    'Before', 'Area', 'NewVariableNames', newColumns); 

colnames = stats2.Properties.VariableNames;

%% Filter out variables (for smaller DB file size)

%contains
not_to_include = {
    'SubarrayIdx', 'WeightedCentroid'};

%exact match
not_to_include2 = {    
    'PerimeterOld', 'Extent', 'EquivDiameter', 'Eccentricity', ... %scalar
    'EulerNumber', 'ConvexArea', 'FilledArea',...         
     'ConvexHull', 'ConvexImage', 'FilledImage', 'Extrema', ...
     'MaxFeretAngle', 'MinFeretAngle', 'MaxFeretCoordinates', 'MinFeretCoordinates', ...
     'PixelIdxList', 'PixelList', 'PixelValues'
    };

idx1 = contains(colnames, not_to_include);
idx2 = ismember(colnames, not_to_include2);
in_idx = ~(idx1 | idx2);

stats3 = stats2(:, in_idx);

%% Optional: Save readable table (for labelling grain centroids)

colNames2 = {'Label', 'centroid_x', 'centroid_y', 'Area', 'Perimeter', ...
    'aspectRatio', 'Convexity', 'BoundingBox', 'Orientation', ...
    'Circularity', 'Solidity', 'MaxFeretDiameter', 'MinFeretDiameter'};

stats4 = stats3(:, [colNames2, colNames1]);

writetable(stats4, destinationFile1); 

end