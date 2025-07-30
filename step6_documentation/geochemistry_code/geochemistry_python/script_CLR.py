'''
#Script to calculate CLR compositions

#Documentation: 
https://pyrolite.readthedocs.io/en/main/examples/comp/compositional_data.html
https://pyrolite.readthedocs.io/en/main/examples/comp/logtransforms.html

#Citation: 'A Concise Guide to Compositional Data Analysis' Aitchison, John (1984)

#Created: 27-Jun-2025, Marco Acevedo
#Updated: 

'''
import os
import pandas as pd
import argparse
import pyrolite.comp

default_path = r""
#Read CMD input
parser = argparse.ArgumentParser(description='Script for calculating lambda parameters')
parser.add_argument('--input', action="store", dest='input', default= default_path)
args = parser.parse_args()
sourceDir = args.input

file1 = 'input_CLR.csv'
file2 = 'output_CLR.csv'
filepath1 = os.path.join(sourceDir, file1)
filepath2 = os.path.join(sourceDir, file2) #patternCoeff_output_Chondrite Lattice_.95

df = pd.read_table(filepath1, delimiter=',')

participate_cols = [col for col in df.columns if '_ppm_mean' in col]
output_cols = [col.replace('_ppm_mean','_clr') for col in participate_cols]

df1 = df[participate_cols]
lr_df = df1.pyrocomp.CLR()
lr_df.columns = output_cols

#Save
lr_df.to_csv(filepath2, sep=",", index=False)
