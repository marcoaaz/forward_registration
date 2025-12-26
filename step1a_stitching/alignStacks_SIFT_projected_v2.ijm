

//Macro  to run the plugin "Linear Stack Alignment with SIFT" on tiff files in a folder. 
//Will save the aligned files in a folder called "Aligned Images"
//Open image files using Bioformats (tif) and save the aligned stacks as t-series

//Created: Pradeep Rajasekhar, Monash Institute of Pharmaceutical Sciences, Australia (pradeep.rajasekhar at gmail)
//Modified: Marco Acevedo, QUT. 13-Dec-24

//Documentation:
//https://github.com/pr4deepr/imagej_macros/tree/master
//https://imagej.net/Linear_Stack_Alignment_with_SIFT

outputFolder1 = "SIFT_aligned"; //default= SIFT_aligned
outputFolder2 = outputFolder1 + "_std";

name_layer1 = "BSE";
final_name = "Concatenated";

print ("\\Clear"); //Clears the Results window
run("Close All"); //CLose all open images

input = getDirectory("Choose Input Directory "); //create directory lists
output_path1 = input + outputFolder1 + File.separator;
output_path2 = input + outputFolder2 + File.separator;

//Make a directory with name Aligned images in the input directory to save the aligned images
if (!File.exists(output_path1)) 
	{
	File.makeDirectory(output_path1);
	}

if (!File.exists(output_path2))
	{
	File.makeDirectory(output_path2);
	}
	
extension= getString("Enter the extension of the files.", "tif"); //can disable this by entering extension ="tif"; if you always use tif files
setBatchMode(true); //batchmode set to True
input_list = getFileList(input); //get no of files

new_file_list=ext_file(input,input_list,extension);
Array.print(new_file_list);
//run a for loop iteratively on each file within the folder
for (i=0; i<new_file_list.length; i++) //loop through all the files in the directory
{
	path=input+new_file_list[i]; //Initialise path variable with the file path

	if (endsWith(path, extension)) //only execute following code if file ends with lif// could adapt to other microscopy formats
		{
		if(i==0);
		
		run("Bio-Formats Importer", "open=["+path+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		name = getTitle();
		print("Active Image: " + name);		
		
		run("Duplicate...", "title="+name_layer1+" duplicate range=1-1");
		//selectWindow(name_layer1);
		
		//Align
		selectWindow(name);
		run("Slice Remover", "first=1 last=1 increment=1"); //SIFT uses the first frame as template for alignment; IF first few frames have artefacts and mess up the alignment, remove the backslashes to activate this
		
		getDimensions(width, height, channels, slices, frames); //get the number of frames		
		align_sift(); //call function to align image
		name2 = "Aligned "+frames+" of "+frames;				
		
		wait(100);
		close(name); //close the original image
		
		strA = "  title="+final_name+" image1="+name_layer1+" image2="+name2;
		print(strA);
		
		//Concatenate
		run("Concatenate...", "  title="+final_name+" image1="+name_layer1+" image2=["+name2+"]");
		
		//Set metadata
		selectWindow(final_name);		
		run("Properties...", "channels=1 slices=1 frames=" + (frames + 1) + " pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000"); //for t-series for Stitching plugin
		
		//Save A		
		name3 = getTitle();
		selectWindow(name3);		
		saveAs("Tiff", output_path1 + name); //save the new aligned image tile in the same directory
		
		//Z-project
		run("Z Project...", "projection=[Standard Deviation]"); //float-32
		//run("Z Project...", "projection=[Average Intensity]"); //8-bit (optional)
		
		//Save A		
		name4 = getTitle();
		selectWindow(name4);		
		saveAs("Tiff", output_path2 + name); //save the new aligned image tile in the same directory		
				
		close(name2); //CL aligned
		close(final_name); //BSE + CL aligned
		close(name3); //stack (BSE + CL aligned) 
		close(name4); //stack z-project 
		}
}

setBatchMode(false); //batchmode set to False
print("The ImageJ macro finished.");

//function to get the list of files that have the extension passed from the main code 
function ext_file(input,input_list,extension)
{
	
	setOption("ExpandableArrays", true); //automatically expand array size on the go.
	ext_file_array=newArray; //store the file list
	j=0; //initialise j as array number for th ext_file_array. Otherwise if the first file is does not have the extension and we use ext_file_array[i] instead, it will throw an error 
	for (i=0; i<input_list.length; i++) //loop through all the files in the directory
	{
		path=input+input_list[i]; //Initialise path variable with the file path
	if(endsWith (path,extension))
	{
		ext_file_array[j]=input_list[i];
		j+=1; //increase counter by 1
	}
	}
	return ext_file_array;
}

function align_sift()
{
	initial_gaussian_blur=1.60;
	steps_per_scale_octave=3;
	minimum_image_size=700;
	maximum_image_size=2600; 
	feature_descriptor_size=8; 
	feature_descriptor_orientation_bins=8;
	closest_ratio=0.92; 
	maximal_alignment_error=25; 
	inlier_ratio=0.05; 
	expected_transformation= "Translation";
	
	run("Linear Stack Alignment with SIFT", "initial_gaussian_blur=" + initial_gaussian_blur + " steps_per_scale_octave=" + steps_per_scale_octave + " minimum_image_size=" + minimum_image_size + " maximum_image_size=" + maximum_image_size + " feature_descriptor_size=" + feature_descriptor_size + " feature_descriptor_orientation_bins=" + feature_descriptor_orientation_bins + " closest/next_closest_ratio=" + closest_ratio + " maximal_alignment_error=" + maximal_alignment_error + " inlier_ratio=" + inlier_ratio + " expected_transformation=" + expected_transformation + " ");
}

