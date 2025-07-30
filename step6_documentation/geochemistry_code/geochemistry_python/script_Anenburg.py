#Script to calculate lambda-3 parameter of a REE smooth curve

#Documentation: 
# https://pyrolite.readthedocs.io/en/main/examples/geochem/lambdas.html
# https://lambdar.rses.anu.edu.au/blambdar/
#Citation: https://link.springer.com/article/10.1007/s11004-021-09959-5#citeas

#Created: 1-Aug-2024, Marco Acevedo
#Updated: 30-Apr-2025

import os
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import argparse

# import pyrolite.plot
from pyrolite.util.synthetic import example_spider_data
from pyrolite.util.lambdas.plot import plot_lambdas_components

default_path = r""
#Read CMD input
parser = argparse.ArgumentParser(description='Script for calculating lambda parameters')
parser.add_argument('--input', action="store", dest='input', default= default_path)
args = parser.parse_args()
sourceDir = args.input

file1 = 'input_Anenburg.csv'
file2 = 'output_Anenburg.csv'
filepath1 = os.path.join(sourceDir, file1)
filepath2 = os.path.join(sourceDir, file2) #patternCoeff_output_Chondrite Lattice_.95

df = pd.read_table(filepath1, delimiter=',')

ls = df.pyrochem.lambda_lnREE(degree=4, algorithm="ONeill", 
                              exclude=["Ce", "Eu"], anomalies=["Ce", "Eu"], 
                              add_X2=True, sigmas=0.1, add_uncertainties=True)

ls.insert(0, "id_number", df["id_number"])

ls = ls.rename(columns={'λ0': 'lambda_0', 'λ1': 'lambda_1', 'λ2': 'lambda_2', 'λ3': 'lambda_3',
                        'λ0_σ': 'lambda_0_sigma', 'λ1_σ': 'lambda_1_sigma', 'λ2_σ': 'lambda_2_sigma', 'λ3_σ': 'lambda_3_sigma', 
                        'X2': 'fit_chi_squared', 'Ce/Ce*': 'Ce_ratio_A', 'Eu/Eu*': 'Eu_ratio_A'})

#Save
ls.to_csv(filepath2, sep=",", index=False)
