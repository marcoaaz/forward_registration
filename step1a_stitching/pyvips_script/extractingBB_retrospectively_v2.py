# -*- coding: utf-8 -*-
"""

Script that calculates and saves the original binary masks from the AutoRadio_segmenter.ijm image patches (AutoRadio_Segmenter version without mask export) 
for a series of patches within the 'Segmented images' folder (and sub-folders for each sample). The mask generation is only executed when there is a match 
with the original CL image at full resolution. It only needs to be run once to obtain foregrounds. 

The latest output = E:\Feb-March_2024_zircon imaging\cl_zircon_twoCorrections\originals_fixed\input_v5\Binary masks

Original environment used: ?

Written by: Marco Andres, ACEVEDO ZAMORA
Created: 12-Jul-24
Update: 

Followed sources:
-https://github.com/cgohlke/roifile
-https://scikit-image.org/docs/stable/api/skimage.draw.html#skimage.draw.polygon

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
import skimage as ski

from skimage.measure import label, regionprops, regionprops_table
from roifile import ImagejRoi

np.set_printoptions(threshold=sys.maxsize)

## User input

segmentation_dir = "E:\Feb-March_2024_zircon imaging\cl_zircon_twoCorrections\originals_fixed\input_v5\Segmented images"
root_dir = "E:\Feb-March_2024_zircon imaging\cl_zircon_twoCorrections\originals_fixed"

## Script

#automatic
path_list = glob.glob(f"{root_dir}/*.tif", recursive = True) + glob.glob(f"{root_dir}/*.png", recursive = True)

#manual
# file_list = ["ECU_944_945_CL_highres.png", "ECU_962_963_CL_highres.png"]
# path_list = [root_dir + "\\" + folder for folder in file_list]

path1 = os.path.split(segmentation_dir)
workingDir = path1[0]
maskDir = os.path.join(workingDir, "Binary masks")

destDir = maskDir
if not os.path.exists(destDir):
    try:
        os.mkdir(destDir)
    except OSError as e:
        print(f"An error has occurred: {e}")
        raise

#ECU_905_906_CL_inverted_1_[x=12683,y=318,w=177,h=175].tif
fileList = glob.glob(f"{segmentation_dir}/**/*.tif", recursive = True) 
pattern = re.compile(r".+\\(.+)\\(.+)_\[x=(.+),y=(.+),w=(.+),h=(.+)\]\.tif") #for Windows \\
pattern_grain = re.compile(r".+\\.+\\.+_(.+)_\[.+\.tif")
pattern_original = re.compile(r".+\\.+\\(.+)_inverted_.+\.tif") 

list_df = []
for imageInput_path in path_list:    

    path1_temp = os.path.split(imageInput_path) #ECU_944_945_CL_highres.png
    tag = path1_temp[1].replace(".tif", "") #daughter file
    # print(f"Processing {tag}")         

    list_sample = []
    list_grain = []
    list_calculated = []    
    for filename in fileList:    
    # for filename in fileList[25:26]: #trial    
    # for filename in fileList[25:27]: #trial 

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

            #ROI
            roi = ImagejRoi.fromfile(filename)
            item1 = roi[0]
            roi_name = item1.name #00124-02189 = grain number-            
            roi_top = item1.top
            roi_left = item1.left
            roi_bottom = item1.bottom #real last pixel
            roi_right = item1.right
            roi_coordinates = item1.integer_coordinates #or multi_coordinates
            roi_multi = item1.multi_coordinates
            
            #medicine (small roi hanging on big one)
            if roi_coordinates is None:                   
                idx_zero = np.where(roi_multi == 0)
                idx_zero1 = idx_zero[0]
                n_polygons = len(idx_zero1)
                
                polygons_found = []
                polygons_len = []
                for i in range(0, n_polygons):
                    try:
                        test = roi_multi[idx_zero1[i]:idx_zero1[i+1]]
                    except:
                        test = roi_multi[idx_zero1[i]:]

                    polygons_len.append(len(test))
                    polygons_found.append(test)                
                    # print(test)
                # print(polygons_found)
                idx_longest = polygons_len.index(max(polygons_len))
                main_polygon = polygons_found[idx_longest][:-1]
                polygon = np.reshape(main_polygon, (-1, 3))[:, 1:]
                polygon2 = np.flip(polygon, axis= 1) #for multi_coordinates

            else:                         
                polygon2 = [roi_top, roi_left] + np.flip(roi_coordinates, axis= 1) #for integer_coordinates    
                
            #Image
            img = pyvips.Image.new_from_file(filename)
            image_shape = (img.width, img.height)       
            mask_fg = ski.draw.polygon2mask(image_shape, polygon2) #enlarged from ImageJ macro
            
            #getting original mask
            mask_fg1 = mask_fg[roi_top:roi_bottom, roi_left:roi_right]
            mask_enlarged = pyvips.Image.new_from_array(mask_fg1)                

            #getting squared patch (enlarged ROI)            
            bb = [x, y, w, h]
            height_factor = bb[3] / mask_enlarged.height
            width_factor = bb[2] / mask_enlarged.width
            mask = mask_enlarged.affine((width_factor, 0, 0, height_factor),
                                        interpolate=pyvips.Interpolate.new("nearest"))

            #Saving mask images
            folderDest = os.path.join(destDir, sample)
            
            if not os.path.exists(folderDest):
                try:
                    os.mkdir(folderDest)
                except OSError as e:
                    print(f"An error has occurred: {e}")
                    raise

            #patch_name = f"{patch}_{tag}_[x={x},y={y},w={w},h={h}].tif"
            patch_name = f"{patch}_mask_[x={x},y={y},w={w},h={h}].tif"

            fileDest = os.path.join(folderDest, patch_name)       
            mask.write_to_file(fileDest) #for masks
