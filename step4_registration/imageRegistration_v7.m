
%imageRegistration_v4.m

%Script to register the spot table of virtual analytical spots into a
%master table that can be read by Chromium software (Teledyne) platform

%Created: 30-Apr-24, M.A. Supports
%Updated: 24-Mar-25, M.A. Supports pipeline with Option 1 and 2.

%% Preparation

close all
clear
clc

%dependencies
%For laptop Alienware X15
scriptDir0 = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\WMI\update_14-Jan-25';
scriptDir1 = fullfile(scriptDir0, 'step4_registration');

%for BigWarp
currentPath = fullfile(scriptDir0, '\bigWarp_matlab');
functionsPath = fullfile(currentPath, 'functions');
javaPath = fullfile(currentPath, 'java_files/classes');

addpath(scriptDir0) %Own scripts
addpath(scriptDir1)
addpath(functionsPath); %BigWarp
javaaddpath(javaPath)
javaaddpath(fullfile(javaPath, '/dependency/ejml-0.24.jar'));
javaaddpath(fullfile(javaPath, '/dependency/opencsv-4.6.jar'));
javaaddpath(fullfile(javaPath, '/dependency/commons-lang3-3.8.1.jar'));
javaaddpath(fullfile(javaPath, '/dependency/imglib2-realtransform-2.2.1.jar'));
javaaddpath(fullfile(javaPath, '/dependency/imglib2-5.6.3.jar'));
%%
%User input
experimentName = 'May20_trial1'; %name for saving *.scancsv file
main_folder = 'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\chromium';
% files2 = {
%     "D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row1\project_31-Mar-25\knn_164\option1_spot_table.xlsx",...
%     "D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row2\project_31-Mar-25\knn_188\option1_spot_table.xlsx",...
%     "D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row3\project_31-Mar-25\knn_15\option1_spot_table.xlsx",...
%     "D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row4\project_31-Mar-25\knn_157\option1_spot_table.xlsx"
%     };
files2 = {
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row1\project_22-Apr-25\knn_164\option1_spot_table.xlsx';
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row2\project_22-Apr-25\knn_188\option1_spot_table.xlsx';
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row3\project_22-Apr-25\knn_15\option1_spot_table.xlsx';
    'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\CL_28-Mar-25_row4\project_22-Apr-25\knn_157\option1_spot_table.xlsx'
    };

%planned spots for all samples (landmarks and planned spots)
sample_name = {
    'CA24MR_1_second_row1',...
    'CA24MR_1_second_row2',...
    'CA24MR_1_second_row3',...
    'CA24MR_1_second_row4'
    }; %corresponding sample name for the output

basenames1 = {
    'landmarks_row1.csv',...
    'landmarks_row2.csv',...
    'landmarks_row3.csv',...
    'landmarks_row4.csv',...
    };

%control points for registration #2

%Full resolution flatbed scanner (navigate coordinates in ImageJ)
movingImage = [
   16306, 15387;
   16079, 15803;
   16193, 17221;
   19074, 17155;
   19058, 15487;
   17347, 15796;
   17708, 16779

    ]; 

%Chromium software coordinates (mm)
fixedImage = [
    70.005, 74.272, 20.981;
    68.835, 76.509, 20.981;
    69.539, 83.973, 20.981;
    84.712, 83.438, 20.963;
    84.493, 74.630, 20.963;
    75.518, 76.362, 20.963;
    77.499, 81.555, 20.963

    ]; 

%Script begins
workingDir = fullfile(main_folder, 'registration_intermediateFiles');
destDir1 = fullfile(workingDir, 'control_points');
destDir3 = fullfile(workingDir, 'control_points_temp');
mkdir(workingDir)
mkdir(destDir1)
mkdir(destDir3)
cd(workingDir)

files1 = fullfile(destDir1, basenames1); %landmarks
n_files = length(files1); %must correspond to files2

%%
filePath_cp_reg2 = fullfile(workingDir, 'cp_reg2.csv'); %output/input
filePath_spot_reg1 = fullfile(workingDir, 'spot_reg1.csv'); %intermediate
filePath_spot_reg2 = fullfile(workingDir, 'spot_reg2.csv'); %intermediate
filePath_spot_reg3 = fullfile(workingDir, 'spot_reg3.csv'); %intermediate
file_to_python = fullfile(workingDir, 'option2_TPS.csv'); %intermediate
file_from_python = fullfile(workingDir, 'nodeVector.csv'); %input
filePath = fullfile(workingDir, experimentName); %output (scancsv file)

