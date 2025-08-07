
%'merge_grids_v9.m'

%Script to import several grids from 'prototype_optionA_v2.m', merge them, and
%generate custom grids (age populations).

%This version gets feedback from the analysis in Fiftyone software.

%Created: 20-Apr-25, Marco Acevedo
%Updated: 23-Apr-24, 2-May-25, 12-May-25, 27-June-25, 28-July-25, M.A.

%%
clear 
clc

%Dependencies
scriptsFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts';
scriptsFolder1 = fullfile(scriptsFolder, "WMI/update_14-Jan-25/");
scriptsFolder2 = fullfile(scriptsFolder1, 'step2_grids');
scriptsFolder3 = fullfile(scriptsFolder1, 'step3_planning');
scriptsFolder4 = fullfile(scriptsFolder1, 'step3b_semi-automatic');
scriptsFolder5 = fullfile(scriptsFolder1, 'step6_documentation');
scriptsFolder6 = fullfile(scriptsFolder5, 'tblvertcat');
scriptsFolder7 = fullfile(scriptsFolder5, 'geochemistry_code');
scriptsFolder9 = fullfile(scriptsFolder5, 'fiftyone_link');
scriptsFolder8 = fullfile(scriptsFolder7, 'functions_plots/');

addpath(scriptsFolder);
addpath(scriptsFolder1) 
addpath(scriptsFolder2) 
addpath(scriptsFolder3) 
addpath(scriptsFolder4) 
addpath(scriptsFolder5) 
addpath(scriptsFolder6) 
addpath(scriptsFolder7) 
addpath(scriptsFolder8) 
addpath(scriptsFolder9) 

[temp, ~, ~] = fileparts(scriptsFolder7);
dbDir1 = fullfile(temp, 'geochemistry_db'); %for geochemistry db


%Merge grid databases
% User input
folders = {
    'D:\Justin Freeman collab\Marco Zircon_16bit\prototype2_work\qupath_project\output_test2\project_22-Apr-25\aspectRatio_1';    
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row1\project_22-Apr-25\knn_164';
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row2\project_22-Apr-25\knn_188';
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row3\project_22-Apr-25\knn_15';
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row4\project_22-Apr-25\knn_157';
};

expert_coordinates = {
    'E:\Feb-March_2024_zircon imaging\02_John Caulfield_files\CA-24MR_chemical data\puck 1\scan_list_output.xlsx';
    'E:\Feb-March_2024_zircon imaging\02_John Caulfield_files\CA-24MR_chemical data\puck 2\scan_list_output.xlsx'
    };

workingDir = "E:\Feb-March_2024_zircon imaging\00_Paper 4_Forward image registration\puck 1 and 2\merge_grid_test";
destinationFolder = 'project_6-Aug-25'; %output folder

trial_n = 1; %counter to avoid overwriting

%Script

n_folders = length(folders);

%Saving directory
destDir = fullfile(workingDir, destinationFolder);
mkdir(destDir)

%Read and merge grid databases
fileName1 = 'grid_info.mat';
fileName2 = 'boundingboxXY_full.mat';
inputType = load(fullfile(folders{1}, fileName1), 'grid_info').grid_info.inputType; %assumes consistency

%Load grids
merging_grid_files = cell(1, n_folders);
merged_gridCells = cell(1, n_folders);
for m = 1:n_folders
    temp1 = load(fullfile(folders{m}, fileName1), 'grid_info').grid_info.grid_files;
    [temp_gridCells] = load_grids_image(temp1); %image
    
    merging_grid_files{m} = temp1;
    merged_gridCells{m} = temp_gridCells;
end

