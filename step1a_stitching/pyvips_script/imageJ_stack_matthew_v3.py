# -*- coding: utf-8 -*-
"""
'imageJ_stack_matthew_v3.py' 

Script to save an AMICS software (Bruker) image tile sequence (SEM-BSE and phase map)
as an image tile stack (t-series) grid for montaging in the Stitching plugin.
The total workflow takes 2 minutes and it is followed by splitting the stack
into the BSE and labelled image (phase map). 
The phase map is attributed the original colourmap (LUT lookup table) 
that can be found in the phase map tiles within the project 
'Mineral' folder (manually exported tiles from AMICS). 
To obtain the LUT go to:
ImageJ > Image > Color > Show LUT > List > File > Save As.. > LUT.csv
To apply the LUT select the montaged phase map and go to:
ImageJ > Image > Color > Edit LUT > Open > select LUT.csv > OK
Save the image montages for QuPath segmentation.

Written by: Marco Andres, ACEVEDO ZAMORA
Created on Mon 9-Dec-24
Published (first version): 
Updated (second version): 

Followed sources:
https://pypi.org/project/tifffile/
https://imagej.net/plugins/image-stitching

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

#User input
workingDir = r'F:\AMICS Data\Particle Mapping_scan speed 32'
# workingDir = r'F:\AMICS Data\Matrix Mapping exported frames'

image_name = "output2"

n_rows = 384 #height px
n_cols = 512 #width
dim_tiles = [3, 4] #number of tiles
sel_type = 2 #AMICS: type=2, order=0
sel_order = 0

#Helper functions

#Guide to use grid_numberer():
# tiling_type = ['row-by-row', 'column-by-column', 'snake-by-rows', 'snake-by-columns']
# tiling_order_hz = ['right & down', 'left & down', 'right & up', 'left & up']
# tiling_order_vt = ['down & right', 'down & left', 'up & right', 'up & left']

#Create folder
destDir_parent = os.path.join(workingDir, image_name)
if not os.path.exists(destDir_parent):
    try:
        os.mkdir(destDir_parent)
    except OSError as e:
        print(f"An error has occurred: {e}")
        raise

#Script

fileList = glob.glob(f"{workingDir}/**/*.bmp", recursive = True) 
pattern = re.compile(r".+\\(.+)\\.+_Image_(\d+)\.bmp")

#Learning arrangement
referenceGrid, _ = grid_numberer(dim_tiles, sel_type, sel_order) #snake
desiredGrid, _ = grid_numberer(dim_tiles, 0, 0) #TrakEM2 row-major

vectorGrid_ref = np.asarray(referenceGrid.astype(np.uint32)).reshape(-1) - 1 #python index
vectorGrid = np.asarray(desiredGrid.astype(np.uint32)).reshape(-1) - 1 #python index

vector1 = np.array(
    np.unravel_index(
    vectorGrid, (dim_tiles[0], dim_tiles[1])) ) + 1 #readable

values = []
for filename in fileList:
# for filename in fileList[499:501]: #trial    
    
    match = pattern.match(filename) # scan image set (perfect match needed)      
    item_map = match.group(1)
    item_number = int(match.group(2))
        
    values.append([item_map, item_number])

df = pd.DataFrame(values, columns =['map', 'number'])
df.insert(0, "path", fileList, True)
df1 = df.sort_values(['map', 'number'], ascending=[True, True])

numbers = df1['number'].unique()
for number in numbers:     #[0:1]
        
    #subset
    idx1 = df1['number'] == number    
    df2 = df1[idx1]

    filenames = df2['path'].tolist()    
    im1 = np.array(Image.open(filenames[0])).reshape(n_rows, n_cols, -1)
    im2 = np.array(Image.open(filenames[1])).reshape(n_rows, n_cols, -1)
        
    im_stack = np.stack([im1, im2], axis=3) #has axis 2
    im_stack_t = np.transpose(im_stack, (3, 2, 0, 1)) #z or t, c, y, x            

    #file names
    idx = (vectorGrid_ref == number - 1)    

    name_int1 = vector1[1, idx][0] #readable
    name_int2 = vector1[0, idx][0]    
    name_str = f'tile_x{name_int1:03.0f}_y{name_int2:03.0f}.tif'

    file2 = os.path.join(destDir_parent, name_str)
    imwrite(file2, im_stack_t, 
            imagej=True, metadata={'axes': 'TCYX'}) # write ImageJ hyperstack