fixed_avg = mean(fixedImage, 1);
% fixedImage(:, 3) = fixed_avg(3); %ignoring z (almost the same)

n_cp = size(movingImage, 1) %should be ~20 points
scale_debug = 1000; %prevents degenerate solution

%Custom laser parameters
value = struct;
%parameters: ablation
value.dosage = 1; value.dwellTime = 1; value.lineSpacing = 100; 
value.laserOutput = 19.2; value.laserFluence = 0.67; value.lineScanMode = 1; value.passCount = 1;
value.laserRepRate = 10; value.scanSpeed = 50; value.passEnabled = 0; value.shotCount = 10; 
value.spotSpacing = 100; value.laserSpotSize = 25; value.laserSpotRotation = 0; value.zDepth = 0;

%parameters: pre-ablation
value.dosage2 = 1; value.dwellTime2 = 1; value.lineSpacing2 = 1; 
value.laserOutput2 = 24; value.laserFluence2 = 0.83; value.lineScanMode2 = 1; value.passCount2 = 1;
value.laserRepRate2 = 8; value.scanSpeed2 = 1; value.passEnabled2 = 1; value.shotCount2 = 240; 
value.spotSpacing2 = 1; value.laserSpotSize2 = 25; value.laserSpotRotation2 = 0; value.zDepth2 = 0;

%% Pre-check Registration 2 control points (might prevent failure)

close all
numBins = 15;

hFig = figure;
hFig.Position = [100, 100, 1800, 600];
subplot(1, 3, 1)
histogram(movingImage(:, 1:2), 'NumBins', numBins)
title('Moving: Holder scan')
grid on
subplot(1, 3, 2)
histogram(fixedImage(:, 1:2), 'NumBins', numBins)
title('Fixed: Stage coordinates')
grid on
subplot(1, 3, 3)
histogram(fixedImage(:, 3), 'NumBins', 65)
title('Fized Z values')
grid on

%Control points in stage

fixedLandmarks = fixedImage*scale_debug;
markerSize = 20;
offset_val= 1000;
fontWeight = 'bold';

figure('units', 'normalized', 'outerposition', [0 0 1 1])

plot3(fixedLandmarks(:, 1), fixedLandmarks(:, 2), fixedLandmarks(:, 3), ...
    'x', 'Color', 'red', 'MarkerSize', markerSize, ...
    'DisplayName', 'Fixed cp')
text(fixedLandmarks(:, 1) + offset_val, ...
    fixedLandmarks(:, 2)  + offset_val, ...
    fixedLandmarks(:, 3), strsplit(num2str(1:n_cp)), ...
    'Color', 'red', 'FontSize', 12, 'FontWeight', fontWeight, ...
    'HorizontalAlignment', 'left')
hold off

grid on
pbaspect([1 1 1])
legend('Location','northeast')
title('Registration 2 pre-check')

%% Feedback required: Fixing issues

% selected_cp = [1, 5, 10, 14, 3, 11, 8, 16]; %1:n_cp
selected_cp = 1:n_cp;
z_value_reg2 = 2*(fixed_avg(3)*scale_debug); %assumed =2K, 20K reaches real values
z_value_reg1 = z_value_reg2;%default= 10000, value sufficiently large to avoid 'singular matrix' issue

%Parametrisation
% max_iters = iterations for the transformation (min = 50)
% inv_tol = acceptable error on the inverse calculation.

n_iterations_reg1 = 10000; %default= 10K, registration #1 runs 3 min
n_iterations_reg2 = 25000; %default= 50K, registration #2 for 10K points runs 30 min
inv_tol_reg1 = .1;
inv_tol_reg2 = .1; %min= 0.1, default= 0.01

%% Registration 2: generating landmark file for Big Warp TPS registration 
%needs saving all spots, not only selected (experiment metadata reproducibility)

n_cp_sel = length(selected_cp);
movingLandmarks_pre = [movingImage, z_value_reg2*ones(n_cp, 1)]; 
fixedLandmarks_pre = fixedImage*scale_debug;
movingLandmarks = movingLandmarks_pre(selected_cp, :);
fixedLandmarks = fixedLandmarks_pre(selected_cp, :);

col1 = strsplit(sprintf('Pt-%.f,', 1:n_cp_sel), ',')';
col1_1 = cellstr(col1(1:end-1));
col2 = string(repmat('TRUE', [n_cp_sel, 1]));
col_data = array2table([movingLandmarks, fixedLandmarks]);
cp_table = addvars(col_data, col1_1, col2, 'Before', 1);

