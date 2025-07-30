

%% User input

currentPath = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\Feb-March_2024_zircon imaging\Marco_modified scripts\bigWarp_matlab';
functionsPath = fullfile(currentPath, 'functions');
javaPath = fullfile(currentPath, 'java_files/classes');

addpath(functionsPath); 
javaaddpath(javaPath)
javaaddpath(fullfile(javaPath, '/dependency/ejml-0.24.jar'));
javaaddpath(fullfile(javaPath, '/dependency/opencsv-4.6.jar'));
javaaddpath(fullfile(javaPath, '/dependency/commons-lang3-3.8.1.jar'));
javaaddpath(fullfile(javaPath, '/dependency/imglib2-realtransform-2.2.1.jar'));
javaaddpath(fullfile(javaPath, '/dependency/imglib2-5.6.3.jar'));

%data
sourceDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\Feb-March_2024_zircon imaging\OneDrive_1_06-03-2024\';
landmarkFile_input = fullfile(sourceDir, '\ECU_907_908_CL_landmarks_noScale.csv');
pointFile_input = fullfile(sourceDir, '\qupath_annotation_test\allGrains_xy.csv');
pointFile_output = strrep(pointFile_input, '.csv', '_warped.csv');

%% Script

%Read landmarks
[landmarksFolder, landmarksFile, ext] = fileparts(landmarkFile_input);
landmarksPath = fullfile(landmarksFolder, strcat(landmarksFile, ext));

z_value = 10000; %make this value sufficiently large to avoid 'singular matrix' issue
landmarks = Landmarks2Array_2D(landmarksPath, z_value);
n_landmarks = size(landmarks, 1);
movingLandmarks = landmarks(:, 1:3); %for affine
fixedLandmarks = landmarks(:, 4:6);

%Read points to transform
xy_input = readmatrix(pointFile_input);
n_points = size(xy_input, 1);
originalLattice = [xy_input, ones([n_points, 1])*z_value];

%Apply BigWarp TPS transform to the point lattice
fprintf("Calculating nonlinear transform...\n")
TPSLattice = ApplyBigWarpTrans(landmarksPath1, originalLattice, 1000, 0.01); %iterations and error

%Measure non-linear warp distance for landmarks and point lattice
fprintf("Calculating best fit linear transform...\n")

[linearLandmarks, linearTransMat] = ApplyBestFitAffineTrans(movingLandmarks, fixedLandmarks);
%Warning: Rank deficient, rank = 3, tol =  3.425931e-11. 
nonlinearLandmarkWarpDists = FindDistances(linearLandmarks, fixedLandmarks);

linearLattice = ApplyAffineTrans(originalLattice, linearTransMat);
nonlinearLatticeWarpDists = FindDistances(linearLattice, TPSLattice);

%Saving x-y (drop z)
TPSLattice2 = TPSLattice(:, 1:2);
writematrix(TPSLattice2, pointFile_output)

