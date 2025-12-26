
function [laser_data_sub, status_laser] = load_stepFour_output(filename_11, sample_str)
%Data after Step 4 ('imageRegistration_v7.m' script and Iolite)

try
    status_laser = 1;
    laser_data = readtable(filename_11, 'VariableNamingRule','preserve');    
    
    %Filter Iolite output by sampleName column (e.g., 'CA24MR_1_second')
    if strcmp(sample_str, '')
        laser_data_sub = laser_data;
    else
        idx_sample = contains(laser_data.sampleName, sample_str);
        laser_data_sub = laser_data(idx_sample, :);
    end
    
catch ME    
    laser_data_sub = [];
    status_laser = 0;
    
    display(ME.message);
    
end