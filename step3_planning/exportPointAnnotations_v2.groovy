
//'exportPointAnnotations_v2.groovy'

//Export the expert point annotations of all annotated images to corresponding GEOJSON files.
//These files are then read by 'collect_pointAnnotations.m' function within 'prototype_two_v9.m' script.

directory = PROJECT_BASE_DIR

def project = getProject()

for (entry in project.getImageList()) {    

    
    String name = entry.getImageName()
    def imageData = entry.readImageData()
    def hierarchy = imageData.getHierarchy()
    def annotations = hierarchy.getAnnotationObjects()
    
    def n_annotations = annotations.size()
    
    if(n_annotations > 0){
        //Set the file
        path = buildFilePath(PROJECT_BASE_DIR,  name + ".geojson")
        //path = directory + "/" + name + ".geojson"
        
        //Export GeoJson
        exportObjectsToGeoJson(annotations, path, "FEATURE_COLLECTION")
        
        }            
}

print 'done'