
workingDir = 'E:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\row3_BSE_t-grid\SIFT_aligned_std';
% workingDir = 'E:\Justin Freeman collab\Marco Zircon\LayersData\Layer\output_combined_BSE_t-position_withBSE\SIFT_aligned_MIP_std';

fileName_1 = 'TileConfiguration.txt'; %input from Stitching (without compute overlap)
% fileName_1 = 'TileConfiguration.registered.txt'; %input from Stitching (compute overlap)
% fileName_2 = 'registered2.txt'; %intermediate input

%Dependencies
scripts1 = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
scriptPath1 = fullfile(scripts1, 'distCorr/');
addpath(scriptPath1)

filepath1 = fullfile(workingDir, fileName_1);
% filepath2 = fullfile(workingDir, fileName_2);

adapter_st(filepath1)

%%

adapter_ts(filepath2)