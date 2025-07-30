
%'prototype_two_v9.m'

%Script to import the QuPath segmented masks (zircon grains), generate a
%labelled whole-mount image (WMI) of zircon grains and sub-grains, and simulate
%microanalytical spot locations (Option 2). See more details in manuscript.

%The update supports loading centroid/user coordinates and transforming
%them back and forth between WMI and grids for QuPath interaction. It can
%also load foreign images for producing grids and reconstruction WMI.
%Plotting options were added for simplicity

%Created: 24-Sep-24, Marco Acevedo
%Updated: 
% 2-Oct-24, 2-Jan-25, 13-Jan-25, 20-24-Jan-25, 1-Feb-25, 4-Mar-25, M.A.
% 19-21-25-Mar-25, MA

%Dependencies
scriptsFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts';
scriptsFolder1 = fullfile(scriptsFolder, "WMI/update_14-Jan-25/");
scriptsFolder2 = fullfile(scriptsFolder1, 'step2_grids');
scriptsFolder3 = fullfile(scriptsFolder1, 'step3_planning');
scriptsFolder4 = fullfile(scriptsFolder1, 'step3b_semi-automatic');

addpath(scriptsFolder);
addpath(scriptsFolder1) 
addpath(scriptsFolder2) 
addpath(scriptsFolder3) 
addpath(scriptsFolder4) 
addpath(fullfile(scriptsFolder, "bfmatlab/")) 

clear 
clc

%Notes (puck 2 images):
%row3_stack-0001.tif
%row3_stack_CL_RGB.tif

%%
%User input
destinationFolder = 'project_31-Mar-25_issue'; %output folder

%Registered reference images to interrogate
folderWithMontages = 'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\original_registered_row1';
sourceFile1 = fullfile(folderWithMontages, 'row1_stack_CL.tif'); %interrogation
source_path1 = fullfile(folderWithMontages, "row1_stack_CL_RGB.tif"); %slicing


folderWithOutputs = 'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row1\';
sourceFile2 = fullfile(folderWithOutputs, 'wsi_labelled.tif'); %Labelled whole-slide image (QuPath export collaged in Python)
filename_9 = fullfile(folderWithOutputs, 'row1_stack_CL_greyscale\PT_patches\row1_stack_CL_greyscale_vector-knn.csv'); %CNN feature vectors

%New QuPath project bearing point annotations within grids
qupath_dir = 'C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\test'; %annotated grids

%Watershed segmentation import (grain size threshold)
spatialResolution = 1; %microns/px
minSpotSize = 25; %microns

%Pre-select grains getting centroids x-y (after manual QA/QC QuPath for lost grains).
lost_grains = [];

%Pre-classification (follows 'classifying_variable' defined in script section)
%Note: ascend sorting within grids (defined by topSize)
n_classes = 1; %default= 4; equal populations
plotOption = 1;
sel_grain = 378; %by grain label, number in MatLab convention

%Grid slicing, saving, and collaging settings (grids)
canvas_aspectR = 1; %W/H = 16/9 power point
topSize = 12000;  %20500
scale = 75; %default= 50; 80 is nice; pct of largest grain dim (bounding box calculation)
pctOut = .5; %optional: auto-contrast (percentile out on both histogram sides)
orientation = 'vertical';
brightnessOption = 1; %brightness rescaling on/off
burnOption = 1; %grain tags on/off


%Script

[rootFolder, ~] = fileparts(sourceFile2);
cd(rootFolder);

sourceFolder = fullfile(rootFolder, destinationFolder);
intermediateFolder = fullfile(sourceFolder, 'processed_files'); %avoids a mess

%if laser session input (scancsv parent) and output (iolite output) files are available:
intermediateFile_1 = fullfile(sourceFolder, 'registration_intermediateFiles\spot_reg3.csv'); 
intermediateFile_2 = fullfile('E:\Feb-March_2024_zircon imaging\02_John Caulfield_files\puck 1_chemical data', ...
    '250328_CA24MR-1_firstpuck_25_UPb_GJ189_matlab.xlsx'); 

mkdir( sourceFolder )
mkdir( intermediateFolder )