for p = 1:n_folders-1
    item1 = p;
    item2 = p + 1;
    
    if p == 1
        DB_1 = load(fullfile(folders{item1}, fileName1), 'grid_info').grid_info.DB_sorted;
        BB_1 = load(fullfile(folders{item1}, fileName2), 'bbXYtable_full').bbXYtable_full;

        database_val1 = item1*ones(size(DB_1, 1), 1);
        DB_1 = addvars(DB_1, database_val1, 'NewVariableNames', 'Database', 'Before', 1);        
        BB_1 = addvars(BB_1, database_val1, 'NewVariableNames', 'Database', 'Before', 1);
    end
    DB_2 = load(fullfile(folders{item2}, fileName1), 'grid_info').grid_info.DB_sorted;    
    BB_2 = load(fullfile(folders{item2}, fileName2), 'bbXYtable_full').bbXYtable_full;
    
    database_val2 = item2*ones(size(DB_2, 1), 1);
    DB_2 = addvars(DB_2, database_val2, 'NewVariableNames', 'Database', 'Before', 1);
    BB_2 = addvars(BB_2, database_val2, 'NewVariableNames', 'Database', 'Before', 1);

    [DB_1, BB_1] = merge_two_grids(DB_1, DB_2, BB_1, BB_2);
end
DB_merged2 = DB_1;
BB_merged1 = BB_1;

%Medicine: variables that are no longer useful
DB_merged2.Image = []; %medicine
DB_merged2.BoundingBox = [];
DB_merged2.Centroid = [];
DB_merged2.X = []; 
DB_merged2.Y = []; %issues with Yttrium
% test = splitvars(DB_sorted_in); %prevents issues with indxing

%Medicine 1: filtering artefact ages from merged grid database
filtering_variable = 'Final Pb206-U238 age_mean';
values = DB_merged2{:, filtering_variable};
idx_real = (values > 0) & (values < 4543);
DB_merged2 = DB_merged2(idx_real, :);
BB_merged1 = BB_merged1(idx_real, :);

%Medicine 2: filtering other minerals (not zircon)
idx_zircon1 = (DB_merged2.Ti49_ppm_mean < 3000); %
idx_zircon2 = (DB_merged2.Zr91_ppm_mean > 300000);
idx_zircon = idx_zircon1 & idx_zircon2;
DB_merged2 = DB_merged2(idx_zircon, :);
BB_merged1 = BB_merged1(idx_zircon, :);

%Helper: getting image basenames
[~, basename1, ext1] = fileparts(DB_merged2.filename);
basename2 = strcat(basename1, ext1);
DB_merged2 = addvars(DB_merged2, basename2, 'NewVariableNames', 'path_basename', 'After', 'filename');

%% Master table geochemistry calculations

%Pre-requisite: setting up Python environment and OS environment variable paths.
path_python = "E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\WMI\update_14-Jan-25\step6_documentation\geochemistry_code\geochemistry_python\trial1";
path_Rscripts = "E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\WMI\update_14-Jan-25\step6_documentation\geochemistry_code\geochemistry_R";

%Run
script_path1 = fullfile(path_Rscripts, "script_isoplot_v2.R");
script_path2 = fullfile(path_Rscripts, "script_Carrasco.R");

sort0_variable = 'Final Pb206-U238 age_mean';
sort1_variable = 'age_isoplot'; %or 'Final Pb206-U238 age_mean' 
%sort1 is used for grid pre-classification

%Sort 0: by age
[~, sort_idx2] = sortrows(DB_merged2, {sort0_variable}, {'ascend'});
DB_sorted_age = DB_merged2(sort_idx2, :); %sorting 0
BB_merged2_master0 = BB_merged1(sort_idx2, :); %follows

%Database
file_db1 = fullfile(dbDir1, 'mcdonough_and_sun_1995.txt'); %chondrite normalisation

%R
[table_calculations2] = geochemistry_isoplot_1(DB_sorted_age, destDir, script_path1); %Vermeesch, KDE and age
[table_calculations5] = geochemistry_calculation4(DB_sorted_age, destDir, script_path2); %Carrasco-Godoy, impute REE
%Python
[table_calculations4] = geochemistry_calculation3(DB_sorted_age, destDir, path_python); %Anenburg and Williams, lambdas, Ti-temp, ratios
[table_calculations6] = geochemistry_calculation5(DB_sorted_age, destDir, path_python); %Aitchison, pyrolite CLR
%MatLab
[table_calculations3] = geochemistry_calculation2(DB_sorted_age, file_db1); %Pizarro
[table_calculations1a] = geochemistry_calculation1a(DB_sorted_age); %Allen C., apfu
[table_calculations1b] = geochemistry_calculation1b(DB_sorted_age, table_calculations2); %Allen C., ratio ages and geochemistry

