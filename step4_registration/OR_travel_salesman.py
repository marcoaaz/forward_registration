# -*- coding: utf-8 -*-

"""
Simple Travelling Salesperson Problem (TSP) on a circuit board.

Documentation: 
https://developers.google.com/optimization/install
https://developers.google.com/optimization/routing/
https://developers.google.com/optimization/routing/tsp

Citation:


#Created: Tue Mar 26 12:00:14 2024, Marco Acevedo Zamora

#Environment: Python 3.12.7 (base)

"""

from ortools.constraint_solver import routing_enums_pb2
from ortools.constraint_solver import pywrapcp
from matplotlib import pyplot as plt
import math
import numpy as np
from pathlib import Path
import os.path

csvfile = r"D:\Justin Freeman collab\25-mar-2025_Apreo2\CA24MR-1_Redo_stitched and unstitched tiles\montages_final\segmentation\chromium\registration_intermediateFiles\option2_TPS.csv"
path = Path(csvfile)
destDir = path.parent.absolute()

data_mtx1 = np.loadtxt(open(csvfile, "rb"), delimiter=",", skiprows=0)
data_mtx2 = data_mtx1.round(0)
data_mtx3 = tuple(map(tuple, data_mtx2.astype(int)))

shape_val = data_mtx2.shape
n_spots = shape_val[0]

#%%
data_array = data_mtx3

def create_data_model(data_array):
    """Stores the data for the problem."""
    data = {}
    # Locations in block units
    data["locations"] = data_array
    data["num_vehicles"] = 1
    data["depot"] = 0
    return data


def compute_euclidean_distance_matrix(locations):
    """Creates callback to return distance between points."""
    distances = {}
    for from_counter, from_node in enumerate(locations):
        distances[from_counter] = {}
        for to_counter, to_node in enumerate(locations):
            if from_counter == to_counter:
                distances[from_counter][to_counter] = 0
            else:
                # Euclidean distance
                distances[from_counter][to_counter] = int(
                    math.hypot((from_node[0] - to_node[0]), (from_node[1] - to_node[1]))
                )
    return distances


def print_solution(manager, routing, solution):
    """Prints solution on console."""
    
    print(f"Objective: {solution.ObjectiveValue()}")
    index = routing.Start(0)
    plan_output = "Route:\n"
    route_distance = 0
    nodeVector = np.zeros((n_spots, 1), dtype=int)
    k = 0
    while not routing.IsEnd(index):      
        
        nodeNumber1 = manager.IndexToNode(index)
        plan_output += f" {nodeNumber1} ->"
        nodeVector[k] = nodeNumber1
        previous_index = index
        index = solution.Value(routing.NextVar(index))
        
        route_distance += routing.GetArcCostForVehicle(previous_index, index, 0)
        k = k + 1    
    
    nodeNumber2 = manager.IndexToNode(index) #returns to 0    
    plan_output += f" {nodeNumber2}\n"    
    
    print(plan_output)    
    plan_output += f"Objective: {route_distance}m\n"
    
    return nodeVector

#%% Some tooling to ease drawing
height = 7

def plot_location(location, axes, color, location_number):
    axes.scatter(
        location[0],      
        location[1],      
        s=20, #1000      
        facecolors='white',      
        edgecolors=color,      
        linewidths=2)    
  
    axes.scatter(      
        location[0],      
        location[1],      
        s=10, #400      
        marker=f'${location_number}$',      
        edgecolors=color,      
        facecolors=color)

# A diagram of the city is shown below, with the company location marked in black and the locations to visit in blue.
def plot_locations(locations):
    fig, axes = plt.subplots(figsize=(1.7 * height, height))

    axes.grid(False) #True
  
    axes.set_xticks(list(set([x for (x, y) in locations])))  
    axes.set_xticklabels([])  
    axes.set_yticks(list(set([y for (x, y) in locations])))  
    axes.set_yticklabels([])  
    axes.set_axisbelow(True)
  
    for (i, location) in enumerate(locations):    
        color = 'blue' if i else 'black'
        plot_location(location, axes, color, i)


    
