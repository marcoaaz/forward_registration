function [order_column, cummulative_dist] = minimumDistPath(X, initial_idx)

n_spots2 = size(X, 1);
Pos_idx = initial_idx;

cummulative_dist = 0;
order_column = zeros(n_spots2, 1);
order_column(Pos_idx) = 1;
X_current = X;
Z_current = squareform(pdist(X)); %Euclidean distance

for m = 2:n_spots2    
    
    %find next point
    search_row = Z_current(Pos_idx, :);
    temp1 = unique(search_row(:));
    temp2 = temp1(2); %second smallest
    idx_closest = (search_row == temp2)';    
    next_xy = X_current(idx_closest, :);        

    %cummulative distance
    cummulative_dist = cummulative_dist + temp2;
        
    %order in original array
    Pos_idx_0 = ( (X(:, 1) == next_xy(1)) & (X(:, 2) == next_xy(2)) );
    order_column(Pos_idx_0) = m;
    
    %update search array    
    X_current(Pos_idx, :) = [];
    Z_current(Pos_idx, :) = [];
    Z_current(:, Pos_idx') = [];
    Pos_idx = idx_closest(~Pos_idx, :); %next spot
    
end
sprintf('%.f', cummulative_dist) %OR-Tools reduces distance 16%

end