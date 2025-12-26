function [mosaicInfo] = montageSaveRenamedTiles(mosaicInfo, ...
    targetBit, rescaleOption, saveOption, filePaths_renamed)
%Function to extract descriptive statistics of each visited image tile and
%rename the files with a desired name pattern

n_images = mosaicInfo.n_images;
imgDim = mosaicInfo.imgDim;
fileNames_sorted = mosaicInfo.fileNames_sorted;

tile_stats = zeros(n_images, 6);
for i = 1:n_images %optional: parfor    
        
    %e.g.: %02d wont be properly read by TrakEM2 after >100 tiles
    temp_img = imread(fileNames_sorted{i});
    temp_img = temp_img(1:imgDim(1), 1:imgDim(2));
       
    tile_stats(i, :) = [
        min(temp_img, [], 'all'), ...
        max(temp_img, [], 'all'), ...
        mean(temp_img, 'all'), ....
        median(temp_img, 'all'), ...
        mode(temp_img, 'all'), ...
        std(double(temp_img), 0, 'all')... %0: n-1
        ]; 
    %stats for 1000 images of 1000x1000 in 40 sec

    %tile allocation
    switch rescaleOption
        case 0
            temp_img1 = temp_img;
        
        case 1 %each tile channel   

            n_channels = size(temp_img, 3);
            temp_img_rescaled = zeros(imgDim(1), imgDim(2), n_channels);

            for ii = 1:n_channels

                Im16 = temp_img(:, :, ii);

                %Rescales linearly to full range (ImageJ style)
                dbIm16 = double(Im16)+1;
                db16min = min(dbIm16(:)); 
                db16max = max(dbIm16(:));
                        
                Norm_woOffSet = (dbIm16 - db16min)/(db16max - db16min); 
                temp_img_rescaled(:, :, ii) = Norm_woOffSet*2^targetBit-1; % back to 0:2^8-1    
            end       

            temp_img1 = uint8(temp_img_rescaled); 
    end
        
    switch saveOption
        case 0
            disp('Renamed greyscale tiles will not be saved.')
        case 1
            imwrite(temp_img1, gray(256), char(filePaths_renamed{i}), 'compression', 'none'); %, gray(256)
            %Colormap must have three columns.
    end    

    disp(num2str(i))
end

%% Storing process metadata

%montage mode
[N, edges] = histcounts(tile_stats(:, 4), 256);%4= median; 5= mode
[~, I] = max(N);
mosaic_mode = (edges(I) + edges(I+1))/2;

%update input structure
mosaicInfo.mosaic_min = min(tile_stats(:, 1));
mosaicInfo.mosaic_max = max(tile_stats(:, 2));
mosaicInfo.mosaic_mean = mean(tile_stats(:, 3));
mosaicInfo.mosaic_median = median(tile_stats(:, 4));
mosaicInfo.mosaic_mode = mosaic_mode;
mosaicInfo.mosaic_std = sqrt(sum(tile_stats(:, 6).^2));

end