# a diagram of the solution using a Google colorscheme
def plot_solution(locations, manager, routing, solution, loc, marker_size):
    
    destFile = os.path.join(destDir, 'optimalPath.png')         
    height = 8
    
    fig, axes = plt.subplots(figsize=(1.7 * height, height))
        
    axes.grid(False) #True
    axes.set_xticks(list(set([x for (x, y) in locations])))
    axes.set_xticklabels([])
    axes.set_yticks(list(set([y for (x, y) in locations])))
    axes.set_yticklabels([])
    axes.set_axisbelow(True)
    axes.axis('equal')
    max_route_distance = 0
    google_colors = [
      r'#4285F4', r'#EA4335', r'#FBBC05', r'#34A853', r'#101010', r'#FFFFFF'  
    ]
  
    for vehicle_id in range(manager.GetNumberOfVehicles()):
          
      
        previous_index = routing.Start(vehicle_id)
      
        while not routing.IsEnd(previous_index):
          
            index = solution.Value(routing.NextVar(previous_index))          
            start_node = manager.IndexToNode(previous_index)          
            end_node = manager.IndexToNode(index)          
            start = locations[start_node]          
            end = locations[end_node]          
            delta_x = end[0] - start[0]          
            delta_y = end[1] - start[1]          
            delta_length = math.sqrt(delta_x**2 + delta_y**2)          
            unit_delta_x = delta_x / delta_length          
            unit_delta_y = delta_y / delta_length
          
            axes.arrow(
                start[0] + (marker_size / 2) * unit_delta_x,              
                start[1] + (marker_size / 2) * unit_delta_y,              
                (delta_length - marker_size) * unit_delta_x,              
                (delta_length - marker_size) * unit_delta_y,              
                head_width=2,              
                head_length=2,              
                facecolor=google_colors[vehicle_id],              
                edgecolor=google_colors[vehicle_id],              
                length_includes_head=True,              
                width=5)
            previous_index = index
            node_color = 'black' if routing.IsEnd(
                previous_index) else google_colors[vehicle_id]          
          
            plot_location(end, axes, node_color, end_node)
            
    fig.savefig(destFile)

#%
def main():
    """Entry point of the program."""
    # Instantiate the data problem.
    data = create_data_model(data_array)

    manager = pywrapcp.RoutingIndexManager(
        len(data["locations"]), data["num_vehicles"], data["depot"]
    )

    routing = pywrapcp.RoutingModel(manager)

    distance_matrix = compute_euclidean_distance_matrix(data["locations"])

    def distance_callback(from_index, to_index):
        """Returns the distance between the two nodes."""
        # Convert from routing variable Index to distance matrix NodeIndex.
        from_node = manager.IndexToNode(from_index)
        to_node = manager.IndexToNode(to_index)
        return distance_matrix[from_node][to_node]

    transit_callback_index = routing.RegisterTransitCallback(distance_callback)

    # Define cost of each arc.
    routing.SetArcCostEvaluatorOfAllVehicles(transit_callback_index)   
    
    # Option 3: Allow solver to escape local minimum     
    search_parameters = pywrapcp.DefaultRoutingSearchParameters()
    search_parameters.local_search_metaheuristic = (
        routing_enums_pb2.LocalSearchMetaheuristic.GUIDED_LOCAL_SEARCH) #SIMULATED_ANNEALING
    search_parameters.time_limit.seconds = 60
    search_parameters.log_search = False #True    

    # Solve the problem.
    solution = routing.SolveWithParameters(search_parameters)

    # Print solution on console.
    if solution:
        nodeVector_output = print_solution(manager, routing, solution)
    else:
        print('No solution found !')    
    
    #plot_solution(data_array, manager, routing, solution, data_array,  20)
    #plt.show()     
    
    destFile = os.path.join(destDir, 'nodeVector.csv')         
    np.savetxt(destFile, nodeVector_output, delimiter=",")       
    

if __name__ == "__main__":
    main()