%New files
[~, suffix, ~] = fileparts(source_path1); %helper
fileName1 = 'grainMeasurements.xlsx'; %segmentation (saving unsorted table)
fileName2 = 'binaryFG_splitted.tif';
fileName3 = strcat(suffix, '_masked.tif'); %edit to avoid overwriting
fileName4 = 'boundingboxXY.xlsx'; %grid
fileName8 = 'grid_info.mat';
fileName6 = strrep(fileName3, '.tif', '_adj_recon.tif'); %masked, adjusted, reconstructed WMI
fileName7 = strrep(fileName6, '.tif', '_obias.tif'); %SuperSIAT map
fileName9 = strrep(fileName6, '.tif', '_obias_RGB.tif'); %SuperSIAT map in RGB

destinationFile1 = fullfile( rootFolder, fileName1); %save unsorted grain measurements (regionprops)
destinationFile2 = fullfile( rootFolder, fileName2); %foreground
destinationFile3 = fullfile( intermediateFolder, fileName3); %reference image modified (masked)
filepath_10 = fullfile(intermediateFolder, 'coord_output_grid.xlsx'); %TSV

%% Loading images

labelled_map = imread(sourceFile2); %whole-mount image grains (Pyvips script)
img_ref = imread(sourceFile1); %registered reference image
dim_wmi = size(img_ref, 1:3); %3 channels

%Loading segmentation (3 min)
size_TH = (minSpotSize*(1/spatialResolution))^2; %min. grain size threshold (px^2)
[labelled_map2, stats2_pre] = imported_Watershed(labelled_map, img_ref, size_TH, destinationFile1);

%Extra calculations
if dim_wmi(3) == 3

    rgb = stats2_pre{:, {'MeanIntensity_ch1', 'MeanIntensity_ch2', 'MeanIntensity_ch3'}}/255; %works w/ 3 channels
    hsv = rgb2hsv(rgb);
    
    stats2 = addvars(stats2_pre, hsv(:, 1), hsv(:, 2), hsv(:, 3), ...
        'NewVariableNames', {'MeanIntensity_H', 'MeanIntensity_S', 'MeanIntensity_V'});
elseif dim_wmi(3) == 1
        
    stats2 = stats2_pre;
end

%Saving intermediate files (filtered grains)
BW2 = (labelled_map2 > 0);
BW3 = repmat(BW2, 1, 1, size(labelled_map2, 3)); %mask
img_ref_fg = img_ref;
img_ref_fg(~BW3) = 0;

imwrite(BW2, destinationFile2);
imwrite(img_ref_fg, destinationFile3);

%% Image to slice into grids (re-run)

img_foreign = imread(source_path1);
dim_wmi_slice = size(img_foreign, 1:3);
inputType = class(img_foreign); %8 or 16-bit

img_foreign_fg = img_foreign;
img_foreign_fg(~BW3) = 0;
img_ref_fg2 = img_foreign_fg; %pre-allocating

%Sorting grains by criteria (prepare for next section)

%Using ResNet50 data (from Python)
%pre-requisite: run 'classifyFolder_wVectors_v4.ipynb'
sorting_table = readtable(filename_9);

%parse grain number
path_temp = sorting_table.filename; 
[~, basename9, ext9] = fileparts(path_temp);
expression9 = '.+_(?<grain>\d+)_\[.+\]';
temp_str = regexp(basename9, expression9, 'names');
temp_str2 = struct2table([temp_str{:}]);
sorting_table2 = addvars(sorting_table, double(string(temp_str2.grain)), ...
    'NewVariableNames', {'grain'}, 'Before', 1);

%medicine: rectify idx_knn_#
varNames = sorting_table2.Properties.VariableNames;
varIdx_1 = contains(varNames, 'vector_'); %not used
varIdx_2 = contains(varNames, 'idx_knn_');
varIdx = ~(varIdx_1 | varIdx_2);
sorting_table3 = sorting_table2(:, varIdx); %used

