function [mosaic_edges, mosaic_counts, mosaic_counts_log] = ...
    montageHistogramStacking(mosaicInfo, TH_array, n_bins)
%Update: 21-May-24, Marco Acevedo

%Input: it uses the tile histogram metadata (min and max) from the
%previous step to generate a montage histogram in linear and log scale. The
%TH_array values are used as forceful outer bounds to the montage histogram.

%Output: the montage histogram values for reproduction

%%

fileNames_sorted = mosaicInfo.fileNames_sorted;
n_images = mosaicInfo.n_images;

imgDim = mosaicInfo.imgDim;
MinMax_array = [mosaicInfo.mosaic_min, mosaicInfo.mosaic_max];

%calculate intervals
mosaic_min_range = max(TH_array(1), MinMax_array(1)); %script
mosaic_max_range = min(TH_array(2), MinMax_array(2));
range = mosaic_max_range - mosaic_min_range;
bin_width = range/n_bins;

mosaic_edges = zeros(1, n_bins+1);
mosaic_edges(1) = mosaic_min_range;
for j = 1:n_bins
    mosaic_edges(j+1) = mosaic_edges(j) + bin_width;
end

%calculate counts
tile_counts = zeros(n_images, n_bins);
for i = 1:n_images %parfor        
    temp_img = imread(fileNames_sorted{i});    
    temp_img = temp_img(1:imgDim(1), 1:imgDim(2)); %edit manually

    %clipping
    temp_img(temp_img < mosaic_edges(1)) = mosaic_edges(1);
    temp_img(temp_img > mosaic_edges(end)) = mosaic_edges(end);

    tile_counts(i, :) = histcounts(temp_img(:), mosaic_edges);  

    disp(num2str(i))
end
mosaic_counts = sum(tile_counts, 1);
mosaic_counts_posi = mosaic_counts;
mosaic_counts_posi = mosaic_counts_posi + 1; %prevent -Inf

%mosaic counts log rescaled
mosaic_counts_log = log(mosaic_counts_posi);
mosaic_counts_log = (mosaic_counts_log-min(mosaic_counts_log))*...
    (max(mosaic_counts_posi)-min(mosaic_counts_posi))/(...
    max(mosaic_counts_log)-min(mosaic_counts_log));

end