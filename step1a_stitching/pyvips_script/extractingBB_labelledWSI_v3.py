# -*- coding: utf-8 -*-
"""
'extractingBB_labelledWSI_v3.py'

Update of 'extractingBB_quPath workflow_v2.py' that allows generating
a labelled whole-mount image (labelled according to the grain number) 
following original binary image patches coordinates (bounding box) 
from a prior image segmentation into grain object masks using a QuPath 
software script that calls the irregular watershed (ImageJ-BioVoxxel).

The script loops through all the binary masks available and, optionally, 
re-saves the image as patches (LxL) compatible with ParticleTrieur using 
the reformatted large image (input). This is done one large image at the 
time (no loop)  

Further development: 
enable labelled image tiles (original and labelled image)
for training SAM model.

Notes:
The patch saving filename cannot be too large to avoid 'pyvips.error.Error: unable to call VipsForeignSaveJpegFile'

Created: 2-Jan-25, Marco Andres, ACEVEDO ZAMORA
Updated: 31-Jan-25, 3-Jun-25, M.A.

Followed sources:
'extractingBB_labelledTiles_v5.py'
'extractingBB_quPath workflow.py'

Runs in: python 3.10.11 with 'pyvips_env6'venv

"""

#Dependencies   
import os
import sys

vipsbin = r'c:\vips-dev-8.16\bin'
add_dll_dir = getattr(os, 'add_dll_directory', None)
if callable(add_dll_dir):
    add_dll_dir(vipsbin)
else:
    os.environ['PATH'] = os.pathsep.join((vipsbin, os.environ['PATH']))
import pyvips

import glob
import re
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from skimage.measure import label, regionprops

from ismember import ismember #for multiple patches search

#relative paths
from helperFunctions.mkdir2 import mkdir1, mkdir2 
from helperFunctions.save_tiles import save_tiles
from helperFunctions.save_tiles_informed import save_tiles_informed
from helperFunctions.img_stats import img_stats
from helperFunctions.PT_patches import PT_patches

#region User input

output_option = 1 #pre-determined output formats
imagePatch_format = '.jpg' #.tif output for ParticleTrieur
size = 2048 #input block size for training SAM
output2 = "wsi_labelled.tif" #input for 'prototype_two_v3.m' script

#Segmentation mask
# workingDir = r"E:\Justin Freeman collab\Marco Zircon_16bit\prototype2_work\qupath_project" #grain segmentation
# workingDir = r"D:\Charlotte_spot proj\qupath_segmentation" #grain segmentation
workingDir = r"C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\Ruby Creek_db_imagery\GA6141_Cross_Mole granite\registered\segmentation"

input_folder = r"RL_GA6141 200701550" #Binary mask folder (per image that was segmented)
project_name = input_folder + "_1" #for output (specify BSE, CL, etc.) 3-Jun-25_run2

#Large image(s)

#Option A: Parse folder
#root_dir = r"D:\Charlotte_spot proj\marco obs\Klamath" 
#path_list = glob.glob(f"{root_dir}/*.tif", recursive = True) + glob.glob(f"{root_dir}/*.png", recursive = True)

#Option B: Enter manually
path_list = [
    r"C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\Ruby Creek_db_imagery\GA6141_Cross_Mole granite\registered\CL_GA6141 200701550.tif",
    r"C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\Ruby Creek_db_imagery\GA6141_Cross_Mole granite\registered\RL_GA6141 200701550.tif",
    r"C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\Ruby Creek_db_imagery\GA6141_Cross_Mole granite\registered\TL_GA6141 200701550.tif",
    
]



#endregion 

#region Script

maskDir = os.path.join(workingDir, input_folder)
destDir_parent = os.path.join(workingDir, project_name)
mkdir1(destDir_parent) #mkdir2

