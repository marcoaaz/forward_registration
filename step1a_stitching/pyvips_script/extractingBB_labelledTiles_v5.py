# -*- coding: utf-8 -*-
"""
'extractingBB_labelledTiles_v5.py'

Generating a whole-mount image following pre-sliced binary image patch (bounding box) coordinates 
obtained from image segmentation (instances) in ImageJ macro (AutoRadio_Segmenter version with mask export) 
and retrospectively generated with 'extractingBB_retrospectively_v2.py'.

Script that loops a series of large images, reads, and pastes the masks (labelled according to the grain number) 

Processing of 42 whole-mount images takes 15 min (not sure yet). 

The latest output = E:\Feb-March_2024_zircon imaging\cl_zircon_twoCorrections\originals_fixed\input_v5\SAM_1024x1024


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
from ismember import ismember #for multiple patches search

def remove(path):
    """ param <path> could either be relative or absolute. """
    if os.path.isfile(path) or os.path.islink(path):
        os.remove(path)  # remove the file
    elif os.path.isdir(path):
        shutil.rmtree(path)  # remove dir and all contains
    else:
        raise ValueError("file {} is not a file or dir.".format(path))
    
def mkdir2(destDir_parent):
    try:
        remove(destDir_parent)
    except:
        print("Producing original pyramid for the first time")

    if not os.path.exists(destDir_parent):
        try:
            os.mkdir(destDir_parent)
        except OSError as e:
            print(f"An error has occurred: {e}")
            raise

#count number of pixels in pyvips image
def total(image):
    return image.avg() * image.width * image.height * image.bands


def save_tiles(img, destDir_parent, tag):
    tiles_across = 1 + int(img.width / size)
    tiles_down = 1 + int(img.height / size)
    
    condition_list = []
    # chop into tiles and save 
    for y in range(0, tiles_down):
        for x in range(0, tiles_across):
            destFile = os.path.join(destDir_parent, tag + f"_x{x:04d}_y{y:04d}.tif") 

            tile = img.crop(x * size, y * size,
                            min(size, img.width - x * size),
                            min(size, img.height - y * size))
            
            avg = (tile > 0).avg()
            condition_positive = (avg > 0)
            condition_list.append(condition_positive)

            if condition_positive:
                tile.write_to_file(destFile)

    return condition_list

def save_tiles_informed(img, condition_list, destDir_parent, tag):

    tiles_across = 1 + int(img.width / size)
    tiles_down = 1 + int(img.height / size)    
    k = -1

    # chop into tiles and save 
    for y in range(0, tiles_down):
        for x in range(0, tiles_across):
            
            k += 1
            destFile = os.path.join(destDir_parent, tag + f"_x{x:04d}_y{y:04d}.tif") #leading zeros

            tile = img.crop(x * size, y * size,
                            min(size, img.width - x * size),
                            min(size, img.height - y * size))
                        
            if condition_list[k]:
                tile.write_to_file(destFile)

    return

## User input

root_dir = "E:\Feb-March_2024_zircon imaging\cl_zircon_twoCorrections\originals_fixed"
workingDir = "E:\\Feb-March_2024_zircon imaging\\cl_zircon_twoCorrections\\originals_fixed\\input_v5"
image_name = "SAM_2048x2048" #output folder

size = 2048 #block size

## Script

#automatic input
path_list = glob.glob(f"{root_dir}/*.tif", recursive = True) + glob.glob(f"{root_dir}/*.png", recursive = True)
maskDir = os.path.join(workingDir, "Binary masks")

destDir_parent = os.path.join(workingDir, image_name)
destDir_parent1 = os.path.join(destDir_parent, 'labels')
destDir_parent2 = os.path.join(destDir_parent, 'images')
mkdir2(destDir_parent)
mkdir2(destDir_parent1)
mkdir2(destDir_parent2)

#ECU_996_997_CL_inverted_1_mask_[x=8526,y=636,w=175,h=97].tif
fileList = glob.glob(f"{maskDir}/**/*.tif", recursive = True) 

#regex
pattern_original = re.compile(r".+\\.+\\(.+)_inverted_.+\.tif") 
pattern = re.compile(r".+\\(.+)\\(.+)_mask_\[x=(.+),y=(.+),w=(.+),h=(.+)\]\.tif") #for Windows \\
pattern_grain = re.compile(r".+\\.+\\.+_(.+)_mask_.+\.tif")

n_masks = len(fileList)

multiples_dir = r"E:\Feb-March_2024_zircon imaging\02_John Caulfield_files\Multiples"
multiples_List = glob.glob(f"{multiples_dir}/**/*.tif", recursive = True) 

#basenames
fileList2 = [os.path.basename(x) for x in fileList] #_mask_
fileList3 = [x.replace("_mask", "") for x in fileList2]
multiples_List2 = [os.path.basename(x) for x in multiples_List]

#full names for loop
I, idx = ismember(fileList3, multiples_List2)
fileList4 = np.array(fileList)[~I]

# print(type(fileList4))

for imageInput_path in path_list: #[0:3]
#subset recommended; cannot be a subset at the same time as the inner loop; [path_list[0]]
    
    k = 0 #save only images with content

    path1_temp = os.path.split(imageInput_path)
    tag = path1_temp[1].replace(".tif", "") #daughter file
    # print(f"Processing {tag}")           
    
    #Load whole-mount image            
    large_image = pyvips.Image.new_from_file(imageInput_path) #, access="sequential"
    zero_wsi = np.zeros((large_image.height, large_image.width, 3), dtype=np.uint16)
    
    list_sample = []
    list_grain = []   

    for filename in fileList4: #subsetting not recommended
    # for filename in fileList[0:36310]: #trial            

        # scan image set (perfect match needed)      
        match = pattern.match(filename)
        match_grain = pattern_grain.match(filename)
        match_original = pattern_original.match(filename) #ECU_944_945_CL_highres
        condition = (match_original.group(1) in tag) #same sample mount       
        
        if match and condition:             
            k += 1                

            sample = match.group(1)
            patch = match.group(2) #also has sample name
            x = int(match.group(3))
            y = int(match.group(4))
            w = int(match.group(5))
            h = int(match.group(6))            
            grain_number = match_grain.group(1)        
            grain_number_int = int(grain_number)

            list_sample.append(sample)
            list_grain.append(grain_number)            
            print(f"Processing {sample} grain {grain_number} of image patch with bb: {x}, {y}, {w}, {h}")         

            #getting original mask
            image = pyvips.Image.new_from_file(filename) #cannot be "sequential" access            
            mask_1 = (image == 255).bandand() #fg=1
            mask_1_b = (mask_1.numpy() == 255)            
            mask_1_np = grain_number_int*np.dstack([mask_1_b, mask_1_b, mask_1_b])

            #extracting patch from large image (looped)
            from_row = y
            to_row = from_row + h
            from_col = x
            to_col = from_col + w
            mask_2_np = zero_wsi[from_row:to_row, from_col:to_col, :]           

            tile_masked = (mask_1_np + mask_2_np)  #union                     
            intersection_1 = (mask_1_np > 0) & (mask_2_np > 0) #intersection
            
            #medicine
            tile_masked[intersection_1[:, :, 0]] = np.array([0, 0, 0]).reshape(1, 1, 3)

            zero_wsi[from_row:to_row, from_col:to_col, :] = tile_masked
           
    
    if k>=0:   

        #labelled image      
        img = pyvips.Image.new_from_array(zero_wsi)
        condition_list = save_tiles(img, destDir_parent1, tag)

        #original image
        save_tiles_informed(large_image, condition_list, destDir_parent2, tag)
 

        