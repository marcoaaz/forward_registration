
%'prototype_optionA_v2.m'

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
% 19-21-25-Mar-25, 17-Jun-25, MA

%Dependencies
scriptsFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts';
scriptsFolder1 = fullfile(scriptsFolder, "WMI/update_14-Jan-25/");
scriptsFolder2 = fullfile(scriptsFolder1, 'step2_grids');
scriptsFolder3 = fullfile(scriptsFolder1, 'step3_planning');
scriptsFolder4 = fullfile(scriptsFolder1, 'step3b_semi-automatic');
scriptsFolder5 = fullfile(scriptsFolder1, 'step4_registration');

addpath(scriptsFolder);
addpath(scriptsFolder1) 
addpath(scriptsFolder2) 
addpath(scriptsFolder3) 
addpath(scriptsFolder4) 
addpath(scriptsFolder5) 
addpath(fullfile(scriptsFolder, "bfmatlab/")) 

clear 
clc

destinationFolder = 'project_25-Jun_1'; %output folder

%Registered reference images to interrogate
folderWithMontages = 'D:\Charlotte_spot proj\marco obs\Klamath';
sourceFile1 = fullfile(folderWithMontages, 'CL.tif'); %interrogation
source_path1 = fullfile(folderWithMontages, 'CL_rgb.tif'); %slicing

folderWithOutputs = 'D:\Charlotte_spot proj\qupath_segmentation\CL_7-Apr-25';
sourceFile2 = fullfile(folderWithOutputs, 'wsi_labelled.tif'); %Labelled whole-slide image (QuPath export collaged in Python)

%Peripheral files
qupath_dir = '1D:\Justin Freeman collab\Marco Zircon_16bit\prototype2_work\qupath_project\output_test2\John_spots'; %point annotated grids (QuPath new project)
filename_9 = fullfile(folderWithOutputs, 'CL\PT_patches\CL_vector-knn.csv'); %CNN feature vectors
filename_10 = "D:\Charlotte_spot proj\qupath_segmentation\backward_registration\merged_18-apr.xlsx";
filename_11 = "1E:\Feb-March_2024_zircon imaging\02_John Caulfield_files\CA-24MR_chemical data\puck 1\scan_list_output.xlsx"; %merged laser data

%Watershed segmentation import (grain size threshold)
spatialResolution = 1; %microns/px
minSpotSize = 25; %microns

%Pre-select grains getting centroids x-y (after manual QA/QC QuPath for lost grains).
lost_grains = [        
    ];

%Pre-classification (follows 'classifying_variable' defined in script section)
%Note: ascend sorting within grids (defined by topSize)
n_classes = 1; %default= 4; equal populations
plotOption = 1;
sel_grain = 43; %by grain label, number in MatLab convention
classifying_variable = 'knn'; %knn for ResNet50
display_variable = 'age_isoplot'; %for burning text; classifying_variable
sort_direction = 'descend'; %'ascend', 'descend'

%Grid slicing, saving, and collaging settings (grids)
nrows = 15;
nGrids = 1;
chosen_bb_variable = 'MaxFeretDiameter';
scale = 75; %default= 75; pct of largest grain dim (bounding box calculation)
orientation = 'horizontal';
sel_pattern = [4, 1];

pctOut = .5; %optional: auto-contrast (percentile out on both histogram sides)
brightnessOption = 1; %brightness rescaling on/off

burnOption = 1; %grain tags on/off
labelOption = 1; %for spots (time consuming)
pixel_size = spatialResolution; %microns/px
spotSize= 40; %in microns

sample_str = ''; %edit (folder name)
trial_n = 0; %counter

% %standard destination cell 'bounding box'
% bb_width_microns = 125; %microns
% bb_height_microns = bb_width_microns*2;
% bb_width = floor(bb_width_microns/spatialResolution);
% bb_height = floor(bb_height_microns/spatialResolution);


% Script

spot_diameter = 2*spotSize/pixel_size; %in px (for drawing spots)

[rootFolder, ~] = fileparts(sourceFile2);
sourceFolder = fullfile(rootFolder, destinationFolder);
intermediateFolder = fullfile(sourceFolder, 'processed_files'); %avoids a mess