table_temp = [DB_sorted_age, table_calculations1b]; 
[table_calculations1c, table_AND] = geochemistry_calculation1c(table_temp); %Allen C., mineral inclusion filters

%Appending
DB_sorted_in_master0 = [DB_sorted_age, ...
    table_calculations1a, table_calculations1b, table_calculations1c, ...
    table_calculations2, ...
    table_calculations3, table_calculations4, table_calculations5, ...
    table_calculations6
    ];

[dictionary1] = data_completion(DB_sorted_in_master0, destDir); %new dictionary

%Sort 1: by isoplot age
[~, sort_idx_prime] = sortrows(DB_sorted_in_master0, {sort1_variable}, {'ascend'});
DB_sorted_in_master = DB_sorted_in_master0(sort_idx_prime, :); %sorting 1
BB_merged2_master = BB_merged2_master0(sort_idx_prime, :); %follows

%% Optional: Fiftyone link (in development..)

%User input
path_dictionary = "C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\appended_DB_dictionary_v2_Marco.xlsx";
trial_name = 'Talk2'; %must be the ultimate name for further data analysis
pctOut_colour = .5; %boost colours, 2

[table_UMAP, table_Display, first_numeric] = chosen_table_type2(DB_sorted_in_master, path_dictionary, trial_name);

outputFile = fullfile(destDir, strcat(trial_name, '_embedding.xlsx'));
writetable(table_UMAP, outputFile, 'WriteMode', 'overwrite');

[db_labels_table, newFolder2] = generate_fiftyoneDB_v2(table_Display, first_numeric,...
    trial_name, pctOut_colour, destDir);

newFolder3 = strcat(newFolder2, '_grid');
mkdir(newFolder3)

%% User input: Custom merged grids (second part of script)

age_intervals = [...
     [-Inf, 142.7]; %Population 1: Youngest
     [201.4, 301.4]; %Population 2: Permo-Triassic
     [980, 1300]; %Population 3: Grenville
     [1827.66, Inf] %Population 4: Oldest
     ]; 

%Pre-classification 
n_classes = 1; %default= 4; equal populations
sort2_variable = 'age_isoplot'; %might also be display_variable
sort_direction = 'ascend'; %'ascend', 'descend'
display_variable = sort2_variable; %for burned grids text; sort2_variable

%Grid slicing, saving, and collaging settings (grids)
nrows = 16; %4
nGrids = 1;
chosen_bb_variable = 'MaxFeretDiameter';
scale = 75; %default= 75 pct of largest grain dim (bounding box)
orientation = 'vertical';
sel_pattern = [4, 1]; %snake [4, 1]; MatLab default = [2, 1] 
sel_interpolation = 'linear';

burnOption = 1; %for labels
labelOption = 1; %for spots (time consuming)
pixel_size = 0.25; %microns/px
spotSize= 25; %in microns

sample_str = ''; %edit (folder name)

%Filter database (puck 1 = 1; puck 2 = 2, 3, 4, 5)
idx_sample = (DB_sorted_in_master.Database == 1);
DB_sorted_in = DB_sorted_in_master(idx_sample, :); %overwrite
BB_merged2 = BB_merged2_master(idx_sample, :);

%% Image processing loop

% DB_sorted_in = DB_sorted_in_master; %overwrite for all
% BB_merged2 = BB_merged2_master;

spot_diameter = 2*spotSize/pixel_size; 

%For fast computation:
burnOption = 0;
labelOption = 0;
spotOption = 0; 

temp_values = DB_sorted_in{:, sort1_variable}; %for filtering

%Script 
trial_n = trial_n + 1; %avoid overwriting

n_bins = size(age_intervals, 1);
str_temp = strsplit(sprintf('Population_%02.f,', 1:n_bins), ','); 
age_populations = str_temp(1:end-1);

