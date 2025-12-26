import os

def save_tiles(img, size, destDir_parent, tag):
    #Apply on labelled image (first)

    tiles_across = 1 + int(img.width / size)
    tiles_down = 1 + int(img.height / size)
    
    condition_list = []
    # chop into tiles and save 
    for y in range(0, tiles_down):
        for x in range(0, tiles_across):
            destFile = os.path.join(destDir_parent, tag + f"_x{x:04d}_y{y:04d}.tif") 

            tile = img.crop(x * size, y * size,
                            min(size, img.width - x * size),
                            min(size, img.height - y * size))
            
            avg = (tile > 0).avg()
            condition_positive = (avg > 0)
            condition_list.append(condition_positive)

            if condition_positive:
                tile.write_to_file(destFile)

    return condition_list