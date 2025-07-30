
function [grid_info] = save_grids(grid_info, class_grids, suffix)

format = '.tiff';

n_classes = grid_info.n_classes;
nGrids = grid_info.nGrids;
destinationFolder = grid_info.dest_folder_grid;

grid_files = cell(1, n_classes*nGrids);
k = 0;
for i = 1:n_classes    
    for j = 1:nGrids
        
        classImage = class_grids{i}{j}; %class grids (uint16)
        %class(classImage)        

        fileName1 = strcat('class', num2str(i), '_grid', num2str(j), ...
            '_', suffix, format);        
        destinationFile1 = fullfile(destinationFolder, fileName1);
        
        imwrite(classImage, destinationFile1)

        k = k + 1;
        grid_files{k} = destinationFile1;
    end     
end
grid_info.grid_files = grid_files;

end