cd(rootFolder);
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
prev_suffix = strcat(suffix, '_burnedSpot');

destinationFile1 = fullfile( rootFolder, fileName1); %save unsorted grain measurements (regionprops)
destinationFile2 = fullfile( rootFolder, fileName2); %foreground
destinationFile3 = fullfile( intermediateFolder, fileName3); %reference image modified (masked)
filepath_10 = fullfile(intermediateFolder, 'coord_output_grid.xlsx'); %centroids TSV

%Optional:
%data from 'classifyFolder_wVectors_v4.ipynb'
[sorting_table4, status_resnet] = load_resnetSimilarity(filename_9);

%data from 'imageRegistration_v7.m' script and Iolite
try
    laser_data = readtable(filename_11, 'VariableNamingRule','preserve');
    status_laser = 1;
    
    % Option: Parse sample name
    if strcmp(sample_str, '')
        laser_data_sub = laser_data;
    else
        idx_sample = contains(laser_data.sampleName, sample_str);
        laser_data_sub = laser_data(idx_sample, :);
    end
    
catch ME    
    display(ME.message);
    status_laser = 0;
end

%% Loading images (time-consuming)
%Note: a future update should allow using 16-bit multi-channel image
%pyramids that do not fit in memory
disp('Loading images. Please, wait..')

labelled_map = imread(sourceFile2); %whole-mount image grains (Pyvips script)
img_ref = imread(sourceFile1); %registered reference image
img_foreign0 = imread(source_path1); %Image to slice into grids (re-run)

%medicine
if size(img_foreign0, 3) == 1
    img_foreign = repmat(img_foreign0, [1, 1, 3]);
else
    img_foreign = img_foreign0;
end

dim_wmi = size(img_ref, 1:3); %3 channels
dim_wmi_slice = size(img_foreign, 1:3);
inputType = class(img_foreign); %8 or 16-bit

%Loading grain segmentation (3 min)
size_TH = ( minSpotSize*(1/spatialResolution) )^2; %min. grain size threshold (px^2)

[labelled_map2, BW3, stats2] = imported_Watershed(labelled_map, img_ref, size_TH, ...
    destinationFile1, destinationFile2, destinationFile3); %interrogation 

%masking input
img_foreign_fg = img_foreign; %to slice
img_foreign_fg(~BW3) = 0;
img_ref_fg2 = img_foreign_fg; %pre-allocating

% Appending new data
if status_resnet == 1 & status_laser == 0

    %Append segmentation data to ResNet50 vectors
    stats3 = outerjoin(stats2, sorting_table4, ...
        'LeftKeys', {'Label'},'RightKeys',{'grain'}, 'MergeKeys',true);
    stats3 = renamevars(stats3, "Label_grain", 'Label'); %medicine (without laser)

    stats6 = stats3;

elseif status_resnet == 1 & status_laser == 1   
    
    stats3 = outerjoin(stats2, sorting_table4, ...
    'LeftKeys', {'Label'},'RightKeys',{'grain'}, 'MergeKeys', true);       

    %Append laser/QuPath expert/registration data    
    stats4 = outerjoin(stats3, laser_data_sub, ...
        'LeftKeys', {'Label_grain'},'RightKeys',{'Grain'}, 'MergeKeys',true); 
    stats5 = renamevars(stats4, ["Label_grain_Grain"], ["Label"]);
        
    stats6 = stats5;

elseif status_resnet == 0 & status_laser == 0 %No change

    stats6 = stats2;
end

%Comment below to reproduce old results:
% %Medicine: filtering artefact ages
% filtering_variable = 'Final Pb206-U238 age_mean';
% values = stats6{:, filtering_variable};
% idx_real = (values > 0) & (values < 4543);
% stats6 = stats6(idx_real, :);

%% Sorting grains by criteria (prepare for next section)

% %Optional: User secondary input (manual to avoid reloading images)
% sel_grain = 238; %by grain label, number in MatLab convention
% classifying_variable = 'knn'; %knn for ResNet50
% sort_direction = 'descend'; %'ascend', 'descend'

