# forward_registration

Repository with the image analysis pipeline to study mineral mounts with combined microscopy techniques and micro-analytical spots. The case study are hand-picked zircon epoxy mounts from a location in Australia (Murray River Basin). More details in the manuscript (currently under review).

## Workflow

Schematic workflow to study zircon mounts using state-of-the-art microscopy and laser ablation ICP-MS:

<img width=70% height=70% alt="Image" src="https://github.com/user-attachments/assets/d87ff7c5-099b-4279-becf-e6422532c90a" />

Data and script flows (denoted by arrows):

<img width=70% height=70% alt="Image" src="https://github.com/user-attachments/assets/e5909253-59ff-4a98-b6b4-ff35b3087008" />

Software sequence (programming languages) and output of Step 5 (master table). The plug-in symbol represents the external software that can be streamlined to the pipeline:

<img width=60% height=60% alt="Image" src="https://github.com/user-attachments/assets/6af06a1f-2b06-4a16-b90a-160c984401a7" />

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

The Python scripts require environments to be set up. You can use the nearby requirements.txt files. I recommend deploying Python environments in VSCode IDE.

The R scripts require R version 4.4.3 (2025-02-28 ucrt) -- "Trophy Case" for x86_64-w64-mingw32/x64 platform. You can use RStudio 2024 to visualise/edit them according to your needs.

Step 1 used [Fiji](https://imagej.net/software/fiji/) distribution (ImageJ 1.54f) macros and plugins ([registration](https://imagej.net/plugins/bigwarp), [segmentation](https://imagej.net/plugins/biovoxxel-toolbox)). Step 1a involved using [pyvips](https://github.com/libvips/pyvips) library. 

Steps 1 and 3 worked using [QuPath](https://qupath.github.io/) version 0.5.1 (Build time: 2024-03-04). 

#### Supplementary Data

Uploading to Zenodo..

After downloading all the data, you need to edit the downloaded scripts and update the filepaths (within your system) mapping every required input file/image/folder to achieve the same results. The parameters are given in the paper Supplementary Material B.

#### Documentation

See paper Supplementary Material A.

#### Cite

If using the software pipeline or an independent module script, please cite:

"Forward image registration for higher level interpretation of zircon provenance based on combined CL, U/Pb age and geochemical data"

Marco A. Acevedo Zamora1*, Balz S. Kamber1, John T. Caulfield1, Charlotte M. Allen1,2, and Justin S. Freeman3

1 Queensland University of Technology, School of Earth and Atmospheric Sciences, Brisbane, QLD, Australia.
2 Queensland University of Technology, Central Analytical Research Facility
3 SEM Applications Scientist, Thermo Fisher Scientific, Brisbane, QLD, Australia; justin.freeman@thermofisher.com

* Corresponding author: marco.acevedozamora@qut.edu.au 
https://orcid.org/0000-0003-3330-3828

Keywords: image analysis, forward registration, grid display, colour cathodoluminescence, correlative microscopy

Thank you.
