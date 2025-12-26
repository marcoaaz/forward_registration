
import os
from helperFunctions.remove import remove #relative path

def mkdir2(destDir_parent):    
    if not os.path.exists(destDir_parent):
        try:
            os.mkdir(destDir_parent)
        except:
            print(f"Folder already existed. Now clearing..")            
            remove(destDir_parent)
            os.mkdir(destDir_parent)

def mkdir1(destDir_parent):    
    if not os.path.exists(destDir_parent):
        try:
            os.mkdir(destDir_parent)
        except:
            print(f"Folder already existed.")            
            
            