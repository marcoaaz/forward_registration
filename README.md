# forward_registration

The forward registration image analysis pipeline can be deployed to study mineral mounts with combined microscopy techniques and micro-analysis using spots. 

Graphical abstract:

<img width=65% height=65% alt="Image" src="https://github.com/user-attachments/assets/a891fca7-94fe-4f27-96b2-7e651316a1e1" />

## Scientific citation

We studied a hand-picked zircon epoxy mount from a location in Murray River Basin (Australia) in a research article using the approach. If using the forward registration approach, please cite: 

**"Acevedo Zamora, M. A., Kamber, B. S., Caulfield, J. T., Allen, C. M., & Freeman, J. S. (2026). Forward Image Registration for Higher Level Interpretation of Zircon Provenance Based on Combined CL, U/Pb Age, and Geochemical Data. Geochemistry, Geophysics, Geosystems, 27(7), e2025GC012671. https://doi.org/10.1029/2025GC012671**
* Corresponding author: marco.acevedozamora@qut.edu.au (https://orcid.org/0000-0003-3330-3828)

Preliminary work was presented at:
- "A Step Change in Multi-Dimensional Zircon Provenance Analysis from Forward Registered CL, U/Pb Age, and Trace Element Data." Acevedo Zamora MA, Kamber BS, Caulfield JT & Allen CM (2025). https://goldschmidtabstracts.info/abstracts/abstractView?doi=10.7185/gold2025.26671
-	"Forward Image Registration for Higher Level Interpretation of Zircon Provenance Based on Combined CL, U/Pb Age and Geochemical Data." Acevedo Zamora MA, Kamber BS, Caulfield JT & Allen CM (2025). https://goldschmidtabstracts.info/abstracts/abstractView?id=2020016303
-	"Mineral Separate Microanalysis with Intelligent Spot Placement, Manual Edition, and Simulation: Two Correlative Microscopy Prototypes for Relating Zircon Texture, Age, and Geochemistry."  Acevedo Zamora MA, Caulfield JT, Laupland E, Kamber BS, Allen CM (2025). https://www.scienceopen.com/hosted-document?doi=10.14293/APMC13-2025-0280

If using the image analysis workflow code entirely or partially, do not forget to cite the authors of the corresponding software libraries that have been used in this repository as well (see external software repositories). Support open-source.


## Image analysis pipeline

The steps of the pipeline are: 1) image processing including image stitching (full version), grain segmentation, and montage registration, (2) grain image processing into grids, (3) desktop computer spot placement, (4) two-step image registration, microanalysis, and data reduction, (5) data source fusion into a master table, and (6) documentation of correlative microscopy findings including imagery, geochemistry, and U-Pb ages.

Schematic workflow to study zircon mounts using state-of-the-art microscopy and laser ablation ICP-MS:

<img width=70% height=70% alt="Image" src="https://github.com/user-attachments/assets/ecd73f6b-144c-4882-acc4-09fd46a2a8bf" />

Details of the steps routines, data and script flows (denoted by arrows):

<img width=70% height=70% alt="Image" src="https://github.com/user-attachments/assets/6237d3d9-6295-4b69-b273-e5e7293da38d" />

The slide below shows the programming languages sequence for all the Steps. Step 5 (master table) in bold font is the main MatLab script (merge_grids_v9.m) that orchestrates the data flow that comes in the master table and is shown as grid displays. The plug-in cartoon represents the external software that can be streamlined to the pipeline:

<img width=60% height=60% alt="Image" src="https://github.com/user-attachments/assets/6af06a1f-2b06-4a16-b90a-160c984401a7" />


## Installation and required libraries

The MatLab scripts require:

MATLAB Version: 24.2.0.2740171 (R2024b) Update 1
Operating System: Microsoft Windows 11 Enterprise Version 10.0 (Build 22631)
Java Version: Java 1.8.0_202-b08 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode
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

The Python scripts require environments to be set up. You can use the nearby requirements.txt files (see folder and sub-folders). I recommend deploying Python environments in VSCode IDE.

The R scripts require R version 4.4.3 (2025-02-28 ucrt) -- "Trophy Case" for x86_64-w64-mingw32/x64 platform. You can use RStudio 2024 to visualise/edit them according to your needs.

Step 1 used [Fiji](https://imagej.net/software/fiji/) distribution (ImageJ 1.54f) macros and plugins ([tile stitching](https://imagej.net/plugins/trakem2/), [montage registration](https://imagej.net/plugins/bigwarp), [segmentation](https://imagej.net/plugins/biovoxxel-toolbox)). Step 1a involved using [pyvips](https://github.com/libvips/pyvips) library. Steps 1 and 3 worked using [QuPath](https://qupath.github.io/) version 0.5.1 (Build time: 2024-03-04). 

If there are any omissions in terms of software and citations. Please, let me know to my personal email. Thanks for your understanding.


#### Supplementary Data

For trialling Step 3, the manual spot placement dataset can be downloaded from [Zenodo](https://zenodo.org/records/16750323) and opened in QuPath software. 

For full reproducibility of the paper results (and figures), the original dataset can be downloaded in four parts (total ~200 GB) containing: 
-	[Part 1](https://zenodo.org/records/16625000): CA-24MR-1 Puck 1 image analysis intermediate files and outputs from Step 5 (merge_script_v9.m). Iolite version 4 chemical data for pucks 1 and 2 and Iolite v4 projects. Ruby Creek imagery by Geoscience Australia. Data for Figure 8 and Table 1. Master table data dictionary with variable description (‘appended_DB_dictionary_v2_Marco.xlsx’). SEM experimental metadata in puck 1 TIMA and puck 2 Apreo 2 (similar to puck 1) experiments. 
-	[Part 2](https://zenodo.org/records/16625000): Puck 1 image analysis inputs, intermediate files, and outputs.
- [Part 3](https://zenodo.org/records/16653718): Puck 2 image analysis inputs, intermediate files, and outputs.
-	[Part 4](https://zenodo.org/records/16655509): Puck 2 image stitching (Step 1) inputs and intermediate files.

After download, the user needs the scripts within this repository (follow Step subfolders) and update the filepaths within your system mapping every required input file/image/folder to achieve the same results. 

The full explanation of the workflow is in Supporting information Text 1. The exact script metadata to reproduce the manuscript figures are given in the Supporting information Text 2.


Thank you.

Cordially,

Marco

