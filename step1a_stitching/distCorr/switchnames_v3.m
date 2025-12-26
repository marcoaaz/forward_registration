%% Root folder

%script to read TIMA files, understand tile sequence, resave with serial names

%Created: 22-Aug-23, Marco Acevedo
%Updated: 5-Aug-24, Marco Acevedo

clear
clc

scriptsFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
addpath(scriptsFolder);
addpath(fullfile(scriptsFolder, 'distCorr')) 
addpath(fullfile(scriptsFolder, 'external_package/'))%xml library

experiment = 'F:\BALZ_Rock\BALZ_Rock.timaproj.Datasets\c7898c96-95a2-4568-b92d-f4a91ed036d6';
parentDir = fullfile(experiment, 'fields');
config = fullfile(experiment, 'configuration/profile.xml');

% fileDenominations = {'bse.png', 'sem-CL.png'}; %'maplayout.tif', 'pixelmask.png'
dirDenominations = {'fields_BSE'};  %'CL', 'phasemap', 'PixelMask'
fileDenominations = {'bse.png'};
sourceFolder = fullfile(experiment, 'fields_matlab/'); %after ''
dirDenominations2 = 'fields_EDX';

cd(parentDir);

%% Import experiment metadata

%Finding files (assuming TIMA project structure)
fileName = 'bse-png.hdr';
fileName2 = 'bse.png';
bseHdr_str = struct2table(dir(fullfile(parentDir, '**', fileName)));
files1 = fullfile(bseHdr_str.folder, fileName);
files2 = fullfile(bseHdr_str.folder, fileName2);

%Available file names (constant = asuming all folders are equal)
endout = regexp(files1, filesep, 'split');
sectionNames = cell(length(endout), 1);
for m = 1:length(endout)
    sectionNames{m} = endout{m}{end-1}; %focus on folder name
end 

%Interrogating metadata (following Ryan Ogliore script)
imagedir= files1;
nfiles=numel(imagedir);

%Montage info*********
fid = fopen(imagedir{1}); 
dd = textscan(fid,'%s');
dd=dd{1};
fclose(fid);

wdstr='PixelSizeX=';
ss=strfind(dd,wdstr);
index = false(1, numel(ss));
for k = 1:numel(ss)
  if numel(ss{k} == 1)==0
     index(k) = 0;
  else
     index(k) = 1;
  end     
end
ll=dd{index};
spatialResolution = str2double(ll((numel(wdstr)+1):end))*10^6; %microns/px

%Image size WxH info

%Tile info************
image_reference = imread(files2{1});    
image_size = size(image_reference); %tileSize_px
tileSize_px = image_size(1); %assuming equal X=Y

WD=zeros(nfiles,1);
YStage=zeros(nfiles,1);
XStage=zeros(nfiles,1);
for ii=1:nfiles
    
    fileName = imagedir{ii};
    fid = fopen(fileName); %[imagedir(ii).folder '/' imagedir(ii).name]
    dd = textscan(fid,'%s');
    dd=dd{1};
    fclose(fid);

    wdstr='WD=';
    ss=strfind(dd,wdstr);
    index = false(1, numel(ss));
    for k = 1:numel(ss)
      if numel(ss{k} == 1)==0
         index(k) = 0;
      else
         index(k) = 1;
      end     
    end
    ll=dd{index};
    WD(ii)=str2double(ll((numel(wdstr)+1):end));
      
    xstr='StageX=';
    ss=strfind(dd,xstr);
    index = false(1, numel(ss));
    for k = 1:numel(ss)
      if numel(ss{k} == 1)==0
         index(k) = 0;
      else
         index(k) = 1;
      end     
    end
    ll=dd{index};
    XStage(ii)=str2double(ll((numel(xstr)+1):end));
    
    ystr='StageY=';
    ss=strfind(dd,ystr);
    index = false(1, numel(ss));
    for k = 1:numel(ss)
      if numel(ss{k} == 1)==0
         index(k) = 0;
      else
         index(k) = 1;
      end     
    end
    ll=dd{index};
    YStage(ii)=str2double(ll((numel(ystr)+1):end));    
end

%Transforming coordinates
XStage_px = (10^6)*XStage/spatialResolution;
YStage_px = (10^6)*YStage/spatialResolution;
XStage1 = max(XStage_px) - XStage_px; %inverting axis (TIMA)
YStage1 = YStage_px - min(YStage_px); %max(YStage) - 

