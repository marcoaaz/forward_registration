import os

def save_tiles_informed(img, size, condition_list, destDir_parent, tag):
    #Apply on original image (second)

    tiles_across = 1 + int(img.width / size)
    tiles_down = 1 + int(img.height / size)    
    k = -1

    # chop into tiles and save 
    for y in range(0, tiles_down):
        for x in range(0, tiles_across):
            
            k += 1
            destFile = os.path.join(destDir_parent, tag + f"_x{x:04d}_y{y:04d}.tif") #leading zeros

            tile = img.crop(x * size, y * size,
                            min(size, img.width - x * size),
                            min(size, img.height - y * size))
                        
            if condition_list[k]:
                tile.write_to_file(destFile)

    return