writetable(cp_table, filePath_cp_reg2, 'WriteVariableNames', false)

%% Registration 1 (for each sample)
%Moving (CL image) to Fixed (Holder scan)

%Moving: Annotation files: ECU_905_906_CL.tif.geojson
%Landmark files: ECU_905_906_CL_landmarks

master_table = [];
for i = 1:n_files
    
    %Landmarks (from BigWarp)        
    [~, landmarksPath1] = Landmarks2Array_2D(files1{i}, z_value_reg1); 
    %assumed flat z (equal for both)    
    temp_table = readtable(landmarksPath1); %control point table
    movingLandmarks_reg1 = temp_table{:, 3:5};
    fixedLandmarks_reg1 = temp_table{:, 6:8};    
    
    %Moving: Planned spots (from option 1= QuPath/ option 2= SuperSIAT)    
    spot_table = readtable(files2{i});    
    n_spots = size(spot_table, 1);               
    z_fake =  ones([n_spots, 1])*z_value_reg1;
    originalLattice = [spot_table.X, spot_table.Y, z_fake]; %assuming all from the same grid    

    %Warp with Thin plate spline (TPS)
    registeredLandmarks_reg1 = ApplyBigWarpTrans(landmarksPath1, movingLandmarks_reg1, n_iterations_reg1, inv_tol_reg1);
    TPSLattice = ApplyBigWarpTrans(landmarksPath1, originalLattice, n_iterations_reg1, inv_tol_reg1); 
    
    %print error
    error_matlab = fixedLandmarks_reg1 - registeredLandmarks_reg1; %in pixels
    A = error_matlab;
    intro_str = char(strcat(sample_name{i}, {' '}, 'alignment error matrix is: \n '));
    sprintf([intro_str strrep(mat2str( round(A, 4) ),';','\n ')])

    %Build master table
    sampleName = repmat(sample_name{i}, [n_spots, 1]);    
    
    spot_table1 = addvars(spot_table, sampleName, 'Before', 1);
    spot_table3 = addvars(spot_table1, TPSLattice(:, 1), TPSLattice(:, 2), ...
        'NewVariableNames', {'x_reg1', 'y_reg1'}, 'After', size(spot_table1, 2));    

    master_table = vertcat(master_table, spot_table3);
end
writetable(master_table, filePath_spot_reg1)

%% Registration 2 (for all samples)
%Moving (Holder scan) to Fixed (Stage coordinates)
%Note: 10K points in 30 min, depending on warping filed estimation

master_table_reg1 = readtable(filePath_spot_reg1, "Delimiter", ',');
n_spots2 = size(master_table_reg1, 1);
z_fake2 = z_value_reg2*ones(n_spots2, 1); 
originalLattice2 = [master_table_reg1{:, {'x_reg1', 'y_reg1'}}, z_fake2];

%Estimating transform
registeredLandmarks = ApplyBigWarpTrans(filePath_cp_reg2, movingLandmarks, n_iterations_reg2, inv_tol_reg2);
registeredLattice = ApplyBigWarpTrans(filePath_cp_reg2, originalLattice2, n_iterations_reg2, inv_tol_reg2);
%Note: z is still is estimated (probably not accurate)

%Info: print error
error_matlab = fixedLandmarks - registeredLandmarks; %in pixels
A = error_matlab;
intro_str = 'For each control point, the alignment error was: \n ';
sprintf([intro_str strrep(mat2str( round(A, 4) ),';','\n ')])

%Append to master table
master_table_reg2 = addvars(master_table_reg1, ...
    registeredLattice(:, 1), registeredLattice(:, 2), registeredLattice(:, 3), ...
    'After', 'y_reg1', 'NewVariableNames', {'x_reg2', 'y_reg2', 'z_reg2'});
writetable(master_table_reg2, filePath_spot_reg2)

%Write file for Python script 
n_spots2 = size(master_table_reg2, 1);
x = master_table_reg2.x_reg2;
y = master_table_reg2.y_reg2;
X = [x, y];
writematrix(X, file_to_python); 
file_to_python

%% Registration #2 (quality check)

markerSize = 20;
offset_val= 1000;
fontWeight = 'bold';

close all

figure('units', 'normalized', 'outerposition', [0 0 1 1])

plot3(registeredLattice(:, 1), registeredLattice(:, 2), registeredLattice(:, 3), ...
    '.', 'Color', 'blue', 'MarkerSize', markerSize/4,...
    'DisplayName', 'Registered spots')