metadata = table(files2, str2double(sectionNames), XStage1, YStage1, ...
    'VariableNames', {'File', 'Tile', 'X', 'Y'});
metadata1 = sortrows(metadata, 'Tile', 'ascend');

%montage built (assuming rectangular montage)
nrows = int64(max(YStage1) + tileSize_px);
ncols = int64(max(XStage1) + tileSize_px);
nrows_tiles = round(nrows/tileSize_px);
ncols_tiles = round(ncols/tileSize_px);
dim_tiles = [nrows_tiles, ncols_tiles];
n_tiles = nrows_tiles*ncols_tiles; %>nfiles (acquired tiles)

%Extra TIMA metadata
outStruct = xml2struct(config);
%str2double(outStruct.JobProfile.FieldProfile.FieldWidth.Text)

%% Optional: Plot tiled montage

fontSize = 15;
canvas = ones(nrows, ncols); %preallocating

close all
hFig = figure;
ax = gca;

imshow(canvas)
for i = 1:nfiles
    hRectangle = drawrectangle(ax, ...
        'Position', [XStage1(i), YStage1(i), tileSize_px, tileSize_px], ...
        'InteractionsAllowed', 'none', 'LineWidth', 0.5, 'FaceAlpha', 0.1);
  
    hPoint = drawpoint(ax, ...
        'Position', [XStage1(i), YStage1(i)], ...
        'Color', 'r', 'Deletable', false, 'DrawingArea', 'unlimited');
    text(XStage1(i), YStage1(i), sectionNames{i}, ...
        'FontSize', fontSize, 'clipping', 'on')
%     hPoint.Label = sectionNames{i}; %update to MatLab 2020b
%     hPoint.LabelAlpha = 0;
    hPoint.MarkerSize = 3;
    
end
xlim([-10, ncols+10])
ylim([-10, nrows+10])

%% Reconfiguring tiling (grid collection)

%Map tiles with artificial grid
corner_x = metadata1.X;
corner_y = metadata1.Y;

%tiling_type = {'row-by-row'}; tiling_order_hz = {'right & down'}
[referenceGrid, tiling_name] = gridNumberer(dim_tiles, 1, 1); 
all_labels = referenceGrid(:); %column-major order, left to right

%%
%tiling_type = ['row-by-row', 'column-by-column', 'snake-by-rows', 'snake-by-columns']
%tiling_order_hz = ['right & down', 'left & down', 'right & up', 'left & up']
%tiling_order_vt = ['down & right', 'down & left', 'up & right', 'up & left']

[referenceGrid_test, ~] = gridNumberer([3, 4], 4, 4); 
referenceGrid_test
%%
%corresponding mesh
span_x = 0:tileSize_px:(ncols-tileSize_px+1); %without overlap (TIMA)
span_y = 0:tileSize_px:(nrows-tileSize_px+1);
[X_mesh, Y_mesh] = meshgrid(span_x, span_y);
all_points = double([X_mesh(:), Y_mesh(:)]); %follows matlab convention

oldLabel = zeros(n_tiles, 1);
for i = 1:n_tiles 

    [D, I] = pdist2([corner_x, corner_y], all_points(i, :), 'euclidean', ...
        'Smallest', 1); %minimum value
    if D < 100 %tolerance
        oldLabel(i) = metadata1.Tile(I);
    end    
end
mapping = [all_labels, oldLabel];

montage_Info = struct;
montage_Info.experiment = experiment; %path
montage_Info.metadata1 = metadata1;
montage_Info.mapping = mapping; 
montage_Info.dim = [nrows, ncols];
montage_Info.dim_tiles = dim_tiles;
montage_Info.tileSize_px = tileSize_px;
montage_Info.xRayCount = str2double(outStruct.JobProfile.AcquisitionProfile.XRayCount.Text);
montage_Info.dwellTime = str2double(outStruct.JobProfile.AcquisitionProfile.DwellTime.Text);
montage_Info.mode = outStruct.JobProfile.SegmentationProfile.Mode.Text;
montage_Info.segmentationLevel = str2double(outStruct.JobProfile.SegmentationProfile.SegmentationLevel.Text);
montage_Info.bseTH = str2double(outStruct.JobProfile.SegmentationProfile.BSEu_Threshold.Text);
montage_Info.edsTH = str2double(outStruct.JobProfile.SegmentationProfile.EDSu_Threshold.Text);

