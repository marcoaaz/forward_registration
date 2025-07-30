# -*- coding: utf-8 -*-
"""
Slicing a very large image using bounding box coordinates obtained from image segmentation (instances).


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

#example (manual input):
# root_dir = "C:\\Users\\n10832084\\OneDrive - Queensland University of Technology\\Desktop\\10X_bb\\Export"
# file_list = ["20X_ppl_registered.tif", "20X_xpl_registered.tif", "20X_rl_registered.tif", "ECU_996_997_CL.tif"]
# path_list = [root_dir + "\\" + folder for folder in file_list]
# path1 = os.path.split(path_list[0])
# sourceDir = path1[0]
# workingDir = os.path.join(sourceDir, "segmentation_input")

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

list_df = []
for imageInput_path in path_list:    

    path1_temp = os.path.split(imageInput_path)
    tag = path1_temp[1].replace(".tif", "") #daughter file
    print(f"Processing {tag}")         

    destDir_parent = os.path.join(workingDir, "Other modalities")
    destDir = os.path.join(destDir_parent, "Segmented images_" + tag)
    if not os.path.exists(destDir):
        try:
            os.mkdir(destDir)
        except OSError as e:
            print(f"An error has occurred: {e}")
            raise

    #Load whole-mount image            
    large_image = pyvips.Image.new_from_file(imageInput_path) #, access="sequential"

    list_sample = []
    list_grain = []
    list_calculated = []    
    for filename in fileList:
    # for filename in fileList[499:501]: #trial    

        # scan image set (perfect match needed)      
        match = pattern.match(filename)
        match_grain = pattern_grain.match(filename)

        if match:                        

            sample = match.group(1)
            patch = match.group(2) #also has sample name
            x = int(match.group(3))
            y = int(match.group(4))
            w = int(match.group(5))
            h = int(match.group(6))            
            grain_number = match_grain.group(1)            

            
            list_sample.append(sample)
            list_grain.append(grain_number)            
            # print(f"Processing {sample} grain {grain_number} of image patch with bb: {x}, {y}, {w}, {h}")         

            #getting original mask
            image = pyvips.Image.new_from_file(filename) #cannot be "sequential" access
            mask = (image == 0).bandand()

            #getting squared patch (enlarged ROI)            
            bb = [x-2, y-2, w+4, h+4]
            height_factor = bb[3] / mask.height
            width_factor = bb[2] / mask.width
            mask_enlarged = mask.affine((width_factor, 0, 0, height_factor))

            #extracting patch from large image
            tile = large_image.crop(x, y, w, h)
            tile_enlarged = large_image.crop(bb[0], bb[1], bb[2], bb[3])
            
            tile_masked = mask.ifthenelse(0, tile) #for descriptive statistics
            tile_masked_enlarged = mask_enlarged.ifthenelse(0, tile_enlarged) #for classification
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
            
            #Generating image patch (similar to ImageJ macro segmentation)
            border = 6
            if bb[2] > bb[3]:                
                img_zero = pyvips.Image.black(bb[2] + border, bb[2] + border, bands=3)
                L = img_zero.width
                start_point_x = np.floor(L/2) - np.floor(bb[2]/2)
                start_point_y = np.floor(L/2) - np.floor(bb[3]/2)
            else:                
                img_zero = pyvips.Image.black(bb[3] + border, bb[3] + border, bands=3)
                L = img_zero.width
                start_point_x = np.floor(L/2) - np.floor(bb[2]/2)                      
                start_point_y = np.floor(L/2) - np.floor(bb[3]/2)
                
            
            img_zero = img_zero.insert(tile_masked_enlarged, 
                           start_point_x, #top
                           start_point_y) #left   
             
            #Saving image
            folderDest = os.path.join(destDir, sample)
            
            if not os.path.exists(folderDest):
                try:
                    os.mkdir(folderDest)
                except OSError as e:
                    print(f"An error has occurred: {e}")
                    raise

            #patch_name = f"{patch}_{tag}_[x={x},y={y},w={w},h={h}].tif"
            patch_name = f"{patch}_[x={x},y={y},w={w},h={h}].tif"
            fileDest = os.path.join(folderDest, patch_name)       

            # tile_masked.write_to_file(fileDest) #for real images
            img_zero.write_to_file(fileDest) #for patches

    #Info table
    stats_table = pd.DataFrame(list_calculated)
    calculation_names = ['min', 'max', 'std', 'median', 'mode']
    channel_names = ['_R', '_G', '_B']
    stats_table.columns = [tag + "_" + names + channel 
                        for names in calculation_names for channel in channel_names]
    
    
    list_df.append(stats_table)

stats_table_hz = pd.concat(list_df, axis=1, ignore_index=False)
stats_table_hz.insert(0, "sample_rgb", list_sample, True)
stats_table_hz.insert(1, "grain_rgb", list_grain, True)

#save
filename1 = "descriptiveStats_ROI_rgb.csv"
file1 = os.path.join(destDir_parent, filename1)
stats_table_hz.to_csv(file1, sep=',', 
                   encoding='utf-8', index=False, header=True)