hold on
% plot3(originalLattice(:, 1), originalLattice(:, 2), originalLattice(:, 3), ...
%     '.', 'Color', 'magenta', 'MarkerSize', markerSize/4,...
%     'DisplayName', 'Original spots')
plot3(registeredLandmarks(:, 1), registeredLandmarks(:, 2), registeredLandmarks(:, 3), ...
    '+', 'Color', 'green', 'MarkerSize', markerSize, ...
    'DisplayName', 'Moving cp')
plot3(fixedLandmarks(:, 1), fixedLandmarks(:, 2), fixedLandmarks(:, 3), ...
    'x', 'Color', 'red', 'MarkerSize', markerSize, ...
    'DisplayName', 'Fixed cp')

%text
text(registeredLandmarks(:, 1) + offset_val, ...
    registeredLandmarks(:, 2)  + offset_val, ...
    registeredLandmarks(:, 3), ...
    strsplit(num2str(selected_cp)), ...
    'Color', 'green', 'FontSize', 12, 'FontWeight', fontWeight, ...
    'HorizontalAlignment', 'left')
text(fixedLandmarks(:, 1) + offset_val, fixedLandmarks(:, 2)  + offset_val, ...
    fixedLandmarks(:, 3), strsplit(num2str(selected_cp)), ...
    'Color', 'red', 'FontSize', 12, 'FontWeight', fontWeight, ...
    'HorizontalAlignment', 'left')
hold off

grid on
pbaspect([1 1 1])
legend('Location','northeast')

%% Optimal travel path (Travel salesman problem by Google OR-Tools)
%Pre-requisite: The user needs to run 'TPS_test3.py' to estimate path
%Note: OR-Tools gives 16 pct shorter distances

order_column_python  = readmatrix(file_from_python) + 1; %python convention
idx_sort = order_column_python;
order_column_num = 1:n_spots2;

%Sorting
temp2_str = sprintf('spot_%05.f,', order_column_num);%for master table
temp2_str2 = strsplit(temp2_str, ',');
temp2_str3 = temp2_str2(1:end-1);

master_table_sorted = master_table_reg2(idx_sort, :);
master_table_sorted1 = addvars(master_table_sorted, temp2_str3', ...
    'NewVariableNames', 'newName');
writetable(master_table_sorted1, filePath_spot_reg3)
filePath_spot_reg3

%Info: Total travelling distance
X_sorted = X(idx_sort, :);
Z_sorted = squareform(pdist(X_sorted));
cummulative_dist2 = 0;
for i = 2:n_spots2
    temp = Z_sorted(i-1, i);
    cummulative_dist2 = cummulative_dist2 + temp;
end
sprintf('%.f', cummulative_dist2) 

%% Write Scan list to *.scancsv

master_table_sorted1 = readtable(filePath_spot_reg3, 'Delimiter', ',');

value.scanType = 'Spot';
value.selected = 0;
value.lockEdit = 0;
value.vertexCount = 1; %point

%updates
value.description = master_table_sorted1.newName;
value.x = master_table_sorted1.x_reg2;
value.y = master_table_sorted1.y_reg2;
value.z = master_table_sorted1.z_reg2;

[fileDest2] = write_scancsv(filePath, value); %follows a character encoding 

%% Optional: Plot path (quality check)

temp_str = sprintf('%.0f,', order_column_num);%for plot
temp_str2 = strsplit(temp_str, ',');
temp_str3 = temp_str2(1:end-1);

%finding corners
[~, x_idx_min] = min(x,[],"all"); %only fist selected
[~, x_idx_max] = max(x,[],"all");
[~, y_idx_min] = min(y,[],"all");
[~, y_idx_max] = max(y,[],"all");

corners = [
    x(x_idx_min), y(x_idx_min);
    x(x_idx_max), y(x_idx_max);
    x(y_idx_min), y(y_idx_min);
    x(y_idx_max), y(y_idx_max)
    ];
originDistance = sqrt(sum(corners.^2, 2)); %min origin distance
[~, origin_idx] = min(originDistance);
initial_xy = corners(origin_idx, :);
initial_idx = ( (X(:, 1) == initial_xy(:, 1)) & ...
    (X(:, 2) == initial_xy(:, 2)) );

initial_xy_prime = X_sorted(1, :);
spot_plotPath(X_sorted, initial_xy_prime, corners, temp_str3)
