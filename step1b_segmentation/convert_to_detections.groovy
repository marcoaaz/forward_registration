// Convert annotations to detections
def annotations = getAnnotationObjects().findAll{it.getPathClass() == getPathClass("zircon")}
def newDetections = annotations.collect{
    return PathObjects.createDetectionObject(it.getROI(), it.getPathClass())
}
removeObjects(annotations, true) // uncomment to delete original annotations
addObjects(newDetections)