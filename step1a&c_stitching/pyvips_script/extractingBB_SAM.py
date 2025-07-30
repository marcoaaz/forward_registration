# -*- coding: utf-8 -*-
"""
Slicing a very large image using bounding box coordinates obtained from image segmentation (instances).

Update of ‘extractingBB_v5.py’ to extract the original patches corresponding to the previously generated binary masks into two separate folders 
(without sub-folders for each sample). This will be used for training SAM (https://segment-anything.com/demo). Contributed for Abdullah Nazib.

Written by: Marco Andres, ACEVEDO ZAMORA
Created: 27-Jun-24
Update: 10-Jul-24

Followed sources:
-https://stackoverflow.com/questions/62646688/best-way-to-find-modes-of-an-array-along-the-column


"""
#!/usr/bin/python3

#Dependencies   
import os
import sys
import pyvips
import glob
import re
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import shutil

## User input

#automatic input
root_dir = "E:\Feb-March_2024_zircon imaging\cl_zircon_twoCorrections\originals_fixed"
path_list = glob.glob(f"{root_dir}/*.tif", recursive = True) + glob.glob(f"{root_dir}/*.png", recursive = True)

## Script

workingDir = "E:\\Feb-March_2024_zircon imaging\\cl_zircon_twoCorrections\\originals_fixed\\input_v5"
maskDir = os.path.join(workingDir, "Binary masks")

#ECU_996_997_CL_inverted_1_mask_[x=8526,y=636,w=175,h=97].tif
fileList = glob.glob(f"{maskDir}/**/*.tif", recursive = True) 
pattern = re.compile(r".+\\(.+)\\(.+)_mask_\[x=(.+),y=(.+),w=(.+),h=(.+)\]\.tif") #for Windows \\
pattern_grain = re.compile(r".+\\.+\\.+_(.+)_mask_.+\.tif")
pattern_original = re.compile(r".+\\.+\\(.+)_inverted_.+\.tif") 

folder_name1 = "SAM_input_png_8bit"
folder_name2 = "images"
folder_name3 = "masks"
image_name = "Cathodoluminescence" #for Excel table
destDir_parent1 = os.path.join(workingDir, folder_name1)
destDir_parent2 = os.path.join(destDir_parent1, folder_name2)
destDir_parent3 = os.path.join(destDir_parent1, folder_name3)

if not os.path.exists(destDir_parent1):
    try:
        os.mkdir(destDir_parent1)
        os.mkdir(destDir_parent2)
        os.mkdir(destDir_parent3)
    except OSError as e:
        print(f"An error has occurred: {e}")
        raise

list_df = []
for imageInput_path in path_list:    

    path1_temp = os.path.split(imageInput_path)
    tag = path1_temp[1].replace(".tif", "") #daughter file
    print(f"Processing {tag}")           

    #Load whole-mount image            
    large_image = pyvips.Image.new_from_file(imageInput_path) #, access="sequential"

    list_sample = []
    list_grain = []
    list_calculated = []    
    for filename in fileList:
    # for filename in fileList[499:501]: #trial (does not work)       

        # scan image set (perfect match needed)      
        match = pattern.match(filename)
        match_grain = pattern_grain.match(filename)
        match_original = pattern_original.match(filename) #ECU_944_945_CL_highres
        condition = (match_original.group(1) in tag) #same sample mount

        if match and condition:                  

            sample = match.group(1)
            patch = match.group(2) #also has sample name
            x = int(match.group(3))
            y = int(match.group(4))
            w = int(match.group(5))
            h = int(match.group(6))            
            grain_number = match_grain.group(1)        
            
            list_sample.append(sample)
            list_grain.append(grain_number)            
            print(f"Processing {sample} grain {grain_number} of image patch with bb: {x}, {y}, {w}, {h}")         

            #getting original mask
            image = pyvips.Image.new_from_file(filename) #cannot be "sequential" access
            mask = (image == 0).bandand() #background
            mask_fg = (image == 255).bandand() #foreground

            #getting squared patch (enlarged ROI)            
            bb = [x, y, w, h]            

            #extracting patch from large image
            tile = large_image.crop(x, y, w, h)            
            
            tile_masked = mask.ifthenelse(0, tile) #for descriptive statistics            
            n_channels = tile_masked.bands
            
            #ROI interrogation (similar to pyvips 'stats')
            array1 = tile_masked.numpy()       
            array2 = mask.numpy() #uint8
            array_mask = (array2 == 0) #255, bool in foreground       
            pixels = array1[array_mask] #n_pixels x n_channels                          

            if n_channels == 1:
                temp1 = np.reshape(pixels, (-1, 1))
                pixels = np.tile(temp1, (1, 3))       

            val_min = np.min(pixels, 0) #uint8
            val_max = np.max(pixels, 0)                        
            val_std = np.std(pixels, 0) #double
            #mean is not useful            
            val_median = np.median(pixels, 0)        
            val_mode = np.zeros(3) #1D        
            for col in range(len(val_mode)):                        
                values, counts = np.unique(pixels[:, col], return_counts = True)
                val_mode[col] = values[np.argmax(counts)]      

            val_calculated = [val_min, val_max, val_std, val_median, val_mode]        
            val_calculated2 = list(np.concatenate(val_calculated).flat)        
            list_calculated.append(val_calculated2)
                         
            #Saving images    
            #patch_name = f"{patch}_{tag}_[x={x},y={y},w={w},h={h}].tif"
            patch_name = f"{patch}_[x={x},y={y},w={w},h={h}].png"
            fileDest2 = os.path.join(destDir_parent2, patch_name) #images
            fileDest3 = os.path.join(destDir_parent3, patch_name) #masks

            tile_masked2 = tile_masked.cast("uchar", shift= True) #shift every value left by 8 bits
            tile_masked2.write_to_file(fileDest2) 
            mask_fg.write_to_file(fileDest3)
    
    #Info table
    stats_table = pd.DataFrame(list_calculated)
    calculation_names = ['min', 'max', 'std', 'median', 'mode']
    channel_names = ['_R', '_G', '_B']
    stats_table.columns = [image_name + "_" + names + channel 
                        for names in calculation_names for channel in channel_names]
    
    stats_table.insert(0, "sample_rgb", list_sample, True)
    stats_table.insert(1, "grain_rgb", list_grain, True)
    
    list_df.append(stats_table)

stats_table_vt = pd.concat(list_df, axis=0, ignore_index=False)


#save
filename1 = "descriptiveStats_ROI_rgb.csv"
file1 = os.path.join(destDir_parent1, filename1)
stats_table_vt.to_csv(file1, sep=',', 
                   encoding='utf-8', index=False, header=True)