knn_mtx = sorting_table2{:, varIdx_2} + 1; %python table row idx
grain_array = sorting_table3.grain;
n_sorted = length(grain_array);
knn_mtx_update = zeros(size(knn_mtx), 'double');
for i = 1:n_sorted
    temp_grain = grain_array(i);
    replacement_mask = (knn_mtx == i);
    knn_mtx_update(replacement_mask) = temp_grain;
end
knn_cols = strcat('knn_', string(1:n_sorted-1));
knn_table = array2table(knn_mtx_update, 'VariableNames', knn_cols);
sorting_table4 = [sorting_table3, knn_table]; %follows grains

%%
% %Using LA-ICP-MS data (from Iolite)
% a = readtable(intermediateFile_1, 'VariableNamingRule','preserve'); %scan list
% b = readtable(intermediateFile_2, 'VariableNamingRule','preserve'); %chemical data
% c = innerjoin(b, a, 'LeftKeys', {'Var1'}, 'RightKeys', {'newName'});

%Append
%segmentation with resnet
stats3 = outerjoin(stats2, sorting_table4, ...
    'LeftKeys', {'Label'},'RightKeys',{'grain'}, 'MergeKeys',true);
%%
%medicine (without laser)
stats3 = renamevars(stats3, "Label_grain", 'Label');


% %combo with laser
% stats4 = outerjoin(stats3, c, ...
%     'LeftKeys', {'Label_grain'},'RightKeys',{'Grain'}, 'MergeKeys',true);
% stats5 = renamevars(stats4, ["Label_grain_Grain"],["Label"]);
% %n_analysed = sum(~isnan(stats4.X))

% %medicine: column names
% colnames = stats5.Properties.VariableNames;
% colnames_rdy = strrep(colnames, '/', '-');
% stats5.Properties.VariableNames = colnames_rdy;


% %Medicine: filtering ages
% values = stats5{:, classifying_variable};
% idx_real = (values > 0) & (values < 4543);
% stats6 = stats5(idx_real, :);

stats6 = stats3;

% Generating grids