gridFolder = fullfile(destDir, strcat(sort1_variable, '_', sort2_variable, '_', num2str(trial_n)) ) %classifying_variable
mkdir(gridFolder)
winopen(gridFolder); %important for 'data_science_v2.m' script

%Auxiliary calculations
array = DB_sorted_age{:, chosen_bb_variable};
% [bb_width, bb_height] = generic_bb(array, scale, orientation); %scale in percentage
bb_width = 50;
bb_height = 2*bb_width;
% bb_width = 160; %squared
% bb_height = bb_width;

%Grid config (common)
mergedGrid_info = struct;
mergedGrid_info.inputType = inputType;
mergedGrid_info.n_classes = n_classes;
mergedGrid_info.bb_height = bb_height;
mergedGrid_info.bb_width = bb_width;
mergedGrid_info.chosen_bb_variable = chosen_bb_variable;
mergedGrid_info.sel_pattern = sel_pattern;

% Major loop to generate custom grids
grid_files = cell(1, n_bins);
for ii = 1:n_bins %1:n_bins

    %Basic info
    str_interval = age_populations{ii};       
    gridFolder2 = fullfile(gridFolder, str_interval);
    mkdir(gridFolder2)
    
    fileName4 = 'boundingboxXY.xlsx'; %grid
    fileName8 = 'grid_info.mat';
    destinationFile4 = fullfile( gridFolder2, fileName4); %table of bb for SuperSIAT collage
    destinationFile4_full = strrep(destinationFile4, '.xlsx', '_full.mat');
    destinationFile8 = fullfile( gridFolder2, fileName8); %grid_info
    suffix = 'ageBins';
    prev_suffix = strcat(suffix, '_burnedSpot');    
    
    %Filtering and sort 2 (within age-bin)       
    temp_idx = ( temp_values > age_intervals(ii, 1) ) & ( temp_values < age_intervals(ii, 2) );
    DB_sorted_in2 = DB_sorted_in(temp_idx, :); %filtering
    [~, sort_idx3] = sortrows(DB_sorted_in2, {sort2_variable}, {sort_direction});        
    DB_sorted_in3 = DB_sorted_in2(sort_idx3, :); %sorting 2
        
    BB_merged3 = BB_merged2(temp_idx, :); %follows
    BB_merged4 = BB_merged3(sort_idx3, :);
    
    %Pre-classifying (generates 'Group' column)
    [DB_sorted, populationBand] = sorting_grainDB_importedIdx(DB_sorted_in3, n_classes);   
  
    %Grid configuration update
    mergedGrid_info.dest_folder_grid = gridFolder2; %sourceFolder
    mergedGrid_info.DB_sorted = DB_sorted; %2 GB
    mergedGrid_info.populationBand = populationBand; %important
    
    [mergedGrid_info, ~] = grid_configuration_custom(mergedGrid_info, nrows, nGrids);
    % mergedGrid_info
    
    %%Generate grids  
    
    [class_grids, bbXYtable_merged] = collaging_grid_affine( merged_gridCells, BB_merged4, ...
        mergedGrid_info, orientation, sel_interpolation, burnOption);
    
    [mergedGrid_info] = save_grids(mergedGrid_info, class_grids, suffix); %updates

    %Save metadata
    save(destinationFile8, 'mergedGrid_info', '-mat', '') %heavy for saving
    save(destinationFile4_full, 'bbXYtable_merged', '-mat','-v7.3')

    %Optional: Save isoplot plots 
    [~] = geochemistry_isoplot_1(DB_sorted, gridFolder2, script_path1); %optional
    % similar_interval = [222.9, 247];
    % similar_idx = (data_table4.)

    %info
    [folder_temp, ~, ~] = fileparts(destinationFile8);
    grid_files{ii} = destinationFile8;
    
    %%Optional: forward registration, planned spots in grid
    
    idx_content = any(~ismissing(DB_sorted), 2);
    planned_spots = DB_sorted(idx_content, {'X_grid', 'Y_grid', 'Database', 'Label'});  %classifying_variable
    
    planned_spot_info = DB_sorted{idx_content, display_variable}; %text   
    temp_val = strsplit(sprintf('%.00f,', planned_spot_info), ',')';  %rounding %.01f
    planned_spot_info2 = temp_val(1:end-1);
    
    %building input
    planned_coord_input = [planned_spots.X_grid, planned_spots.Y_grid];
    planned_coord_databases = planned_spots.Database;
    planned_coord_labels = planned_spots.Label;
    planned_coord_labelled2 = [...
        double(planned_coord_databases), ...
        double(planned_coord_labels), planned_coord_input];
    
    [planned_coord_output] = collaging_grid_affine_coord(planned_coord_labelled2, bbXYtable_merged);        
       
    [mergedGrid_info] = save_burned_grids(mergedGrid_info, class_grids, ...
        planned_coord_output, planned_spot_info2, spot_diameter, prev_suffix, labelOption);

    % [mergedGrid_info] = save_burned_patches(mergedGrid_info, class_grids, bbXYtable_merged, ...
    %     planned_coord_output, planned_spot_info2, spot_diameter, spotOption, labelOption, newFolder3);
    % %Note: save_burned_patches still is inefficient for re-slicing large grids
    
