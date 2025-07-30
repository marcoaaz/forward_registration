# -*- coding: utf-8 -*-
"""
'stitch_MAPS_overlap_v3.py' 

Script for saving SEM-BSE/CL experiments image tiles (with overlap) from a 
Maps software (Thermo Fischer) project as misaligned image stacks (*.tif).
The tiles (frames) present are distributed in single folders for each 
experiment that contributes data.

This script is part of larger workflow.

Created on Fri 10-Dec-24, Marco Andres, ACEVEDO ZAMORA
Published (first version): 
Updated (second version): 

Followed sources:
https://code.visualstudio.com/docs/python/environments

Runs in: python 3.10.11 with 'pyvips_env6'venv

"""

#Dependencies   
import os
vipshome = 'C:\vips-dev-8.16\bin'
os.environ['PATH'] = vipshome + ';' + os.environ['PATH']

import sys
import pyvips
import glob
import re
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import shutil

from tifffile import imwrite
from PIL import Image
from helperFunctions.grid_numberer import grid_numberer #relative path

#region Helper function
def mkdir1(destDir_parent):
    if not os.path.exists(destDir_parent):
        try:
            os.mkdir(destDir_parent)
        except OSError as e:
            print(f"An error has occurred: {e}")
            raise

def convert(img, output_range, input_range, target_type):
    #Followoinng MatLab: rescale(A, [lower upper], "InputMin", range_min,"InputMax", range_max)

    imin = input_range[0]
    imax = input_range[1]
    target_type_min = output_range[0]
    target_type_max = output_range[1]    

    a = (target_type_max - target_type_min) / (imax - imin)
    b = target_type_max - a * imax
    new_img = (a * img + b).astype(target_type)

    return new_img

#endregion

#region User input

workingDir = r'E:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles'
folder1 = r'Zircon_Row4 (2)'
# folder2 = 'CA24MR-1_Zircon_CL-G-B'
workingDir1 = os.path.join(workingDir, folder1) #16bit
# workingDir2 = os.path.join(workingDir, folder2) 

folder_name = "BSE_t-grid"
input_folders = [folder1]
input_channels = [0, 1, 2, 3] #known to be available in input

input_combinations = [    
    [0, 0], #BSE
    [0, 1], #R   
    [0, 2], #G   
    [0, 3], #B   
                         ] #CL images

#Bit depth transformation
input_range = [0, 65535]                
output_range = [0, 255] #0-255
target_type = 'uint8' #bit depth= 'uint8'   

#endregion

#region Script

fileList = glob.glob(f"{workingDir1}/*.tif", recursive = True) #+ glob.glob(f"{workingDir2}/*.tif", recursive = True) 

pattern = re.compile(r".+\\(.+)\\Tile_(\d+)-(\d+)-.*_(\d+)-.*\.tif")
#Maps software convention: Tile_001-013-000000_0-000.s0001_e00.tif

parentDir = os.path.dirname(workingDir1)
destDir_parent = os.path.join(parentDir, folder_name)
mkdir1(destDir_parent)

#Learning arrangement
values = [] 

for filename in fileList:
# for filename in fileList[499:501]: #trial    
    
    match = pattern.match(filename) # scan image set (perfect match needed)      

    item_folder = match.group(1)
    item_row = int(match.group(2))    
    item_col = int(match.group(3))    
    item_c = int(match.group(4)) #channel

    values.append([item_folder, item_c, item_col, item_row])

df = pd.DataFrame(values, columns =['folder', 'channel', 'col', 'row'])
df.insert(0, "path", fileList, True)
df1 = df.sort_values(['folder', 'channel', 'row', 'col'], 
              ascending=[True, True, True, True])

# print(df1)
# df1.to_csv(os.path.join(parentDir, 'df1.csv'), sep=',')

#info
filenames = df1['path']
rows = df1['row']
cols = df1['col']
tiles_down = rows.max() #count
tiles_across = cols.max()
rows_span = rows.unique()
cols_span = cols.unique()
dim = np.array(Image.open(filenames[0])).shape #random tile

print(f"down= {tiles_down}, across= {tiles_across}")

#row-major order
k = 0
for row in rows_span:    
    for col in cols_span:
        k = k + 1 #series

        tile_layers = []
        for combination in input_combinations:
        
            #subset        
            idx1 = df1['row'] == row
            idx2 = df1['col'] == col
            idx3 = df1['folder'] == input_folders[combination[0]]
            idx4 = df1['channel'] == input_channels[combination[1]]
            idx = idx1 & idx2 & idx3 & idx4   
                        
            try: 
                path_temp = df1.loc[idx, 'path'].array[0]
                img_temp = np.array(Image.open(path_temp))

            except: #missing tile
                # print(df1.loc[idx, 'path'])
                # print(input_folders[combination[0]])
                # print(input_channels[combination[1]])
                
                img_temp = np.zeros( dim, dtype= np.uint16) #issue fixed
       
            input_type = img_temp.dtype

            if input_type == 'uint16':
                img_temp2 = img_temp
                # img_temp2 = convert(img_temp, output_range, input_range, target_type) #optional
            else:
                pass

            img_temp3 = np.expand_dims(img_temp2, axis=2)            
            tile_layers.append(img_temp3)

        im_stack = np.stack(tile_layers, axis=3) #has axis 2
        im_stack_t = np.transpose(im_stack, (3, 2, 0, 1)) #z or t, c, y, x 

        # name_str = f'tile_{k:03.0f}.tif' #TrakEM2 sequence         
        name_str = f'tile_x{col:03.0f}_y{row:03.0f}.tif' #Stitching plugin
        file2 = os.path.join(destDir_parent, name_str)

        # #Option 1: write ImageJ hyperstack for TrakEM2
        # imwrite(file2, im_stack_t, 
        #         imagej=True, metadata={'axes': 'TCYX'}) 

        #Option 2: write ImageJ hyperstack for ImageJ-Stitching
        imwrite(file2, im_stack_t, 
                imagej=True, metadata={'axes': 'TCYX'}) # 
        
#endregion