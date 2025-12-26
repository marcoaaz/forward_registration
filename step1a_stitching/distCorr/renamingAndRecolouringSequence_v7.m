clc
clear

%Script to recolour a SEM-BSE image from greyscale to RGB following a
%16-bit Multi-Otsu threshold suggestion in log-scale. In the idea output,
%no mineral should be left with under- or over-saturated pixels

%Updated: 21-May-24, Marco Acevedo


%Root folder (channels)
rootFolder = 'C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\HR_BSE_41\HR_BSE_41';
sample = ''; %type
destination = 'result_V1';

%********script***********
parentDir = fullfile(rootFolder, sample);
destDir = fullfile(parentDir, destination);
mkdir(destDir)

cd(parentDir);
scriptsFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
scriptsFolder2 = 'E:\Alienware_March 22\current work\00-new code May_22';

addpath(scriptsFolder);
addpath(fullfile(scriptsFolder, '\bfmatlab')) %bio-formats 
addpath(fullfile(scriptsFolder, '\distCorr'))
addpath(fullfile(scriptsFolder, '\distCorr\montageInteractive\'))
addpath(scriptsFolder2);
addpath(fullfile(scriptsFolder2, '\rayTracing'));

%Saving directory
destination2 = 'rgb_debug';
destDir2 = fullfile(destDir, destination2);
mkdir(destDir2)

% source = 'renamed';
% 
% parentDir = fullfile(rootFolder, sample);
% sourceDir = fullfile(parentDir, source);
% mkdir(sourceDir)
% cd(parentDir);


%e.g.: 
%'Image%3f.tif'
%'TileScan_003--stage%2f.tif';        
%'TileScan_001--Stage%3d.tif'
%'tile_x%3d_y%3d.tif'
%'TileScan_001--Stage00.tif'
%'PPL_%dof9.tif'
%'XPL\d*_of_9.tif'
%'tile_\d*.tif'
%'#1_\d*_\d*.tif';
%'Tile_\d*_\d*.tif';

%% Understand Montage configuration

%Grids (assumes names are sorted)
structure_temp = struct2table(dir(fullfile(rootFolder, '*.tif')));
folder_temp = fullfile(structure_temp.folder, structure_temp.name); %cell if >1 length

file_temp = structure_temp.name;

%Parse filename
expression1 = '#1_(?<x>\d+)_(?<y>\d+).tif'; %edit
temp_str = regexp(file_temp, expression1, 'names');
temp_str2 = struct2table([temp_str{:}]);
regex_idx = ~cellfun('isempty', regexp(file_temp, expression1,'match','once') ) ;

x = str2double(temp_str2.x);
y = str2double(temp_str2.y);
n_tile_rows = max(y) + 1; %TIMA index to MatLab
n_tile_cols = max(x) + 1;
dim = [n_tile_rows, n_tile_cols]; %e.g.: [rows, cols]; interpreting montage

%table for sorting
temp_str2.x = x;
temp_str2.y = y;
tile_info = addvars(temp_str2, folder_temp(regex_idx), 'NewVariableNames', 'path');

tile_info2 = sortrows(tile_info, {'x', 'y'}, {'ascend', 'ascend'});
fileNames_sorted = tile_info2.path;

rescaleOption = 0; %yes/no (keep original bitdepth)
targetBit = 8; % or any other lower bit scale
saveOption = 1; %optional: tile saving not useful for recolouring
n_bins = 256; %default= 8-bit; histogram intervals

%Tiling sequence
%e.g.: 'column-by-column'=2; 'down & right'=1
%e.g.: 'row-by-row'=1; 'right & down'=1
%e.g.: 'snake-by-rows'=3; 'right & down'=1


fprintf('Reference grid sequence:\n')
[referenceGrid, ~] = gridNumberer(dim, 2, 1); %Type, Order

fprintf('Desired grid sequence:\n')
[desiredGrid, ~] = gridNumberer(dim, 1, 1); %1,1 preferred by TrakEM2

%serial tile naming
position_ind = desiredGrid(referenceGrid(:)); 
tileNames = sprintf('tile_%04d.tif,', position_ind);
%e.g.: %02d wont be properly read by TrakEM2 after >100 tiles

tileNames1 = strsplit(tileNames, ',');
fileNames_renamed = tileNames1(1:end-1);

%info
n_images = length(fileNames_sorted);
temp_info = imfinfo(fileNames_sorted{1});
n_rows = temp_info.Height; %1024
n_cols = temp_info.Width;
imgDim = [n_rows, n_cols];
%Apply medicine: if image comes with burned scale or legend

%Begin storing info
mosaicInfo.fileNames_sorted = fileNames_sorted; %reside in parentDir
mosaicInfo.fileNames_renamed = fileNames_renamed;
mosaicInfo.n_images = n_images;
mosaicInfo.imgDim = imgDim;
mosaicInfo.mosaicDim = dim;
mosaicInfo.referenceGrid = referenceGrid;
mosaicInfo.desiredGrid = desiredGrid;

tic;
%Tile stats (mandatory)
filePaths_renamed = fullfile(destDir, fileNames_renamed);

%update mosaic info with stats
[mosaicInfo] = montageSaveRenamedTiles(mosaicInfo, ...
    targetBit, rescaleOption, saveOption, filePaths_renamed);

save(fullfile(destination, 'mosaicInfo.mat'), "mosaicInfo", '-v7.3');

t.tileStats = toc;

%% Stacking tile histograms
%8-bit: [0, 255], 16-bit: [0, 65535]
close all

TH_array = [0, 65535]; 
% default=[mosaicInfo.mosaic_min, mosaicInfo.mosaic_max]

tic;

[mosaic_edges, mosaic_counts, mosaic_counts_log] = ...
    montageHistogramStacking(mosaicInfo, TH_array, n_bins);

t.tileHistogram = toc;

%Multi-level TH: Automatic suggestion from log-scaled histogram
N = 3; %requested thresholds
[thresh_h, metric_h] = multiTH_extract(mosaic_counts_log, N, mosaic_edges);

%Plot histogram and suggested thresholds
montageLogHistogram(mosaic_edges, mosaic_counts, mosaic_counts_log, thresh_h, destDir2)

%% Forming RGB scroll
close all force

th_split = [28004, 46800]; %manual for BSE; =thresh_h for hyperspectral

[split_parameters] = montageSplitTH(mosaic_edges, th_split, destDir2);

% %%Single tile check-up
% sel_image = floor((mosaicInfo.n_images)/2) + 11;
% filterSize = 5;
% [img_med] = recolouredTile(sel_image, mosaicInfo, mosaic_edges, ...
%     split_parameters, filterSize, destDir2);

% th_manual = [12904, 13500]; %manual for BSE; =thresh_h %for hyperspectral

tileColourCheck(mosaicInfo, mosaic_edges, split_parameters, th_split)

%% Saving mosaic tiles (if happy)

filterSize = tunnedParameters.filterSize;
split_parameters = tunnedParameters.split_parameters;
split_table = array2table(split_parameters);
split_table.Properties.VariableNames = {'From', 'To', 'Range', 'multiplyFactor', 'binWidth'};
tunnedParameters.split_table = split_table;

save(fullfile(destDir2, 'recolouringMetadata.mat'), "tunnedParameters")

tic;

montageSaveRecolouredTiles(mosaicInfo, mosaic_edges, split_parameters, filterSize, destDir2);

t.tileRecolouredSave = toc;
t
%the pipeline continues in TrakEM2 for montaging RGB tiles
