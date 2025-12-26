# -*- coding: utf-8 -*-
"""
'stitch_MAPS_v1.py' 

Script to reconstruct Maps (Thermo Fischer) from a fully saved project 
containing a 'stitched' experiment series from a SEM-BSE/CL scan
( E:\Justin Freeman collab\Marco Zircon\LayersData\Layer\Zircon_T1-B (3) (stitched) ).
The tiles (frames) do not present any overlap and are distributed in sub-folders
following the montage columns and rows.

Written by: Marco Andres, ACEVEDO ZAMORA
Created on Fri 6-Dec-24
Published (first version): 
Updated (second version): 

Followed sources:
https://code.visualstudio.com/docs/python/environments
Followed scripts using arrayjoin: 
test_script.py, DSA_wsi_predicting_v4.py, stitch_stretch.py


Runs in: python 3.10.11 with 'pyvips_env5'venv

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

## User input

#automatic input
workingDir = r'D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\Zircon_Row1 (2) (stitched)'
# workingDir = r'E:\Justin Freeman collab\Marco Zircon\LayersData\Layer\Zircon_T1-R-G (2) (stitched)'

fileList = glob.glob(f"{workingDir}/****/***/**/*.tif", recursive = True) 
# pattern = re.compile(r".+\\(.+)\\.+\\(.+)\\(.+)\\tile_(.+)\.tif")
pattern = re.compile(r".+\\T(\d+)-Z(\d+)-CH(\d+)\\.+\\l_(\d+)\\c_(\d+)\\tile_(\d+)\.tif")

image_name = "output"
destDir_parent = os.path.join(workingDir, image_name)
if not os.path.exists(destDir_parent):
    try:
        os.mkdir(destDir_parent)
    except OSError as e:
        print(f"An error has occurred: {e}")
        raise

#Learning arrangement
values = [] 
#optional: tile time series, z series, 
#included: channels, resolution layer (full = 6), column, row
#channels in Apreo 2 (BSE, red CL, green CL)

for filename in fileList:
# for filename in fileList[499:501]: #trial    
    
    match = pattern.match(filename) # scan image set (perfect match needed)      
    item_c = int(match.group(3))
    item_pyramid = int(match.group(4))
    item_col = int(match.group(5))
    item_row = int(match.group(6))
    
    values.append([item_c, item_pyramid, item_col, item_row])

df = pd.DataFrame(values, columns =['channel', 'pyramid', 'col', 'row'])
df.insert(0, "path", fileList, True)
df1 = df.sort_values(['channel', 'pyramid', 'row', 'col'], 
              ascending=[True, True, True, True])

pyramids = [6]
channels = df1['channel'].unique()

for pyramid in pyramids:
    for channel in channels:
        
        #subset
        idx1 = df1['pyramid'] == pyramid
        idx2 = df1['channel'] == channel
        df2 = df1[idx1 & idx2]

        #info
        filenames = df2['path']
        tiles_down = df2['row'].max() + 1 #count
        tiles_across = df2['col'].max() + 1
        print(f"down= {tiles_down}, across= {tiles_across}")

        tiles = []
        for filename in filenames:
            tiles.append(pyvips.Image.new_from_file(filename))

        image = pyvips.Image.arrayjoin(tiles, across=tiles_across)

        basename = f'montage_l{pyramid}_c{channel}.tif'
        destFile = os.path.join(destDir_parent, basename)
        image.write_to_file(destFile)

        # print(df2)
# n_cols = df['channel'].unique()
# n_rows = df['channel'].unique()