end
beep

%% Calculate statistics
DB_sorted.initial_U

interrogation_columns = {
    'Convexity', 'MeanIntensity_V',...
    'ratio_Zr_Hf', 'Hf177_ppm_mean', 'P31_ppm_mean',...
    'Y89_ppm_mean', 'Yb172_ppm_mean', 'initial_U',...
    'Ti49_ppm_mean', ...
    'ratio_iTh_iU', 'Dy_Yb_ratio', 'ratio_totalREE_P_mol', ...
    'Eu_ratio', 'Ce_Nd_ratio', 'ratio_CeUTi', 'lambda_3', ...
    }; 

%Naming for Figure (latex interpreter)
formal_name = {
    'Shape convexity', 'CL intensity (HSV)', ...
    'Zr/Hf', 'Hf (ppm)', 'P (ppm)',...
    'Y (ppm)', 'Yb (ppm)', 'initial U (ppm)',...
    'Ti (ppm)', ...
    'initial Th/U', 'Dy/Yb', '(REE+Y)/P mol', ...
    'Eu anomaly', 'Ce anomaly', 'Ce/$\sqrt{initial\ U*Ti}$', 'Lambda 3'
    };

%Geochemical interrogation
number_bins = 8;

n_interrogation = length(interrogation_columns);
population_stats = cell(n_bins, n_interrogation);
population_kde = cell(n_bins, n_interrogation);
for ii = 1:n_bins  %1:n_bins 

    load(grid_files{ii});
    DB_sorted = mergedGrid_info.DB_sorted;
    
    %Save for post-processing
    gridFolder2 = mergedGrid_info.dest_folder_grid;
    destinationFile9 = fullfile( gridFolder2, 'population_data.xlsx');
    writetable(DB_sorted, destinationFile9)

    %Subsetting (finding inclusion-bearing spots)
    idx_bad1 = all(DB_sorted{:, {'Al27_fail', 'La139_fail', 'Ti49_fail'}}, 2);
    idx_bad2 = DB_sorted{:, {'Ti49_fail'}};
    idx_good = ~(idx_bad1 | idx_bad2);
    DB_sorted2 = DB_sorted(idx_good, :);    

    for p = 1:n_interrogation

        temp_variable = interrogation_columns{p};
        temp_array = DB_sorted2{:, temp_variable};
        %Note: no need for capping if removing inclusion-bearing spots

        %Histograms
        [N_counts, ~] = histcounts(temp_array, number_bins); %automatic
        [N, edges] = histcounts(temp_array, number_bins, 'Normalization','pdf');        
        sum_population = sum(N_counts);
        info_histogram = [[0, N]; edges];

        %KDE
        [f1, xf1] = kde(temp_array);        
        
        population_stats{ii, p} = {sum_population, info_histogram};
        population_kde{ii, p} = {f1, xf1};
    end

end

%Note: save them as SVG
plot_population_histograms(age_populations, population_stats, population_kde, formal_name)
plot_population_KDEs(interrogation_columns, age_populations, population_stats, population_kde, formal_name)