
//Macro  to run "Stitching" plugin on tiff files within a folder and save a montage. 
//It needs to be used after the 'alignStacks_SIFT.ijm' script.
//The plugin will compute the overlap using the phase-correlation algorithm.

//Created: Marco Acevedo, QUT. 18-Dec-24

//Documentation:
//https://imagej.net/plugins/image-stitching
//It always uses the option Apply registration of first time-point to all other time-points (as available in Pairwise Stitching)

//Pre-requisite: run Stitching through the interface once. The macro needs the cached memmory of having used Stitching before use.

//Use / in windows
inputFolder = "E:/Justin Freeman collab/25-mar-2025_Apreo2/CA24MR-1_Redo_stitched and unstitched tiles/row3_BSE_t-grid/SIFT_aligned"
//inputFolder = "E:/Justin Freeman collab/Marco Zircon/LayersData/Layer/output_combined_BSE_t-position_withBSE/SIFT_aligned"

//outputFolder = getDirectory("Choose Output Folder");
outputFolder = inputFolder
inputText = "registered3_row3.txt"
outputFile = outputFolder+ "\\" + "Fused_BSE_CL.tif"


print ("\\Clear"); //Clears the Results window
run("Close All"); //CLose all open images

regression_th=0.5; //.3 above TH values dont make any difference
avg_displacement_th=2.50; //2.5
abs_displacement_th=3.50; //3.5

paramStr = ("type=[Positions from file] order=[Defined by TileConfiguration] directory=[" + inputFolder + "] layout_file=[" + inputText + "] fusion_method=[Linear Blending] regression_threshold=" + regression_th + " max/avg_displacement_threshold=" + avg_displacement_th + " absolute_displacement_threshold=" + abs_displacement_th + " computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
//run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by TileConfiguration] directory=[E:/Justin Freeman collab/Marco Zircon/LayersData/Layer/output_combined_BSE_t-position_withBSE/SIFT_aligned] layout_file=registered3.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");


print(paramStr);
print(outputFile);

run("Grid/Collection stitching", paramStr);
//run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by TileConfiguration] directory=[" + inputFolder + "] layout_file=[" + inputText + "] fusion_method=[Linear Blending] regression_threshold=" + regression_th + " max/avg_displacement_threshold=" + avg_displacement_th + " absolute_displacement_threshold=" + abs_displacement_th + " computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");

//selectWindow("Fused");
run("Grays");
saveAs("Tiff", outputFile); //+ File.separator + "\\"
//run("Close");
