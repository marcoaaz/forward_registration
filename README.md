# forward_registration

Repository with the image analysis pipeline to study minerals with combined microscopy techniques and micro-analytical spots. 

## Workflow

Schematic workflow:

<img width=80% height=80% alt="Image" src="https://github.com/user-attachments/assets/d87ff7c5-099b-4279-becf-e6422532c90a" />

Data and script flow:

<img width=80% height=80% alt="Image" src="https://github.com/user-attachments/assets/e5909253-59ff-4a98-b6b4-ff35b3087008" />

## Installation and required libraries

The MatLab scripts can be run with:

MATLAB Version: 24.2.0.2740171 (R2024b) Update 1
MATLAB License Number: 31
Operating System: Microsoft Windows 11 Enterprise Version 10.0 (Build 22631)
Java Version: Java 1.8.0_202-b08 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode

- MATLAB                                                Version 24.2        (R2024b)
- Computer Vision Toolbox                               Version 24.2        (R2024b)
- Curve Fitting Toolbox                                 Version 24.2        (R2024b)
- Deep Learning Toolbox                                 Version 24.2        (R2024b)
- Fixed-Point Designer                                  Version 24.2        (R2024b)
- Global Optimization Toolbox                           Version 24.2        (R2024b)
- Image Processing Toolbox                              Version 24.2        (R2024b)
- MATLAB Compiler                                       Version 24.2        (R2024b)
- Mapping Toolbox                                       Version 24.2        (R2024b)
- Optimization Toolbox                                  Version 24.2        (R2024b)
- Parallel Computing Toolbox                            Version 24.2        (R2024b)
- Signal Processing Toolbox                             Version 24.2        (R2024b)
- Statistics and Machine Learning Toolbox               Version 24.2        (R2024b)
- Symbolic Math Toolbox                                 Version 24.2        (R2024b)
- Wavelet Toolbox                                       Version 24.2        (R2024b)

The Python scripts require environments to be set up. You can use the nearby requirements.txt files. I recommend deploying in VSCode IDE.

The R scripts require R version 4.4.3 (2025-02-28 ucrt) -- "Trophy Case" for x86_64-w64-mingw32/x64 platform. You can use RStudio 2024 to visualise/edit them according to your needs.

#### Supplementary Data

Uploading to Zenodo..

After downloading all the data, you need to update the filepaths (within your system) to every required input file/image/folder.

#### Cite

Please cite the following publication (currently under review) describing the present software (see Supplementary Material A):

"Forward image registration for higher level interpretation of zircon provenance based on combined CL, U/Pb age and geochemical data"

Marco A. Acevedo Zamora1*, Balz S. Kamber1, John T. Caulfield1, Charlotte M. Allen1,2, and Justin S. Freeman3

1 Queensland University of Technology, School of Earth and Atmospheric Sciences, Brisbane, QLD, Australia.
2 Queensland University of Technology, Central Analytical Research Facility
3 SEM Applications Scientist, Thermo Fisher Scientific, Brisbane, QLD, Australia; justin.freeman@thermofisher.com

* Corresponding author: marco.acevedozamora@qut.edu.au 
https://orcid.org/0000-0003-3330-3828

Keywords: image analysis, forward registration, grid display, colour cathodoluminescence, correlative microscopy

Thank you.
