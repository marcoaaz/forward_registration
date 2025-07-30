%Script 'linkTrakEM2_v7.m'

%Script to

%Created: 4-Aug-2022, Marco Acevedo Z., QUT
%Updated: 17-Dec-2024, Marco Acevedo Z., QUT

%Notes:
%-requires Symbolic Math Toolbox for expressing equations
%-_v6 originally worked for 1 layers and 1 tile parsing metadata

%Citation:
%Publication: https://doi.org/10.3390/min13020156
%Repository: https://github.com/marcoaaz/Acevedo-Kamber/tree/main/QuPath_generatingMaps

%Script documentation:


%% Root folder (channels)
clear
clc
close all

%User input
%where TrakEM2 project sits
% rootFolder = 'E:\Justin Freeman collab\Marco Zircon\LayersData\Layer\output_combined_BSE_t-position_withBSE\SIFT_aligned_MIP_std'; 
% rootFolder = 'E:\Alienware_March 22\current work\rodrigo work\UHP41_manual export_28-Nov-24';
%rootFolder = 'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\row1_BSE_t-grid';

rootFolder = 'D:\Justin Freeman collab\Distortion modelling_2-Apr-25\Distortion Test For Marco';
projectFile = 'trial2_all'; %'alignment_p-c_17-Dec-24_trial1_twoLayers'
sample = ''; %type
layer_number = 7; %layer z=0 is 1 (MatLab), where the calibrating tileset sits.
manualSize = 0; %Optional input
imageSize_manual = [2022, 2424]; %depends upon the input tiles to distort

%After distortion correction section: remembering acquisition sequence
n_tile_rows = 3; %edit manually (where: Leica metadata)
n_tile_cols = 3;
overlap = 60; %default= 0 (TIMA tile exports)

%Script 

%Dependencies
scripts1 = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
scriptPath1 = fullfile(scripts1, 'distCorr/');
scriptPath2 = fullfile(scripts1, 'external_package/');

addpath(scripts1) 
addpath(scriptPath1) 
addpath(scriptPath2) 

parentDir = fullfile(rootFolder, sample);
cd(parentDir);

%File/folders
distFile = strcat(projectFile, '.xml'); %XML, option: specify manually
distFolder = rootFolder; %alternative: same project
destFolder = fullfile(rootFolder, strcat(projectFile, sprintf('_output_layer%.f', layer_number)));

mkdir(destFolder)
file_output = fullfile(destFolder, 'registered2.txt'); %for TrakEM2 (re-importing)
fileName = fullfile(destFolder, 'distCorr_marco.txt'); %name for saving Lens correction copycat

%Reading TrakEM2 file

%%Option 1:
% fileName = '12apr'; %edit manually
% format = '.xml.gz';
% name_string1 = strcat(fileName, format);
% name_string2 = strrep(name_string1, '.gz', '');
% temp = gunzip(name_string1); %Extract contents of GNU zip file
% file = fullfile(parentDir, name_string2);
% 
% [content] = xml2struct(name_string2);

%%Option 2: where TrakEM2 distortion project sits
[content] = xml2struct(fullfile(distFolder, distFile));

%Pre-check
layers = content.trakem2.t2u_layeru_set.t2u_layer; %project
if isstruct(layers)
    disp('The project only contains 1 z-level.')    
    layers = {layers}; %medicine
end

layer_montage = layers{1, layer_number};

