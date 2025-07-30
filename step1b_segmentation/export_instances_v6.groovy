
//'export_instances_v6.groovy'

//Script to export individual watershed segmentation instances into binary and original image Bounding boxes.
//It should be executed: 
//(1) after 'irregularWatershed_qupath.groovy' script and 
//(2) on individually openned images

//Notes: 
//Name the manual (parent) annotation for consistency in the file naming.
//When there are <256 objects, the labellled image is saved as 8-bit (RGB display). It it saved as 16-bit (*.tif) otherwise.
//Opening the output patches in ImageJ might be buggy when they are *.tif. Save as *.png to avoid crashing the memory

//Written: Marco Acevedo, 6-Oct-24
//Updated: Marco Acevedo, 23-Dec-24, 2-Jun-25

//Documentation
//https://qupath.readthedocs.io/en/latest/docs/advanced/exporting_annotations.html
//https://qupath.github.io/javadoc/docs/qupath/lib/images/servers/LabeledImageServer.Builder.html
//https://qupath.github.io/javadoc/docs/qupath/lib/objects/PathObject.html
//https://qupath.github.io/javadoc/docs/qupath/lib/objects/hierarchy/PathObjectHierarchy.html
//https://qupath.readthedocs.io/en/stable/docs/tutorials/exporting_measurements.html

//Forum:
//Peter Haub: https://forum.image.sc/t/export-multiple-annotations-at-once-as-images/88800/2
//Peter Bankhead (older version): https://gist.github.com/petebankhead/7547d0cd6b35ec587e163e61b75af081/revisions
//https://forum.image.sc/t/how-select-object-by-class-and-parent/68511
//https://forum.image.sc/t/qupath-saving-filtered-detectiontable-with-measurementexporter-for-current-image-only/41328/2

//Dependencies
import qupath.lib.images.servers.LabeledImageServer
import qupath.lib.gui.tools.MeasurementExporter
import qupath.lib.objects.PathAnnotationObject

//Script 

def imageData = getCurrentImageData()
def name_img = GeneralTools.getNameWithoutExtension(imageData.getServer().getMetadata().getName()) //opened image
def pathOutput = buildFilePath(PROJECT_BASE_DIR, name_img)

mkdirs(pathOutput)

// Define output resolution
double requestedPixelSize = 1.0
double downsample = requestedPixelSize / imageData.getServer().getPixelCalibration().getAveragedPixelSize()

// ImageServer where the pixels are derived from annotations
def labelServer = new LabeledImageServer.Builder(imageData)
    .backgroundLabel(0, ColorTools.WHITE) // Specify background label (usually 0 or 255)
    .downsample(downsample)    // Choose server resolution; this should match the resolution at which tiles are exported
    .useInstanceLabels() // Assign labels based on instances, not classifications
    .multichannelOutput(false) // If true, each label refers to the channel of a multichannel binary image (required for multiclass probability)
    .grayscale(true) //output consistency
    .useFilter({ p -> p.isAnnotation() && p.getParent()?.getPathClass() == getPathClass('zircon') })  
    .build()
    
//Original image in QuPath
def server = imageData.getServer() //def server = getCurrentServer()

def annotations = getDetectionObjects().findAll { it.getPathClass()== getPathClass('zircon') } //path to annotations
//def annotations = getDetectionObjects() //path to annotations
//getAnnotationObjects; getDetectionObjects; getAllObjects

//Export each region
for (annotation in annotations) {

    def annotation0 = annotation.getParent() //from manual annotation
    def annotation_name = annotation0.getName()
    
    def childDetections = annotation.getChildObjects() //from irregular watershed segmentation script

    if (childDetections) {
      childDetections.eachWithIndex{detection, idx->
        //idx restarts from 0 for each class. it is not reliable
        
        def idx_ImageJ = detection.getName()
        def roi = detection.getROI() //outline

        //labelled image patch (with other instances around it)
        def request = RegionRequest.createInstance(labelServer.getPath(),
            downsample, roi)
        def outputName = "${name_img}_${annotation_name}_${idx_ImageJ}_[x=${request.x},y=${request.y},w=${request.width},h=${request.height}]_mask.tif"
        def outputPath = buildFilePath(pathOutput, outputName) //.png
                
        //original image
        def request_img = RegionRequest.createInstance(server.getPath(),
            downsample, roi)
        def outputName2 = "${name_img}_${annotation_name}_${idx_ImageJ}_[x=${request.x},y=${request.y},w=${request.width},h=${request.height}].tif"
        def outputPath2 = buildFilePath(pathOutput, outputName2) //.png
        
        //Save
        writeImageRegion(labelServer, request, outputPath)
        writeImageRegion(server, request_img, outputPath2)

        //println outputPath
        }
      }
}

//Export instance measurements

def project = getProject()

def entry = getProjectEntry()
entryList = [] //def imagesToExport = project.getImageList()
entryList << getProjectEntry()
def name_txt = entry.getImageName() + '_measurements.csv'

//def columnsToInclude = new String[]{} //default=all; "Name", "Class", "Nucleus: Area"
def columnsToInclude = new String[]{"Image", "Object ID", "Object type", "Name", "Classification", "Parent", "ROI", "Centroid X px", "Centroid Y px", "Time index", "Area", "Mean", "Min", "Max", "Area px^2", "Perimeter px"}

def exportType = PathAnnotationObject.class
def outputPath = buildFilePath(PROJECT_BASE_DIR, name_img, name_txt) //.tsv
def outputFile = new File(outputPath)

def exporter  = new MeasurementExporter()
                  .imageList(entryList)            // Images from which measurements will be exported                  
                  .filter({ obj -> obj.isAnnotation() })
                  //.filter({ obj -> obj.isAnnotation() && obj.getParent()?.getPathClass() == getPathClass('zircon') })
                  .separator(",") //"\t"                 // Character that separates values
                  .includeOnlyColumns(columnsToInclude) // Columns are case-sensitive
                  .exportType(exportType)               // Type of objects to export
                  .exportMeasurements(outputFile)        // Start the export process


print "Done!"
