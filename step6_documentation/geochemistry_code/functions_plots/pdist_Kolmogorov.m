function [dissimilarities] = pdist_Kolmogorov(numeric_a)
%columns = samples
%rows = variables (histogram values)

%Note 1: kstest2() returns 'ks2stat' with low precision. I do not know why.

%Note 2: it seems to work well for distributions with 100-800 variables, my
%zircon analysis have 16 variables (columns) and might be not suitable for
%this function


%Download
%https://www.ucl.ac.uk/~ucfbpve/mudisc/#matlab

%Citation:
%2015_Vermeesch and Garzanti_Making geological sense of big data in sedimentary provenance analysis
%https://www.sciencedirect.com/science/article/pii/S0009254115002387

n = size(numeric_a, 1);
numeric = numeric_a';
    
    
data = cell(1,n);
for i=1:n,
    col = numeric(:,i);
    data{i} = col(isfinite(col));
end

MIN = inf; MAX = -inf;
% calculate the dissimilarity matrix:
diss = zeros(n);
for i=1:n,
    if (min(data{i})<MIN) 
        MIN = min(data{i}); 
    end
    if max(data{i})>MAX
        MAX = max(data{i}); 
    end
    for j=1:n,
        [h,p,s] = kstest2(data{i},data{j});
        diss(i,j) = s;
    end
end

dissimilarities = squareform(diss); %vector

end