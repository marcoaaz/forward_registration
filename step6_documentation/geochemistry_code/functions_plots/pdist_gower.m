
function [gowerDist, T_proc] = pdist_gower(T, compCols, numCols, catCols)

% 3. Pre-processing: CLR Transformation for Compositional Columns
% We extract just the compositional part, transform, and put it back
compData = T{:, compCols};
gMeans = exp(mean(log(compData), 2));
clrData = log(compData ./ gMeans);

% Create a processed table to preserve metadata
T_proc = T;
T_proc{:, compCols} = clrData;

% 4. Calculate Gower Dissimilarity
[n, p] = size(T_proc);
gowerDist = zeros(n*(n-1)/2, 1);

% Pre-calculate ranges for numerical/compositional columns only
ranges = max(T_proc{:, [compCols, numCols]}) - min(T_proc{:, [compCols, numCols]});
numVarNames = [compCols, numCols];

k = 1;
for i = 1:n
    for j = i+1:n
        perVarDiff = zeros(1, p);
        
        for v = 1:p
            colName = T_proc.Properties.VariableNames{v};
            
            if ismember(colName, catCols)
                % Categorical Logic: 1 if different, 0 if same
                perVarDiff(v) = double(T_proc{i,v} ~= T_proc{j,v});
            else
                % Numerical/Compositional Logic: Range-normalized Manhattan
                valI = T_proc{i,v};
                valJ = T_proc{j,v};
                
                % Find the pre-calculated range for this specific column
                colIdxInRange = find(strcmp(numVarNames, colName));
                colRange = ranges(colIdxInRange);
                
                if colRange > 0
                    perVarDiff(v) = abs(valI - valJ) / colRange;
                else
                    perVarDiff(v) = 0;
                end
            end
        end
        gowerDist(k) = mean(perVarDiff);
        k = k+1;
    end
end

gowerDist = gowerDist';

end