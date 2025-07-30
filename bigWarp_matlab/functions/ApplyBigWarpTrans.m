function [transformed_points] = ApplyBigWarpTrans(landmarks_path, points, max_iters, inv_tol)

% Interfaces with my java script 'TransformPoints' which acts as a driver
% for the BigWarp java files in order to apply the same tranformations to
% the input points as 'Apply_Bigwarp_Xfm_csvPts' from BigWarp.

% landmarks_path should be the path to the landmarks file you want, 
% points should be a nx3 array of points to be transformed, 
% max_iters should be the maximum number of iterations for the transformation, and 
% inv_tol should be you acceptable error on the inverse calculation.

% import TransformPoints %already imported
%Error: Unable to find or import  Imported names must end with '.*' or be fully qualified.

transformer = TransformPoints;
transformed_points = transformer.transform(landmarks_path, points, inv_tol, max_iters);

%Note: the compiled Java class
%..\bigWarp_matlab\java_files\classes\bigwarp\scripts\..

end