#ECU_996_997_CL_inverted_1_mask_[x=8526,y=636,w=175,h=97].tif
# fileList = glob.glob(f"{maskDir}/**/*_mask.tif", recursive = True) 
fileList = glob.glob(f"{maskDir}/*_mask.tif", recursive = True) 
n_masks = len(fileList)

#regex
pattern_original = re.compile(r".+\\.+\\(.+)_null_.+_mask.tif") #null = ROI annotation name ('thresholded')
pattern = re.compile(r".+\\(.+)\\(.+)_\[x=(.+),y=(.+),w=(.+),h=(.+)\]_mask\.tif") #for Windows \\
pattern_grain = re.compile(r".+\\.+\\.+_(\d+)_\[.+\.tif")
pattern_patch = re.compile(r".+\\(.+)_mask\.tif")

fileList4 = fileList
# print(type(fileList4))

#info table preparation
calculation_names = ['min', 'max', 'std', 'median', 'mode']
channel_names = ['R', 'G', 'B'] #edit: ['R', 'G', 'B']; ['grey']
combination_names = [names + "_" + channel for names in calculation_names for channel in channel_names]

#subset recommended; cannot be a subset at the same time as the inner loop; [path_list[0]]    
for imageInput_path in path_list: #[0:3]    
    k = 0 #save only images with content

    path1_temp = os.path.split(imageInput_path)
    tag = path1_temp[1].replace(".tif", "") #daughter file

    print(f"Processing {tag}")           
    
    #Generating saving directories
    folderDest = os.path.join(destDir_parent, tag) #, sample
    destDir_parent1 = os.path.join(folderDest, 'labels')
    destDir_parent2 = os.path.join(folderDest, 'images')
    destDir_parent3 = os.path.join(folderDest, 'PT_patches')
    mkdir2(folderDest)
    mkdir2(destDir_parent1)
    mkdir2(destDir_parent2)
    mkdir2(destDir_parent3)
    
    #Load whole-mount image            
    large_image = pyvips.Image.new_from_file(imageInput_path) #, page=2; , access="sequential"
    n_rows = large_image.height
    n_cols = large_image.width
    n_channels = large_image.bands #1 is enough
    zero_wsi = np.zeros((n_rows, n_cols, n_channels), dtype=np.uint16)
    
    list_sample = []
    list_grain = []   
    list_calculated = []
    for filename in fileList4: #subsetting not recommended
    # for filename in fileList4[0:2]: #trial                    
        
        # scan image set (perfect match needed)      
        match_original = pattern_original.match(filename) #Fused_BSE_CL_16-bit_tresholded_1_[x=40605,y=192,w=229,h=623]_mask
        match = pattern.match(filename)
        match_grain = pattern_grain.match(filename)
        match_full = pattern_patch.match(filename) #for re-saving

        if match:             
            k += 1                

            description_full = match_full.group(1)
            sample = match.group(1)
            patch = match.group(2) #also has sample name
            x = int(match.group(3))
            y = int(match.group(4))
            w = int(match.group(5))
            h = int(match.group(6))            
            grain_number = match_grain.group(1)   

            bb_original = [x, y, w, h]                             
            grain_number_int = int(grain_number)
            
            list_sample.append(sample)
            list_grain.append(grain_number)            
            #print(f"Processing {sample} grain {grain_number} of image patch with bb: {x}, {y}, {w}, {h}")         

            #getting original mask
            image = pyvips.Image.new_from_file(filename) 
            image_np = image.numpy()

            img_labelled = label(image_np)
            r = regionprops(img_labelled)
            mask_fg = (img_labelled == (1 + np.argmax([i.area for i in r])) ).astype(int) #foreground mask                    
            
            #endregion

            # region Labelled WSI
            mask_1_np = grain_number_int*np.dstack([mask_fg]) #adds 1 dimension
            
            #extracting patch from large mask image
            from_row = y
            to_row = from_row + h
            from_col = x
            to_col = from_col + w
            mask_2_np = zero_wsi[from_row:to_row, from_col:to_col, :]           

            #incorporating
            mask_np = (mask_1_np + mask_2_np) #union                     
            intersection_1 = (mask_1_np > 0) & (mask_2_np > 0) #intersection                      
            mask_np[intersection_1[:, :, 0]] = 0 #medicine

            zero_wsi[from_row:to_row, from_col:to_col, :] = mask_np

            #endregion

            #region PT patches
            mask_fg1 = pyvips.Image.new_from_array(mask_fg)  
            mask = (mask_fg1 == 0).bandand() #background=1
            
            img_zero = PT_patches(large_image, mask, bb_original)
            # print(img_zero)

            #Descriptive statistics.    
            tile = large_image.crop(x, y, w, h)
            tile_masked = mask.ifthenelse(0, tile) #where bg=1, keep background 
            
            #min, max, std, median, mode, (for each channel)
            val_calculated2, n_channels_stats = img_stats(tile_masked, mask) 
            list_calculated.append(val_calculated2)            

            #Save tiles            
            patch_name = f"{description_full}{imagePatch_format}" 
            fileDest = os.path.join(destDir_parent3, patch_name)                   

            match output_option:
                case 1:  #to 16-bit (original)
                    tile_masked3 = img_zero #pyvips image

                case 2:  #to 8-bit rgb (shift every value left by 8 bits) 
                    #=Option 1 if 24-bit input                              
                    tile_masked3 = img_zero.cast("uchar", shift= True) #shift every value left by 8 bits        
                    
                case 3: #to 8-bit greyscale
                    tile_masked3_rgb = img_zero.cast("uchar", shift= True) #shift every value left by 8 bits
                    tile_masked3_greyscale = tile_masked3_rgb.colourspace("b-w")        
                    temp = [tile_masked3_greyscale, tile_masked3_greyscale]
                    tile_masked3 = tile_masked3_greyscale.bandjoin(temp)

                case 4: #to 8-bit rgb w/ adjusted contrast (user friendly option)
                    loc_min_from = (1 - 1)*n_channels_stats
                    loc_min_to = loc_min_from + n_channels_stats
                    loc_max_from = (2 - 1)*n_channels_stats
                    loc_max_to = loc_max_from + n_channels_stats
                    
                    val_min_list = val_calculated2[loc_min_from:loc_min_to] 
                    val_max_list = val_calculated2[loc_max_from:loc_max_to] 
                    val_min = numpy.average(val_min_list)
                    val_max = numpy.average(val_max_list)
                    #Note: the rescaling below could be improved
                    
                    tile_masked2 = (img_zero - val_min) * (256 / (val_max - val_min))            
                    tile_masked3 = pyvips.Image.new_from_array(tile_masked2).cast("uchar")              
            
            tile_masked3.write_to_file(fileDest) #for patches            
            
            #endregion      

    #Info table
    stats_table = pd.DataFrame(list_calculated)   

    stats_table.columns = [tag + "_" + s for s in combination_names]    
    stats_table.insert(0, "sample_rgb", list_sample, True)
    stats_table.insert(1, "grain_rgb", list_grain, True)
    #save
    filename1 = tag + "_colourStats.csv" #within grain mask only
    file1 = os.path.join(destDir_parent, filename1)
    stats_table.to_csv(file1, sep=',', encoding='utf-8', 
                       index=False, header=True)    
    
    if k>=0:           
        print('no optionals')
        #as Labelled image WSI
        destFile = os.path.join(destDir_parent, output2)
        img = pyvips.Image.new_from_array(zero_wsi)
        img.write_to_file(destFile)

        # #as blocks
        # #labelled image      
        # img = pyvips.Image.new_from_array(zero_wsi)
        # condition_list = save_tiles(img, size, destDir_parent1, tag)

        # #original image
        # save_tiles_informed(large_image, size, condition_list, destDir_parent2, tag) 

#endregion 