%Save montage metadata
save(fullfile(experiment, 'montage_Info.mat'), 'montage_Info', '-mat')

%% Read and write image tiles

outputFormat = '.tif';
image_size = [tileSize_px, tileSize_px];

n_denominations = length(fileDenominations);
for i = 1:n_denominations

    %specific destination
    destFolder1 = fullfile(experiment, dirDenominations{i});
    mkdir(destFolder1);
    
    %focus on folder name
    structure_temp = struct2table(dir( fullfile(parentDir, '**', ...
        fileDenominations{i}) ));
    folder_temp = string(fullfile( ...
        structure_temp.folder, structure_temp.name));  
    
    [a, ~, ~]= fileparts(folder_temp);
    [~, folderName_temp, ~] = fileparts(a);     
    folderName_temp = str2double(folderName_temp);

    %info
    image_reference = imread(folder_temp(1));        
    image_class = class(image_reference);

    %generate new images    
    for j = 1:n_tiles

        index_temp = folderName_temp == mapping(j, 2); %finding tile by oldLabel                

        %Allocating: step not stored in memory
        if sum(index_temp) > 0                                
            image_temp = imread(folder_temp(index_temp)); %reading 

        elseif sum(index_temp) == 0                        
            image_temp = zeros(image_size, image_class); 

        end
        
        %Saving
        %option 1:
        %folderName_temp1 = mapping(j, 1); %for saving as ind sequence
        % fileName = strcat('tile_', sprintf('%04d', folderName_temp1), outputFormat);
        %Note: missing leading zeros %03d (might cause TrakEM2 issue at importing)
        
        %option 2: follows deep zoom format (pyvips scripts)
        [temp_row, temp_col] = ind2sub(dim_tiles, j);
        fileName = strcat(sprintf('%.0f_%.0f', temp_col, temp_row), outputFormat);

        fileRoute = fullfile(destFolder1, fileName);
        imwrite(image_temp, fileRoute); %saving is optional when MinDIF export available)
    end
end

%% Saving EDX spectra (for TIMA ROI Tool script)

destFolder2 = fullfile(experiment, dirDenominations2);
mkdir(destFolder2);  

structure_temp_edx = struct2table(dir(fullfile(sourceFolder, '*.mat')));
file_temp = string(fullfile(structure_temp_edx.folder, structure_temp_edx.name));
   
[~, fileName_temp, ~]= fileparts(file_temp);
fileName_temp = str2double(fileName_temp); 

image_size_T = fliplr(image_size);
n_pixels = image_size_T(1)*image_size_T(2);
ind_python_mtx = transpose(reshape(1:n_pixels, image_size_T));

%Reading EDX spectra and resaving   

for j = 1:n_tiles

    index_temp = fileName_temp == mapping(j, 2); %oldLabel    
    %folderName_temp1 = mapping(j, 1); %for ind sequence       

    if sum(index_temp) > 0          
        field_output = struct;

        filepath = file_temp(index_temp);       
        field = load(filepath, 'dictionary');
                
        row = field.dictionary.r + 1; %python convention
        col = field.dictionary.c + 1;
        eds = field.dictionary.eds;        
        %bse = field.dictionary.bse;
        %dotSpacing = field.dictionary.sample_distance;
      
        mask = false(image_size);
        ind = sub2ind(image_size, row, col);
        mask(ind) = 1;             
        ind_python = ind_python_mtx(ind);
        [original_order, ~] = sort(ind_python, 'ascend');
        [~, location] = ismember(ind_python, original_order);
        eds_matlab = eds(location, :); %rearrange following matlab convention

        field_output.row = row;
        field_output.col = col;
        field_output.ind = ind;
        field_output.eds = eds_matlab;
        field_output.tile_id = mapping(j, 2);

        %Saving
        %follows deep zoom format (pyvips scripts)
        [temp_row, temp_col] = ind2sub(dim_tiles, j);
        tileName = sprintf('%.0f_%.0f', temp_col, temp_row);
        
        filepath1 = fullfile(destFolder2, strcat(tileName, outputFormat));
        filepath2 = fullfile(destFolder2, strcat(tileName, '.mat'));
        
        imwrite(mask, filepath1);
        save(filepath2, "field_output", '-mat');
    end   
end
%%