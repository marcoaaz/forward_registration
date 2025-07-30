
import numpy as np

def grid_numberer(dim_tiles, sel_type_python, sel_order_python):

    nrows_tiles_input = dim_tiles[0]
    ncols_tiles_input = dim_tiles[1]
    nrows_tiles = nrows_tiles_input - 2
    ncols_tiles = ncols_tiles_input - 2

    #loop fix: MatLab to Python indexing
    sel_type = sel_type_python + 1
    sel_order = sel_order_python + 1

    # Menu
    tiling_type = ['row-by-row', 'column-by-column', 'snake-by-rows', 'snake-by-columns']
    tiling_order_hz = ['right & down', 'left & down', 'right & up', 'left & up']
    tiling_order_vt = ['down & right', 'down & left', 'up & right', 'up & left']

    # Naming
    if sel_type % 2 == 1:  # odd
        tiling_order = tiling_order_hz
        exterior_loop = dim_tiles[0]
        interior_loop = dim_tiles[1]
    else:
        tiling_order = tiling_order_vt
        exterior_loop = dim_tiles[1]
        interior_loop = dim_tiles[0]

    tiling_name = f'Type: {tiling_type[sel_type_python]}; Order: {tiling_order[sel_order_python]}'
    print(tiling_name)

    # Creating grid
    count = 0
    referenceGrid = np.zeros((nrows_tiles_input, ncols_tiles_input))
    for i in range(0, exterior_loop):
        for j in range(0, interior_loop):
            count += 1
            
            if sel_type == 1:
                if sel_order == 1:
                    row_index = i                
                    col_index = j
                elif sel_order == 2:
                    row_index = i                
                    col_index = ncols_tiles - j + 1
                elif sel_order == 3:
                    row_index = nrows_tiles - i + 1                
                    col_index = j
                elif sel_order == 4:
                    row_index = nrows_tiles - i + 1               
                    col_index = ncols_tiles - j + 1
            elif sel_type == 2:
                if sel_order == 1:
                    row_index = j                
                    col_index = i
                elif sel_order == 2:
                    row_index = j                
                    col_index = ncols_tiles - i + 1
                elif sel_order == 3:
                    row_index = nrows_tiles - j + 1                
                    col_index = i
                elif sel_order == 4:
                    row_index = nrows_tiles - j + 1               
                    col_index = ncols_tiles - i + 1
            elif sel_type == 3:
                if sel_order == 1:
                    row_index = i
                    col_index = j
                    if not row_index % 2 != 1:  # pair (for python)                      
                        col_index = ncols_tiles - j + 1                   
                elif sel_order == 2:
                    row_index = i 
                    col_index = j
                    if not row_index % 2 == 1:  # odd                        
                        col_index = ncols_tiles - j + 1 
                elif sel_order == 3:
                    row_index = nrows_tiles - i + 1                
                    col_index = j 
                    if not row_index % 2 != 1:  # pair                       
                        col_index = ncols_tiles - j + 1
                elif sel_order == 4:
                    row_index = nrows_tiles - i + 1               
                    col_index = ncols_tiles - j + 1
                    if not row_index % 2 == 1:  # odd                       
                        col_index = j                   
            elif sel_type == 4:
                if sel_order == 1:
                    row_index = j
                    col_index = i
                    if not col_index % 2 != 1:  # pair                        
                        row_index = nrows_tiles - j + 1                   
                elif sel_order == 2:
                    row_index = j ####
                    col_index = ncols_tiles - i + 1
                    if not col_index % 2 == 1:  # odd                        
                        row_index = nrows_tiles - j + 1 
                elif sel_order == 3:
                    row_index = nrows_tiles - j + 1                
                    col_index = i 
                    if not col_index % 2 != 1:  # pair                       
                        row_index = j
                elif sel_order == 4:
                    row_index = nrows_tiles - j + 1               
                    col_index = ncols_tiles - i + 1
                    if not col_index % 2 == 1:  # odd                       
                        row_index = j 
            
            referenceGrid[row_index, col_index] = count

    return referenceGrid, tiling_name