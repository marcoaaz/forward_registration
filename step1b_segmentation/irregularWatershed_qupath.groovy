
//'irregularWatershed_qupath.groovy'

//Script to split semantic segmentation mask (threshold) into objects using irregular watershed
//The script only runs in QuPath detections nested in a QuPath annotation (see Hierarchy)..

//Pre-requisites:
//In QuPath, one has to switch the pre-installed ImageJ plugin directory (Menu > Extensions > ImageJ > Set plugins directory) 
//to the user Fiji installation plugin directory.

//In ImageJ > Update > Manage Updates > BioVoxxel 3D Box (activate). 
//Activate only "BioVoxxel_Figure_Tools-4.0.1.jar" to avoid conflicting with previous versions 
//(BioVoxxel_Figure_Tools-2.3.0.jar) in BioVoxxel or BioVoxxel 3D Box.

//Step 1:
//Draw 'brush' annotation around FoV that needs watershed segmentation (whole-mount image)

//Step 2
//QuPath > Classify > Pixel classifier > Create thresholder (parameters below)
//Resolution: full, Channel: Channel 1, Prefilter: Gaussian, 
//Smoothing sigma: 0, Threshold: 28600 (example for 16-bit BSE), 
//Above threshold: zircon, Below threshold: background
//Classifier name: th_trial1 > Save

//Step 3
//In the same window, Create objects > Choose parent objects > Current selection
//New object type: Detection, Minimum object size: 1000, Minimum hole size: 100 (px^2)

//Step 4 (Run this script)
//QuPath > Automate > Script editor > Open: 'irregularWatershed_qupath.groovy'

//Notes: 
//"Analyze Particles..." produces X-Y centroids that are not valid for the original image.
//image demo: 50K x 11K px (6 min processing). Very close to produce RAM overflow (32 GB)
//Analyze Particles: plugin defaults: size=1000, convexity_threshold=0.85
//size=5000 (change depending on input resolution)

//Created: Marco Acevedo, 2-Oct-24
//Updated: Marco Acevedo, 19-Dec-24. 2-Jun-25

//Documentation
//https://forum.image.sc/t/using-watershed-to-split-annotations-in-qupath/60183/4
//https://imagej.net/plugins/biovoxxel-toolbox
//https://imagej.net/ij/docs/menus/analyze.html

//Dependencies
import qupath.imagej.gui.ImageJMacroRunner
import qupath.lib.plugins.parameters.ParameterList

//Script

def imageData = getCurrentImageData()
def base_dir = GeneralTools.getNameWithoutExtension(imageData.getServer().getMetadata().getName())
def pathOutput = buildFilePath(PROJECT_BASE_DIR, base_dir)
def params = new ImageJMacroRunner(getQuPath()).getParameterList()

print ParameterList.getParameterListJSON(params, ' ')

// Use the JSON to identify the key
params.getParameters().get('downsampleFactor').setValue(1.0 as double)
params.getParameters().get('sendROI').setValue(true) //false: the thing I wanted to watershed inside a larger annotation
params.getParameters().get('getOverlay').setValue(true) //get back ROIs 
params.getParameters().get('getOverlayAs').setValue("Annotations") //Annotations

print ParameterList.getParameterListJSON(params, ' ')

mkdirs(pathOutput)

//measurements
text_file = 'analyzeParticles_output.csv'
String path0 = buildFilePath(pathOutput, text_file);
path = path0.replace("\\", "/") //PROJECT_BASE_DIR returns Windows \
print path

//size=1500
def macro = 'run("Create Mask");\n' +
        'run("Fill Holes");\n' +
        'run("Watershed Irregular Features", "erosion=1 convexity_threshold=0.88 separator_size=0-Infinity");\n' +
        'run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape integrated median skewness kurtosis area_fraction stack display redirect=None decimal=3");\n' +
        'run("Analyze Particles...", "size=2600-Infinity display include overlay");\n' +        
        'saveAs("Measurements", "' + path + '");\n'
       
// Loop through the annotations and run the macro
for (annotation in getDetectionObjects()) {
    ImageJMacroRunner.runMacro(params, imageData, null, annotation, macro)
}

//Medicine: Clearing Results table
def params2 = new ImageJMacroRunner(getQuPath()).getParameterList()
params2.getParameters().get('downsampleFactor').setValue(1.0 as double)
def macro2 = 'run("Clear Results");\n'
for (annotation in getDetectionObjects()) {
    ImageJMacroRunner.runMacro(params2, imageData, null, annotation, macro2)
}

print 'Done!'