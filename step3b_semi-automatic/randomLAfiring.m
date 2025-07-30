%% Firing (option 2): using probability sampling

function [spotCoordinates] = randomLAfiring(laserParameters, scoreSurface, n_candidates) 

%'randomLAfiring.m'

%Function that generates n_candidate simulations sampling the cummulative
%probability curve ('scoreSurface') without replacement by updating next
%spot available area ('curveMask'). A 'spotCollection' is generated
%containing the candidates, n_spots realised, and curve values
%(probability, row, col). Only a few realisations are kept (with n_spots)
%and a best candidate list is made for the candidates with a probability
%sum equal to the mode of all candidates. Finally, only one realisation is
%chosen (random find) and the spot coordinates (row, col) are returned.

%Created: Marco Acevedo, 29-Sep-2020
%Updated: Marco Acevedo, 18-Sep-2024

%Input:

%n_candidates: number of candidate solutions
%scoreSurface: surface that represent where to shoot the next spot

%%
n_spots = laserParameters.n_spots;  %number of LA spots
spotDist = laserParameters.spotDist;
spotDist_out = laserParameters.spotDist_out;

% s = RandStream('mlfg6331_64'); %??
spotCollection = zeros(n_candidates*n_spots, 5);
k = 0;
totals = zeros(1, n_candidates); 
for i = 1:n_candidates
    curveMask = scoreSurface ~= 0; %initializing
    for j = 1:n_spots
        if sum(curveMask, 'all') ~= 0
            k = k + 1; %counter
            population = scoreSurface(curveMask);
            [row, col] = find(curveMask);      
            curveValues = [population, row, col];
            
            %sampling (no replacement on 'score curve' image)
            probabilities = curveValues(:, 1)/sum(curveValues(:, 1)); 
            %sample 1 pixel (not binned)
            [sample_value, sample_index] = datasample(population, 1, ...
                'Weights', probabilities); 
            
            %Next spot available area
            white_pixel = zeros(size(curveMask, 1), size(curveMask, 2));
            white_pixel(curveValues(sample_index, 2), curveValues(sample_index, 3)) = 1;
            D_pixel = bwdist(white_pixel);
            D1 = D_pixel.*curveMask; 
            curveMask = (D1 > spotDist) & (D1 <= spotDist_out); 
            
            %Saving value [candidate, spot, score, row, col]
            spotCollection(k, :) = [i, j, sample_value, curveValues(sample_index, 2:3)];
        else
            continue;            
        end
    end    
end

%Filtering out cases with less shots
k = zeros(1, n_candidates);
spotCollection1 = spotCollection; %copy to modify
for i = 1:n_candidates
    index = spotCollection(:, 1) == i;
    totals(i) = sum(spotCollection1(index, 3)); %sum sample_value
    if sum(index) < n_spots
        k(i) = 1;
        spotCollection(index, :) = []; 
    end
end

totals(k == 1) = [];        
best_candidates = find(totals == mode(totals)); %alternative: max()
candidates_list = unique(spotCollection(:, 1));
candidates_list(candidates_list == 0) = []; %delete zero rows
index = spotCollection(:, 1) == candidates_list(best_candidates(1)); %first
temp = spotCollection(index, :);

spotCoordinates = temp(:, [5, 4]); %[col, row]

end