%Parsing lens correction Non-Linear Transform
try
    
    route1 = layers{1, layer_number}.t2u_patch{1,1}.ictu_transform.Attributes.data; 
    %content.trakem2.t2u_layeru_set.t2u_layer is Cell when project has >1 z level

    vector = str2double(strsplit(route1, ' '));
    kernelDim = vector(1);
    n_rows = vector(2);
    from = 3;
    to = from + n_rows*2 -1;
    transformCoeff = vector(from:to);
    transformCoeff1 = reshape(transformCoeff', 2, [])';

    from = to + 1;
    to = from + n_rows -1;
    normMean = vector(from:to);

    from = to + 1;
    to = from + n_rows -1;
    normVar = vector(from:to);

    from = to + 1;
    to = from + 1;
    imageSize_orig = vector(from:to);
    imageSize = fliplr(imageSize_orig); %flipped order (for MatLab convention)
    
    %Optional: write distortion file (Distortion Correction format)
    %Outside try, it fails if not available in *.xml file    
    fileID = fopen(fileName, 'w');

    %Edit
    fprintf(fileID, '%s\n', 'Kerneldimension');
    fprintf(fileID, '%d\n', kernelDim);
    fprintf(fileID, '\n');
    fprintf(fileID, '%s\n', 'number of rows');
    fprintf(fileID, '%d\n', n_rows);
    fprintf(fileID, '\n');
    fprintf(fileID, '%s\n', 'Coefficients of the transform matrix:');
    fprintf(fileID,'%.17f    %.16f\n', transformCoeff1);
    fprintf(fileID, '\n');
    fprintf(fileID, '%s\n', 'normMean:');
    fprintf(fileID,'%.16f\n', normMean(1:5));
    fprintf(fileID,'%.16E\n', normMean(6:end-1));
    fprintf(fileID,'%.1f\n', normMean(end));
    fprintf(fileID, '\n');
    fprintf(fileID, '%s\n', 'normVar: ');
    fprintf(fileID,'%.16f\n', normVar(1:5));
    fprintf(fileID,'%.16E\n', normVar(6:end-1));
    fprintf(fileID,'%.1f\n', normVar(end));
    fprintf(fileID, '\n');
    fprintf(fileID, '%s\n', 'image size: ');
    fprintf(fileID, '%.f    %.f', imageSize_orig);
    fclose(fileID);

    %Format medicine (MatLab -> "Distortion Correction" guts)
    fileID = fopen(fileName, 'rt'); %for changing some minor details in txt
    X = fread(fileID); %as a double (not character)
    fclose(fileID);

    X1 = char(X'); %.'
    X2 = strrep(X1, '+0', ''); %case 1
    X3 = strrep(X2, '+', ''); %case 2

    fid2 = fopen(fileName,'wt') ;
    fwrite(fid2, X3) ;
    fclose (fid2) ;

    clear X1 X2

catch exception

    imageSize(1) = str2double(layers{1, layer_number}.t2u_patch{1, 1}.Attributes.height); %uses other layers and first image patch
    imageSize(2) = str2double(layers{1, layer_number}.t2u_patch{1, 1}.Attributes.width);  
    
    disp('The TrakEM2 project did not applied a distortion correction transform');
end

%Verification required (probably good)
if manualSize == 1
    imageSize = imageSize_manual;
elseif manualSize == 0
    disp('Using project image size')
end

n_pixels = imageSize(1)*imageSize(2);
n_tiles = length(layers{1, layer_number}.t2u_patch);

clear temp from to 

%% After Stitching: Parsing 2D affine (different for every tile)

tileNames = cell(1, n_tiles);
affineCollect = cell(1, n_tiles);
virtualXY = zeros(n_tiles, 2);

for ii = 1:n_tiles
    %metadata 
    route2 = layer_montage.t2u_patch{1, ii}.Attributes.transform;
    route3 = layer_montage.t2u_patch{1, ii}.Attributes.title;  
    
    %parsing
    out = regexp(route2, '(?<=\()[^)]*(?=\))', 'match', 'once');
    out1 = str2double(strsplit(out, ',')); %format long
    temp = [reshape(out1(1:4), [2, 2]), out1(5:6)'];
    temp1 = [temp; [0 0 1]];
    
    %caching
    tileNames{ii} = route3;%according to last edit in TrakEM2 GUI
    affineCollect{ii} = temp1;    
    virtualXY(ii, :) = out1(5:6); %only x-y translation 
end

%Save: Post-registration coordinate file (only translation)

%saves registered2.txt (compatible with TrakEM2)
virtualXY1 = string(virtualXY);
temp_zeros = repmat('0.0', size(virtualXY1, 1), 1);
table_output = table(tileNames', virtualXY1(:, 1), virtualXY1(:, 2), temp_zeros, ...
    'VariableNames', {'fileName', 'x', 'y', 'Layers'});

writetable(table_output, file_output, 'Delimiter', 'tab', 'WriteVariableNames', 0) %saves registered2 for TrakEM2 (reimporting)
adapter_ts(file_output) %saves registered3.txt (for Stitching)

%Generating tile sequence; info: renamingSequence.m
dim = [n_tile_rows, n_tile_cols]; %e.g.: [3, 3]; [6, 5]
[desiredGrid, ~] = gridNumberer(dim, 1, 1); %row-major order (preferred by TrakEM2)
% [referenceGrid, ~] = gridNumberer(dim, 2, 1);  %col-major

%Type, Order
% tiling_type = {'row-by-row', 'column-by-column', 'snake-by-rows', 'snake-by-columns'};
% tiling_order_hz = {'right & down', 'left & down', 'right & up', 'left & up'};
% tiling_order_vt = {'down & right', 'down & left', 'up & right', 'up & left'};

tileSequence = 0; %filename follows numeric sequence
expression_grid = 'Tile_(?<x>\d*)-(?<y>\d*)-.*.tif';
% expression_grid = 'tile_(?<x>\d*)_(?<y>\d*).tif';
% expression_grid = '_x(?<x>\d*)_y(?<y>\d*).tif'; %default

%Parsing filenames
if tileSequence == 1 %not a grid
    
    q0 = regexp(tileNames,'\d*','match'); 
    sequence_str = cat(1, q0{:});
    q1 = str2double(sequence_str);%as column (follows desiredGrid)

elseif tileSequence == 0 %grid (order within TrakEM2 project XML)

    %tile_x001_y003
    q0 = regexp(tileNames, expression_grid,'names');
    pos = struct2table([q0{:}]);
    x = str2double(pos.x);
    y = str2double(pos.y);
    pos_ind = sub2ind([max(y), max(x)], y, x); %col-major order     
    
    q1 = desiredGrid(pos_ind); %getting row-major (follows desiredGrid)
end


%% Top-left tile corners: Ideal(acquisition grid) vs Virtual(TrakEM2)

%ideal (pre-set stage travelling)
YStage_o = 1+ round(((100-overlap)/100)*((1:n_tile_rows)*imageSize(1) - imageSize(1)));
XStage_o = 1+ round(((100-overlap)/100)*((1:n_tile_cols)*imageSize(2) - imageSize(2)));
[X_mesh, Y_mesh] = meshgrid(XStage_o, YStage_o);
%..this should follow a customized order..
idealXY = [X_mesh(:), Y_mesh(:)]; %follows MatLab unfolding (full grid)
idealXY1 = idealXY - idealXY(1, :); %-1 px

%virtual (within TrakEM2)
max_coordinates = max(virtualXY, [], 1);
XStage1 = virtualXY(:, 1);
YStage1 = virtualXY(:, 2);
dist_orig = sqrt(XStage1.^2 + YStage1.^2);
[~, min_index] = min(dist_orig);
virtualXY1 = virtualXY - virtualXY(min_index, :); 

%Correspondences (missing tiles out). 
% Note: If ideal grid is not realistic, this section will fail.

[D1, I1] = pdist2(virtualXY1, idealXY1*2, 'euclidean', 'Smallest', 1); 
temp_filter = D1 < 200; %px 
%depends on the stage error
%it does not work if there is scale transform (multiply idealXY1 by scale number)
virtualXY2 = virtualXY1(I1(temp_filter), :); %rearranged   

sectionNames_num = q1(I1(temp_filter), :); %must be a tile sequence (not a grid)
[Lia, Locb] = ismember(desiredGrid, sectionNames_num);

%matrix: t-l coordinates
pos_info = zeros(n_tiles, 8);
for ii = 1:n_tiles
    
    index_current = find(Locb == ii);
    index_back = index_current - 1;
    
    coord_current_ideal = idealXY1(index_current, :);    
    coord_current_virtual = virtualXY2(ii, :);
    try    
        coord_back_ideal = idealXY1(index_back, :);            
    catch
        coord_back_ideal = [NaN, NaN];        
    end
    try
        if Locb(index_back) ~= 0        
            coord_back_virtual = virtualXY2(ii-1, :);    
        else            
            coord_back_virtual = [NaN, NaN];
        end
    catch 
        coord_back_virtual = [NaN, NaN];
    end
    pos_info(ii, :) = [coord_back_ideal, coord_current_ideal, ...
        coord_back_virtual, coord_current_virtual];
end    
    
%% Top-left tile corners: offsets (virtual - ideal)

pos_ideal = pos_info(:, 3:4) - pos_info(:, 1:2);
pos_virtual = pos_info(:, 7:8) - pos_info(:, 5:6);
offset = pos_virtual - pos_ideal;
% offset = virtualXY2 - idealXY1;%alternative (if cummulative sought after)

U = offset(:, 1);
V = offset(:, 2);
off_mag = sqrt(U.^2 + V.^2);

angle = atan(V./U)*(180/pi); %from X-axis [-90, 90]
quadrant1 = U>=0 & V>=0; 
quadrant2 = U<0 & V>=0;
quadrant3 = U<0 & V<0;
quadrant4 = U>=0 & V<0;
angle(quadrant2) = angle(quadrant2)+180;
angle(quadrant3) = angle(quadrant3)+180;
angle(quadrant4) = angle(quadrant4)+360;
off_angle = angle; %from X-axis counter clock-wise [0, 360]

off_values = [pos_info(:, 3), pos_info(:, 4), U, V, off_mag, off_angle];
% off_values = off_values(2:end, :);

%% Virtual montage reconstruction

nrows= int64(max_coordinates(2) + imageSize(1));
ncols= int64(max_coordinates(1) + imageSize(2));
canvas = ones(nrows, ncols); %preallocating
text_pos = 22.5;

XStage_virtual = virtualXY1(:, 1);
YStage_virtual = virtualXY1(:, 2);

figure;
ax = gca;

imshow(canvas)
for i = 1:n_tiles
    hPoint = drawpoint(ax, ...
        'Position', [XStage_virtual(i), YStage_virtual(i)], ...
        'Color', 'r', 'Deletable', false, 'DrawingArea', 'unlimited');
%     hPoint.Label = sectionNames{i}; %cluttered option: update to MatLab 2020b    
    text(XStage_virtual(i) +text_pos, YStage_virtual(i) -text_pos, tileNames{i}, ...
        'Color', 'red', 'FontSize', 8, 'Interpreter', 'none');

    hRectangle = drawrectangle(ax, ...
        'Position', [XStage_virtual(i), YStage_virtual(i), imageSize(2), imageSize(1)], ...
        'InteractionsAllowed', 'none', 'LineWidth', 0.5, 'FaceAlpha', 0.1);    
end
% xlim([-10, ncols+10])
% ylim([-10, nrows+10])
hold on
scale = 1; %0 shows true size (px); 0.2 for 4x4; 1 for 15x19 tileset
quiver(off_values(:, 1), off_values(:, 2), ...
    off_values(:, 3), off_values(:, 4), scale, 'black')
axis equal
hold off

%% 3D Contour plot: Probability mesh calculation

nbins = 50;%grid side
n_data = sum(~isnan(U));

figure
h = binscatter(U, V, nbins);
hold on
scatter(U, V, 9, 'filled', 'MarkerFaceColor', 'r')
hold off
xlabel('x');
ylabel('y');
set(gca, 'YDir','reverse')
h.ShowEmptyBins = 'on';

%Probabilities
XBinEdges = h.XBinEdges;
YBinEdges = h.YBinEdges;
Values = h.Values;
XLimits = h.XLimits;
YLimits = h.YLimits;
midX = (XBinEdges(1:end-1) + XBinEdges(2:end))/2;
midY = (YBinEdges(1:end-1) + YBinEdges(2:end))/2;
[x_centres, y_centres] = meshgrid(midX, midY);
Values1 = Values'./sum(Values, 'all');%row-major order left-right, top-down

%3D Contour plot: plot calculations
%surface
method= 'linear';
F_c = scatteredInterpolant([x_centres(:), y_centres(:)], Values1(:), method);
F_c.ExtrapolationMethod = 'none';

amplitude_U = max(U)-min(U);
amplitude_V = max(V)-min(V);
downsample = 250;%edit manually
interval = max(amplitude_U, amplitude_V)/downsample;
extra_graph = interval*5;%edit manually
xmin = min(U) -extra_graph;
xmax = max(U) +extra_graph;
ymin = min(V) -extra_graph;
ymax = max(V) +extra_graph;

[xq, yq] = meshgrid(xmin:interval:xmax, ymin:interval:ymax);
[rows_downsampled, cols_downsampled] = size(xq);
prob_interp = F_c(xq(:), yq(:));        
zmin = min(prob_interp) + 0.001; %to neglect background
zmax = max(prob_interp);
surf_interp = reshape(prob_interp, [rows_downsampled, cols_downsampled]);

%statistics
[r_apex, c_apex] = find(surf_interp == max(surf_interp, [], 'all'));
x_temp = xq(1, :)';%sections
y_temp = yq(:, 1);
apex = [x_temp(c_apex), y_temp(r_apex)]; %passes exactly at every point
prob_interp_xsec = [x_temp, surf_interp(r_apex, :)'];
prob_interp_ysec = [y_temp, surf_interp(:, c_apex)];

%3D Contour plot

figure(10);
clf('reset') %required for clearing the automatic plot
hFig = gcf;
pos = get(hFig, 'Position');
set(hFig, 'Position', pos);

subplot(2, 2, 1:2)
s = surf(xq, yq, surf_interp, 'FaceColor', 'interp', ...
    'FaceAlpha', 0.9); 
s.EdgeColor = 'none'; %[0.2, 0.2, 0.2]; 
colormap(jet(10))
c = colorbar;
c.Label.String = 'Relative probability';
xlabel('x');
ylabel('y');
zlabel('Probability');
xlim([xmin, xmax]);
ylim([ymin, ymax]);
zlim([zmin, zmax]);
set(gca, 'YDir','reverse')
%legend
legendText1 = sprintf('x= %0.2f, std= %0.3f', ...
    round(mean(U, 'omitnan'), 2), round(std(U, 'omitnan'), 3));
legendText2 = sprintf('y= %0.2f, std= %0.3f', ...
    round(mean(V, 'omitnan'), 2), round(std(V, 'omitnan'), 3));
legendText3 = sprintf('data = %d', n_data);
% legend(legendText1, legendText2, legendText3);
textbox = sprintf('%s\n%s\n%s', legendText1, legendText2, legendText3);
text(xmax*0.6, ymax*0.6, zmax*0.6, textbox);

sz = 8;
subplot(2, 2, 3)
h2 = scatter(prob_interp_ysec(:, 1), prob_interp_ysec(:, 2), ...
    sz, 'filled', 'MarkerFaceColor', 'black');
grid on
ylabel('Probability');
xlabel('Y')
hold on
line([apex(2), apex(2)], [0, zmax],'Color','red','LineStyle', '-')
hold off
legendText1 = sprintf('apex y= %0.2f', round(apex(2), 2));
legendText2 = sprintf('samples y= %d', size(prob_interp_ysec, 1));
textbox = sprintf('%s\n%s', legendText1, legendText2);
text(ymax*0.6, zmax*0.9, textbox);

subplot(2, 2, 4)
h1 = scatter(prob_interp_xsec(:, 1), prob_interp_xsec(:, 2), ...
    sz, 'filled', 'MarkerFaceColor', [0.6350, 0.0780, 0.1840]);
grid on
xlabel('X')
hold on
line([apex(1), apex(1)], [0, zmax],'Color','red','LineStyle', '-')
hold off
legendText1 = sprintf('apex x= %0.2f', round(apex(1), 2));
legendText2 = sprintf('samples x= %d', size(prob_interp_xsec, 1));
textbox = sprintf('%s\n%s', legendText1, legendText2);
text(xmax*0.6, zmax*0.9, textbox);

%2D tile rotation histogram

n_test = length(affineCollect);
angle = zeros(1, n_test);
angle_dg = zeros(1, n_test);
for i = 1:n_test
    [result] = decompose_2d_matrix(affineCollect{i});
    angle(i) = result.rotation;
    angle_dg(i) = result.rotation*180/pi;
end
angle_mean = mean(angle_dg);
% angle_mode = mode(angle);
[counts, edges] = histcounts(angle_dg, 7);
modeIndexes = find(counts == max(counts));
angle_mode = (edges(modeIndexes(end))+edges(modeIndexes(end)+1))/2;
x_error = imageSize(1)*tan(angle_mode*(pi/180));
y_error = imageSize(2)*tan(angle_mode*(pi/180));
ymax = counts(modeIndexes)*1.2;

%Plot
figure
% histogram(angle_dg)
histogram('BinEdges', edges, 'BinCounts', counts)
% polarhistogram(angle) %radians input
hold on
line([angle_mean, angle_mean], [0, ymax], ...
    'Color','blue','LineStyle', '-')
line([angle_mode, angle_mode], [0, ymax], ...
    'Color','red','LineStyle', '-')
hold off
grid on
xlabel('Degrees')
ylabel('Population')
ylim([0, ymax])
title('Stage rotation')
%legend
legendText1 = sprintf('H= %0.2f, x-error= %0.2f', ...
    imageSize(1), round(x_error, 2));
legendText2 = sprintf('W= %0.2f, y-error= %0.2f', ...
    imageSize(2), round(y_error, 2));
legendText3 = sprintf('\\color[rgb]{%f, %f, %f}mean= %0.3f', [0, 0, 1], round(angle_mean, 3));
legendText4 = sprintf('\\color[rgb]{%f, %f, %f}mode= %0.3f', [1, 0, 0], round(angle_mode, 3));
textbox = sprintf('%s\n%s\n%s\n%s', ...
    legendText1, legendText2, legendText3, legendText4);
text(max(angle_dg)*0.6, counts(modeIndexes)*0.8, textbox);


%% Option 1: Lens distortion correction: Kaynig et al., 2010, pg.168

%generating polynomial
d = 5; %degree (modify according to TrakEM2 context menu)
[u_mtx, v_mtx] = ndgrid(0:d);
total_degree = u_mtx + v_mtx; %reference matrix
total_logical = total_degree >= d;
n_terms = sum(total_logical, 'all'); %upper matrix= n*(n+1)/2

%mapping exponents for X and Y coordinates
row = [];
col = [];
for i = 0:d
    temp = (total_degree == i);
    [row_temp, col_temp] = find(temp); %already in preferred order
    row = [row; row_temp];
    col = [col; col_temp];
end
row = [row(2:end); row(1)]; %medicine (following plugin order)
col = [col(2:end); col(1)];

%Displaying kernel polynomial (doing expansion)
u_power = (row -1)';%exponents (not ndgrid matrix indexes)
v_power = (col -1)';
coeff = ones([1, n_terms]);%coefficients

syms u v %scalar variables
f(u, v) = (coeff).*(u.^u_power).*(v.^v_power); %kernel symbolic vector
display(f);
% test = double(f(1, 5));

%Coordinates of input point/pixel grid (for next section)
[horiz_mtx, vert_mtx] = ndgrid(1:imageSize(1), 1:imageSize(2));
original_coord = [horiz_mtx(:), vert_mtx(:)]-0.5;%column-wise order

%Non-linear transformation
%reference table (redundant calculation)
extent = max(imageSize(1), imageSize(2)); %larger than both image sizes (backup)
precalculated = zeros(extent, d+1);
array = [0:d];%follow mapped indexes
pixel_centres = [1:extent]-0.5;
k=0;
for i = pixel_centres
    k= k+1;
    precalculated(k, 1:d+1) = i.^array; %reference table (computed once)   
end

poly_expanded = zeros(n_pixels, n_terms);
k= 0;
for i = 1:imageSize(2) %x = col
    for j = 1:imageSize(1) %y = row
        %the loop precedence is irrelevant as transformCoeff1 acts pixel-wise
        k = k + 1;
        
        temp_values_u = precalculated(i, :);
        temp_values_v = precalculated(j, :); %use same reference table
        var1 = temp_values_u(row);%X, follows search index of exponents
        var2 = temp_values_v(col); %Y
        temp_poly = var1.*var2; %coeff = 1 in all terms
        poly_expanded(k, 1:n_terms) = temp_poly;
    end
end

clear var1 var2 i j k

expanded_norm = (poly_expanded - normMean)./normVar; %normalized
expanded_norm(:, end) = 100; %instead of -Inf 
trans_coord = expanded_norm*transformCoeff1;%(n_pixels X n_terms)*(n_terms X 2)

%Why are these columns not equal? (email author)
varComparison = [std(poly_expanded)', normVar'];
meanComparison = [mean(poly_expanded)', normMean'];

%% Option 1: Non-linear transformation: Quiver and magnitude plots

X= original_coord(:, 2);
Y= original_coord(:, 1);
U= trans_coord(:, 1) -X; %flipped order (i do not know why)
V= trans_coord(:, 2) -Y;
magnitude = sqrt(U.^2 + V.^2);
magnitude(magnitude > 7) = 7; %pixels, cropping outliers (edit manually)
magnitude1 = 1*(magnitude-min(magnitude))/(max(magnitude)-min(magnitude)); %rescaled

%For transformation field images (Quiver plot)
angle = atan(V./U)*(180/pi); %from X-axis [-90, 90]
quadrant1 = U>=0 & V>=0; %from X-axis counter clock-wise [0, 360]
quadrant2 = U<0 & V>=0;
quadrant3 = U<0 & V<0;
quadrant4 = U>=0 & V<0;
angle(quadrant2) = angle(quadrant2)+180;
angle(quadrant3) = angle(quadrant3)+180;
angle(quadrant4) = angle(quadrant4)+360;
% angle1 = 1*(angle-min(angle))/(max(angle)-min(angle)); %rescaled
angle1 = angle/360;

hsv_triplet = cat(3, angle1, magnitude1, 0.95*ones([n_pixels, 1]));
rgb_triplet = hsv2rgb(hsv_triplet);
% figure %quality check 
% histogram(rgb_triplet(:, 1));
% hold on
% histogram(rgb_triplet(:, 2));
% histogram(rgb_triplet(:, 3));
% hold off

img_rgb = reshape(rgb_triplet, [imageSize(1), imageSize(2), 3]);

%Generating a less dense point grid (for Quiver plot)
%subsetting
ref_grid = 1:n_pixels;
ref_grid = reshape(ref_grid, [imageSize(1), imageSize(2)]);

interval_px = 25; %cell size (edit manually)
interval_row = 1:interval_px:imageSize(1);
interval_col = 1:interval_px:imageSize(2);
ref_grid_shrunk = ref_grid(interval_row, interval_col);
ref_grid_shrunk = ref_grid_shrunk(:);

%interpolating (from less dense point grid)
scaling = 3;
X_sub = X(ref_grid_shrunk);
Y_sub = Y(ref_grid_shrunk);
U_sub = scaling*U(ref_grid_shrunk);
V_sub = scaling*V(ref_grid_shrunk);
magnitude_sub = magnitude(ref_grid_shrunk);
rgb_triplet_sub = rgb_triplet(ref_grid_shrunk, :);

%Plot
hFig = figure; %Magnitude and Quiver plots
imshow(img_rgb)
hold on
quiver(X_sub, Y_sub, U_sub, V_sub, 'black')
axis equal
hold off

print(hFig, fullfile(destFolder, sprintf('layer%.f.svg', layer_number)), '-dsvg');

%% Option 1: Applying non-rigid transformation (saving images)
% 
% % x_trans = trans_coord(:, 1);
% % y_trans = trans_coord(:, 2);
% 
% %where interesting tiles (e.g.: shading-corrected) sit
% route2 = rootFolder;
% format = '.tif';%.png
% 
% [~, fileNames] = GetFileNames(route2, format); %sorted by numeric index (for montages)
% % fileNames = {'stack_restored.tif'}; %manual input (for stacks)
% n_images = length(fileNames);
% 
% folderName = 'rectified';
% folder = fullfile(route2, folderName);
% mkdir(folder);
% 
% %pre-allocating interpolant
% fileName = fileNames{1}; %
% file_route = fullfile(route2, fileName);
% image_temp = imread(file_route);
% tile_img = double(image_temp);
% method = 'linear'; %interpolation, alternative: cubic 
% channel_1 = tile_img(:, :, 1);        
% F_c = scatteredInterpolant(trans_coord, channel_1(:), method);
% F_c.ExtrapolationMethod = 'none';
% 
% %% Option 1: n_images = 40; %(for measuring time)
% % t = zeros(1, n_images); 
% tic;
% 
% M = 8; %maximum number of workers= 8
% parfor (i = 1:n_images, M) %recyclates memmory    
%     fileName = fileNames{i};
%     file = fullfile(route2, fileName);
% 
%     [img_interp] = interpolateIMG4(file, original_coord, F_c);
% %     [img_interp] = interpolateIMG3(file, trans_coord, original_coord);       
% 
%     %edit accordingly
% %     fileName1 = strcat('tile_', sprintf('%03d', i), format);
%     fileName1 = fileName;
% 
%     %saving
%     fileDestination = fullfile(folder, fileName1);
%     imwrite(img_interp, fileDestination)
% 
%     disp(num2str(i))        
% end
% 
% t= toc; %timer: 
% %interpolateIMG4:
% %for 2022x2424 image (8-bit) takes ~6.4232 sec/img 
% %8.0718 hrs for 4524 tiles using 8 cores; 
% % (using 6 cores takes too long for >2000 tiles)
% 
% %interpolateIMG3:
% %for 768x768 image (8-bit) takes 2.44 sec/img
% %for 1040x1392 image (RGB 24-bit) takes 19.25 sec/img
% %for 1000x1000 image (16-bit) takes 1.2825 sec/img