%Find sorting index
all_grains = stats6.Label;
varNames2 = stats6.Properties.VariableNames;

if strcmp(classifying_variable, 'knn')    

    %Sorting by feature vector (fine-tuned pre-trained ResNet50 model)     
    varIdx = contains(varNames2, 'knn_');
    varNames3 = varNames2(varIdx);
    sel_idx = (all_grains == sel_grain);
    knn_grains = stats6{sel_idx, varNames3}; %rows      
    [~, sort_idx1] = ismember(knn_grains, all_grains);
    sort_idx1(sort_idx1 == 0) = []; %avoid missing

    sort_idx2 = [find(sel_idx); sort_idx1'];       
    gridFolder = fullfile(sourceFolder, strcat(classifying_variable, '_', num2str(sel_grain)) );

else   
    trial_n = trial_n +  1; %avoid overwriting

    [~, sort_idx2] = sortrows(stats6, {classifying_variable}, {sort_direction});
    gridFolder = fullfile(sourceFolder, strcat(classifying_variable, '_', num2str(trial_n)) );
end

%Defined in specific folder (applies for next sections)
mkdir(gridFolder)

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

%Sorting and pre-classifying
DB_sorted_in0 = stats6(sort_idx2, :); %untouched

idx_removed_WSgrains = isnan(DB_sorted_in0.centroid_x);
DB_sorted_in = DB_sorted_in0(~idx_removed_WSgrains, :);

% %Optional (only available with geochemistry):
% %Medicine 1: filtering artefact ages from merged grid database
% filtering_variable = 'Final Pb206-U238 age_mean';
% values = DB_sorted_in{:, filtering_variable};
% idx_real = (values > 0) & (values < 4543);
% DB_sorted_in = DB_sorted_in(idx_real, :);
% 
% %Medicine 2: filtering other minerals (not zircon)
% idx_zircon1 = (DB_sorted_in.Ti49_ppm_mean < 3000); %
% idx_zircon2 = (DB_sorted_in.Zr91_ppm_mean > 300000);
% idx_zircon = idx_zircon1 & idx_zircon2;
% DB_sorted_in = DB_sorted_in(idx_zircon, :);
% 
% %Medicine 3 (optional): Appending isoplot calculations and plot saving
% [isoplot_table] = geochemistry_isoplot_1(DB_sorted_in, gridFolder);
% DB_sorted_in = [DB_sorted_in, isoplot_table]; 
%
[DB_sorted, populationBand] = sorting_grainDB_importedIdx(DB_sorted_in, n_classes);

%Auxiliary calculations
array = DB_sorted{:, chosen_bb_variable};
[bb_width, bb_height] = generic_bb(array, scale, orientation); %scale in percentage

% generic search radius (for centroid labelling)
equivalent_radius = sqrt(mean(DB_sorted.Area)/pi); %from average area
r = round(equivalent_radius)/2; %Note: increase if insufficient

%Labelling grain centroids (for quality check)
input_table_unsorted = readtable(destinationFile1);
[~, sort_labels0] = ismember(DB_sorted.Label, input_table_unsorted.Label);
sort_labels = nonzeros(sort_labels0);
input_table = input_table_unsorted(sort_labels, :);
coord_input = [input_table.centroid_x, input_table.centroid_y];

[coord_labelled] = centroid_labelling(coord_input, labelled_map2, r);

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
grid_info.sel_pattern = sel_pattern;

% [grid_info, logSheet] = grid_configuration(grid_info, topSize, canvas_aspectR);
[grid_info, logSheet] = grid_configuration_custom(grid_info, nrows, nGrids);

%Slice whole-mount image with affine transformation (~1 min)
[class_grids, bbXYtable_full] = slice_WMI_affine(grid_info, img_ref_fg2, ...
    orientation, brightnessOption, pctOut, burnOption);

%Saving grids and metadata for reconstruction 
[grid_info] = save_grids(grid_info, class_grids, suffix); %updates
save(destinationFile8, 'grid_info', '-mat', '') %heavy for saving
save(destinationFile4_full, 'bbXYtable_full', '-mat','-v7.3')

% %Collaging reconstruction of whole-mount image
% load(destinationFile8) %grid_info
% load(destinationFile4_full) %for reconstruction
[gridCells] = load_grids_image(grid_info.grid_files);
[mountImage] = collaging_WMI_affine(gridCells, bbXYtable_full, grid_info, 'linear'); 
imwrite(mountImage, destinationFile6); 

%centroids in grid (for QuPath)
[~, b] = ismember(lost_grains, coord_labelled(:, 1)); %filtering out pre-selected grains
c = setdiff(1:size(coord_labelled, 1), b);
coord_labelled2 = coord_labelled(c, :);
coord_labelled2 = unique(coord_labelled2, 'rows'); %medicine
[coord_output] = slice_WMI_affine_coord(coord_labelled2, bbXYtable_full); %grain 164 in row1 repeated

coord_output_grid2 = array2table(coord_output, "VariableNames", ...
    {'class', 'grid', 'label', 'x', 'y'});
writetable(coord_output_grid2, filepath_10); %required
writeQupathPoints(filepath_10);

%Centroids in original image (quality-checks inverse transformation)
coord_labelled_grid = coord_output(:, 3:5);
[coord_output2] = collaging_WMI_affine_coord(coord_labelled_grid, bbXYtable_full);

winopen(gridFolder); %important for 'data_science_v2.m' script

%% Prepare for attending analytical session
%Pre-requisite: Expert has worked in QuPath placing spots (editing pre-populated centroids)
%Output: To be opened in 'imageRegistration_v7.m' script

[coord_output3] = retrieve_optionA(qupath_dir, bbXYtable_full, destinationFile14);

%% Optional: forward registration, planned spots in grid

idx_content = ~any(ismissing(DB_sorted), 2);
planned_spots = DB_sorted(idx_content, {'X', 'Y', 'Label'});  %classifying_variable
    
planned_spot_info = DB_sorted{idx_content, display_variable}; %text   
temp_val = strsplit(sprintf('%.01f,', planned_spot_info), ',')';  %rounding text value
planned_spot_info2 = temp_val(1:end-1);

% planned_spots0 = stats6(:, {'X', 'Y', 'Label', display_variable}); %stats5
% planned_spots = planned_spots0( all(~ismissing(planned_spots0), 2), :);
% planned_spot_info = planned_spots{:, display_variable}; %text

%building input
planned_coord_input = [planned_spots.X, planned_spots.Y];
planned_coord_labels = planned_spots.Label;
planned_coord_labelled2 = [...
    double(planned_coord_labels), ...
    planned_coord_input];

[planned_coord_output] = slice_WMI_affine_coord(planned_coord_labelled2, bbXYtable_full);

[grid_info] = save_burned_grids(grid_info, class_grids, ...
    planned_coord_output, planned_spot_info2, spot_diameter, prev_suffix, labelOption);

%% Optional: backward registration, previously analysed spots in grid

% [A, ~, ~] = fileparts(folderWithOutputs); %backward registration data
% filename_10 = fullfile(A, 'processed_files', 'merged_7-apr.xlsx');
prev_spots = readtable(filename_10, 'VariableNamingRule','preserve');

prev_spot_info = prev_spots.Comment;
prev_coord_input = [prev_spots.X_reg, prev_spots.Y_reg];
prev_coord_labels = prev_spots.Grain;
prev_coord_labelled2 = [double(prev_coord_labels), prev_coord_input];

[prev_coord_output] = slice_WMI_affine_coord(prev_coord_labelled2, bbXYtable_full);

[grid_info] = save_burned_grids(grid_info, class_grids, ...
    prev_coord_output, prev_spot_info, spot_diameter, prev_suffix, labelOption);

%% Optional: Quality check plots

%check centroids
plot_original_check1(img_ref_fg2, coord_labelled2, 7) %n_std
plot_grid_check1(class_grids, coord_output, 1, 1) %class, grid

%check centroids/expert spots 
plot_original_check2(mountImage, coord_output3)%coord_output3 (if quPath)



