import pyvips
import numpy as np

def PT_patches(large_image, mask, bb_original):

    x, y, w, h = bb_original
    
    #getting squared patch (enlarged ROI)            
    bb = [x-2, y-2, w+4, h+4]
    height_factor = bb[3] / mask.height
    width_factor = bb[2] / mask.width
    mask_enlarged = mask.affine((width_factor, 0, 0, height_factor))
    # print(bb)

    #extracting patch from large image    
    tile_enlarged = large_image.crop(bb[0], bb[1], bb[2], bb[3])    
    tile_masked_enlarged = mask_enlarged.ifthenelse(0, tile_enlarged) #for classification
            
    #Generating image patch (following ImageJ macro segmentation)
    border = 6
    if bb[2] > bb[3]:                
        img_zero = pyvips.Image.black(bb[2] + border, bb[2] + border, bands=3)
        L = img_zero.width
        start_point_x = np.floor(L/2) - np.floor(bb[2]/2)
        start_point_y = np.floor(L/2) - np.floor(bb[3]/2)
    else:                
        img_zero = pyvips.Image.black(bb[3] + border, bb[3] + border, bands=3)
        L = img_zero.width
        start_point_x = np.floor(L/2) - np.floor(bb[2]/2)                      
        start_point_y = np.floor(L/2) - np.floor(bb[3]/2)        
    
    img_zero = img_zero.insert(tile_masked_enlarged, 
                    start_point_x, #top
                    start_point_y) #left 
    
    return img_zero