%User secondary input
%'knn', 'MeanIntensity_V', 'MeanIntensity_H', 'Area', 'MaxFeretDiameter', 
% 'aspectRatio', 'shapeIndex', 'Circularity', 'Solidity', 'class_index'
sel_grain = 164; %'knn'
classifying_variable = 'knn'; %aspectRatio, Final Pb206-U238 age_mean
%% 
%Find sorting index
all_grains = stats6.Label;
varNames2 = stats6.Properties.VariableNames;
trial_n = 0; %counter
if strcmp(classifying_variable, 'knn')    

    %Sorting by feature vector (fine-tuned pre-trained ResNet50 model)     
    varIdx = contains(varNames2, 'knn_');
    varNames3 = varNames2(varIdx);
    sel_idx = (all_grains == sel_grain);
    knn_grains = stats6{sel_idx, varNames3};      
    [~, sort_idx1] = ismember(knn_grains, all_grains);

    sort_idx2 = [find(sel_idx); sort_idx1'];       
    gridFolder = fullfile(sourceFolder, strcat(classifying_variable, '_', num2str(sel_grain)) );

else   
    trial_n = trial_n +  1;

    [~, sort_idx2] = sortrows(stats6, {classifying_variable}, {'ascend'});
    gridFolder = fullfile(sourceFolder, strcat(classifying_variable, '_', num2str(trial_n)) );
end
mkdir(gridFolder)

%Defined in specific folder (applies for next sections)
destinationFile4 = fullfile( gridFolder, fileName4); %table of bb for SuperSIAT collage
destinationFile4_full = strrep(destinationFile4, '.xlsx', '_full.mat');
destinationFile8 = fullfile( gridFolder, fileName8); %grid_info
destinationFile6 = fullfile( gridFolder, fileName6); 
destinationFile14 = fullfile(gridFolder, 'option1_spot_table.xlsx');
destinationFile15 = fullfile(gridFolder, 'option1_grain_table.mat'); %sorted

destinationFile7 = fullfile( gridFolder, fileName7); %OBIAS map
destinationFile9 = fullfile( gridFolder, fileName9); %in rgb
destinationFile10 = strrep(destinationFile9, '.tif', '_burned.tif'); %simulation spots
destinationFile11 = strrep(destinationFile10, '_burned.tif', '_burned_CL.tif'); %CL for comparison
destinationFile12 = fullfile(gridFolder, 'option2_spot_table.xlsx');
destinationFile13 = fullfile(gridFolder, 'option2_zone_table.mat');

%Sorting
DB_sorted_in = stats6(sort_idx2, :);

[DB_sorted, populationBand] = sorting_grainDB_importedIdx(DB_sorted_in, n_classes);

%Auxiliary calculations
equivalent_radius = sqrt(mean(DB_sorted.Area)/pi); %from average area

%Finding grain centroids (for quality check)
input_table_unsorted = readtable(destinationFile1); 
[~, sort_idx] = ismember(DB_sorted.Label, input_table_unsorted.Label);
input_table = input_table_unsorted(sort_idx, :);
%find point labels
coord_input = [input_table.centroid_x, input_table.centroid_y];
coord_input2 = ceil(coord_input - 0.5); 
coord_labels = labelled_map2(sub2ind( size(labelled_map2), ...
    coord_input2(:,2), coord_input2(:,1)));
coord_labelled = [double(coord_labels), coord_input]; %no Class and Grid
 %label=0 issue (generates duplicate)

%Complete missing labels (medicine), assumes convex objects
r = round(equivalent_radius)/2; %increase if insufficient
idx_missing = (coord_labelled(:, 1) == 0);
search = find(idx_missing);
for i = search'
    object_missing = input_table(i, :);

    temp = [object_missing.centroid_x, object_missing.centroid_y];
    temp_int = ceil(temp - 0.5);
    from_row = temp_int(2) - r;
    to_row = temp_int(2) + r;
    from_col = temp_int(1) - r;
    to_col = temp_int(1) + r;
    
    temp_patch = labelled_map2(from_row:to_row, from_col:to_col, :);
    temp_label = mode(temp_patch, 'all');
    
    coord_labelled(i, 1) = temp_label;
end

%filtering pre-selected grains
[~, b] = ismember(lost_grains, coord_labelled(:, 1));
c = setdiff(1:size(coord_labelled, 1), b);
coord_labelled2 = coord_labelled(c, :);

coord_labelled2 = unique(coord_labelled2,'rows'); %medicine

% generic grain bounding box
A = ceil(max(DB_sorted.MaxFeretDiameter)*scale/100); %default  
B = ceil(A/2); %default
switch orientation
    case 'horizontal'
        bb_height = B;
        bb_width = A;
    case 'vertical'
        bb_height = A;
        bb_width = B;
end

%Grid configuration
grid_info = struct;
grid_info.dim_wmi = dim_wmi_slice;
grid_info.inputType = inputType;
grid_info.n_classes = n_classes;
grid_info.dest_file_bb = destinationFile4;
grid_info.dest_folder_grid = gridFolder; %sourceFolder
grid_info.DB_sorted = DB_sorted; %2 GB
grid_info.populationBand = populationBand; %important
grid_info.bb_height = bb_height;
grid_info.bb_width = bb_width;

[grid_info, logSheet] = grid_configuration(grid_info, topSize, canvas_aspectR);

%Slice whole-mount image with affine transformation (~1 min)
close all

[class_grids, bbXYtable_full] = slice_WMI_affine(grid_info, img_ref_fg2, ...
    orientation, brightnessOption, pctOut, burnOption);
%%
%transform centroid points
[coord_output] = slice_WMI_affine_coord(coord_labelled2, bbXYtable_full); %grain 164 in row1 repeated

%centroids used by the expert (later)
coord_output_grid2 = array2table(coord_output, ...
    "VariableNames", {'class', 'grid', 'label', 'x', 'y'});
writetable(coord_output_grid2, filepath_10); %required
writeQupathPoints(filepath_10);

%Saving grids and metadata for reconstruction 
[grid_info] = save_grids(grid_info, class_grids, suffix); %updates
save(destinationFile8, 'grid_info', '-mat') %heavy for saving
save(destinationFile15, 'DB_sorted', '-mat'); %redundant (for consistency)
save(destinationFile4_full, 'bbXYtable_full', '-mat')

%Collaging reconstruction of whole-mount image
load(destinationFile8) %grid_info
load(destinationFile4_full) %for reconstruction

[gridCells] = load_grids_image(grid_info.grid_files);
[mountImage] = collaging_WMI_affine(gridCells, bbXYtable_full, grid_info, 'linear'); 
imwrite(mountImage, destinationFile6); 

%Centroids inverse transform (for quality check)
coord_labelled_grid = coord_output(:, 3:5);
[coord_output2] = collaging_WMI_affine_coord(coord_labelled_grid, bbXYtable_full);

%% Optional: forward registration, find planned spots

planned_spots0 = stats6(:, {'X', 'Y', 'Label', classifying_variable}); %stats5

planned_spots = planned_spots0( all(~ismissing(planned_spots0), 2), :);

planned_spot_info = planned_spots{:, classifying_variable};
planned_coord_input = [planned_spots.X, planned_spots.Y];
planned_coord_labels = planned_spots.Label;
planned_coord_labelled2 = [double(planned_coord_labels), planned_coord_input];

[planned_coord_output] = slice_WMI_affine_coord(planned_coord_labelled2, bbXYtable_full);

prev_suffix = strcat(suffix, '_burnedSpot');
[grid_info] = save_burned_grids(grid_info, class_grids, ...
    planned_coord_output, planned_spot_info, prev_suffix);

%% Optional: backward registration, find previously analysed spots

[A, ~, ~] = fileparts(folderWithOutputs);
filename_10 = fullfile(A, 'processed_files', 'merged_7-apr.xlsx');
prev_spots = readtable(filename_10, 'VariableNamingRule','preserve');

prev_spot_info = prev_spots.Comment;
prev_coord_input = [prev_spots.X_reg, prev_spots.Y_reg];
prev_coord_labels = prev_spots.Grain;
prev_coord_labelled2 = [double(prev_coord_labels), prev_coord_input];

[prev_coord_output] = slice_WMI_affine_coord(prev_coord_labelled2, bbXYtable_full);

prev_suffix = strcat(suffix, '_burnedSpot');
[grid_info] = save_burned_grids(grid_info, class_grids, ...
    prev_coord_output, prev_spot_info, prev_suffix);

%% For Option 1: Retrieving expert annotations made within Class grids
%requires export from special QuPath project folders containing the grid
%annotation exports (following naming convention for regex)

[T3] = collect_pointAnnotations(qupath_dir); %for all contained images

path_temp = T3.path_geojson;
[~, basename, ext] = fileparts(path_temp);
expression1 = '[a-zA-Z]+(?<class>\d+)_[a-zA-Z]+(?<grid>\d+)'; %.tiff
temp_str = regexp(basename, expression1, 'names');
temp_str2 = struct2table([temp_str{:}]);

T4 = addvars(T3, double(temp_str2.class), double(temp_str2.grid), ...
    'NewVariableNames', {'Class', 'Grid'}, 'After','path_geojson');
coord_expert = T4{:, {'x', 'y'}}; %in grid coordinates
pre_classification = [1, 1]; %class, grid to search

[coord_output3] = collaging_WMI_affine_coord_unlabelled(coord_expert, bbXYtable_full, pre_classification);
n_annotations = size(coord_output3, 1);

expert_table = array2table([[1:n_annotations]' , coord_output3(:, 3:5)], ...
    "VariableNames", {'Spot', 'Grain', 'X', 'Y'});

%Save (all grids of a sample)
writetable(expert_table, destinationFile14, ...
    'WriteVariableNames', true, 'WriteMode', 'overwritesheet');

%% Optional: Quality checks

%check centroids
plot_original_check1(img_ref_fg2, coord_labelled2, 7) %n_std
plot_grid_check1(class_grids, coord_output, 1, 1) %class, grid

%check centroids/expert spots 
plot_original_check2(mountImage, coord_output3)%coord_output3 (if quPath)

%% Object-based image segmentation (Semi-automated mode)
%Input (pre-requisite): grids analysed by object-based image analysis in SuperSIAT
%Output: Put OBIAS map on top of binary map for quality control
%load_grid_maps() assumes segmentation outputs are saved within SuperSIAT 
% generated folders for each image

gridNames = grid_info.grid_files;
grain_fg = imread(destinationFile2); %foreground of splitted objects

[gridCells, newMapCells, referenceTable] = load_grids_map(gridNames); 

[mountMap] = collaging_WMI_affine(newMapCells, bbXYtable_full, ...
    grid_info, 'nearest');
mountMap = uint16(mountMap);

%Colour map
n_zones1 = double( max(unique( mountMap ))); %must match referenceTable
s = rng;
r = randperm(n_zones1);
cmap = colorcube(n_zones1); %allows >256 colours
cmap_rand = rand(n_zones1, 3);
grey_idx = (cmap(:, 1) == cmap(:, 2)) & (cmap(:, 2) == cmap(:, 3));
cmap2 = cmap; %pre-allocate
cmap2(grey_idx, :) = cmap_rand(grey_idx, :);
cmap3 = cmap2(r, :);

%Whole-mount map
mountMap_RGB = label2rgb(mountMap, cmap3, 'black'); %zerocolor
mapped_fg = (mountMap > 0); %mask
artefact_fg = logical(grain_fg - mapped_fg);
artefact_fg2 = repmat(artefact_fg, [1, 1, 3]);
mountMap_RGB(artefact_fg2) = artefact_fg2(artefact_fg2)*255; %white fringe bg

%Saving
imwrite( mountMap, destinationFile7 ); %maximum label = 65535;
imwrite( mountMap_RGB, destinationFile9 );
destinationFile9_b = strrep(destinationFile9, '.tif', '_colormap.mat');
save(destinationFile9_b, 'cmap3', '-mat')

%%

%% Simulating spot location

%Spot simulation parameters
spatialResolution_sim = 0.250; %microns/px
n_spots = 3;
spotDiameter_user = 25; %microns
proximityDist_user = 15;
outboundDist_user = 0;

spotDiameter = spotDiameter_user/spatialResolution_sim;
proximityDist = proximityDist_user/spatialResolution_sim;
outboundDist = outboundDist_user/spatialResolution_sim;
searchRadius = outboundDist + ceil(spotDiameter/2);

parameters.n_spots = n_spots; %maximum per object
parameters.spotDiameter = spotDiameter;
parameters.proximityDist = proximityDist; %minimum (overlapping spot) = -searchRadius
parameters.outboundDist = outboundDist;
parameters.searchRadius = searchRadius;

labeled = imread(destinationFile7); %labelled WMI
labeled_RGB = imread(destinationFile9);
n_rows = size(labeled, 1);
n_cols = size(labeled, 2);
% row_range = [1:n_rows]; %entire image
% col_range = [1:n_cols]; 

%% ROI: select area for computation

figure
ax = gca;

imshow(labeled_RGB)
hROI = drawrectangle('Parent', ax);
pos = hROI.Position; %[x_tl, y_tl, box_w, box_h]

%Subsetting
from_row = ceil(pos(2));
to_row = floor(from_row + pos(4) - 1);
from_col = ceil(pos(1));
to_col = floor(from_col + pos(3) - 1);
row_range = [from_row:to_row];
col_range = [from_col:to_col];

labelled_map3 = labelled_map2(row_range, col_range); %from Option 1
img_ref1 = mountImage(row_range, col_range, :);
labeled1 = labeled(row_range, col_range); %from Option 2
labeled_RGB1 = labeled_RGB(row_range, col_range, :);

%Simulating spots
[simulation_table, measurements] = tableLA(labeled1, labelled_map3, 'max', parameters);

[labeled_RGB2] = save_burned_image(labeled_RGB1, simulation_table, spotDiameter, destinationFile10);
figure, imshow(labeled_RGB2)

%Save
writetable(simulation_table, destinationFile12, 'WriteVariableNames', true, 'WriteMode', 'overwritesheet');
save(destinationFile13, 'measurements', '-mat'); 
imwrite(img_ref1, destinationFile11); %for quality check

