
import numpy as np

def img_stats(tile_masked, mask):

    #ROI interrogation (similar to pyvips 'stats')
    array1 = tile_masked.numpy() #masked patch (zero indentations)      
    array2 = mask.numpy() #true mask, uint8
    array_mask = (array2 == 0) #255, bool in foreground       
    pixels = array1[array_mask] #n_pixels x n_channels                          

    n_channels = tile_masked.bands
    if n_channels == 1:
        temp1 = np.reshape(pixels, (-1, 1))
        pixels = np.tile(temp1, (1, 3))  #force it to repeat thrice      

    val_min = np.min(pixels, 0) #uint8
    val_max = np.max(pixels, 0)                        
    val_std = np.std(pixels, 0) #double             
    val_median = np.median(pixels, 0)        
    val_mode = np.zeros(3) #1D. n_channels=3        
    for col in range(len(val_mode)):                        
        values, counts = np.unique(pixels[:, col], return_counts = True)
        val_mode[col] = values[np.argmax(counts)]      
    #Note: the mean is not useful   

    val_calculated = [val_min, val_max, val_std, val_median, val_mode]        
    val_calculated2 = list(np.concatenate(val_calculated).flat)    
    
    return val_calculated2, n_channels