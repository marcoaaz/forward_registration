function [DB_sorted_in5] = retrieving_fiftyone_clusters(DB_sorted_in, filepath2, matching_column, ...
    cluster_column, clusters_chosen, cluster_age_intervals)

age_col = 'Final Pb206-U238 age_mean'; %edit

table_clusters = readtable(filepath2, 'VariableNamingRule','preserve');
idx1 = ismember(table_clusters.hdb1, clusters_chosen);
table_cluster2 = table_clusters(idx1, :);

cluster_column_str = strcat(cluster_column, '_double'); %clusters
str3 = str2double(table_cluster2{:, cluster_column});

[~, basename, ext] = fileparts(table_cluster2{:, matching_column}); %paths
str4 = strcat(basename, ext);

%Relevant clusters table
table_cluster3 = table(str4, str3, ...
    'VariableNames', {strcat(matching_column, '_basename'), cluster_column_str});

%Finding filename matches
str5 = DB_sorted_in.path_basename;
[~, Locb] = ismember(str4, str5);
Locb(Locb == 0) = [];
DB_sorted_in2 = DB_sorted_in(Locb, :);

%Appending
DB_sorted_in3 = [table_cluster3, DB_sorted_in2]; 

%Filtering ages
cluster_array = DB_sorted_in3{:, cluster_column_str};
age_array = DB_sorted_in3{:, age_col};

clusters_chosen_1 = str2double(clusters_chosen);
n_analyses = length(clusters_chosen_1);

idx_master = false(size(DB_sorted_in3, 1), 1);
for i = 1:n_analyses

    interval_temp = cluster_age_intervals(i, :);
    cluster_temp = clusters_chosen_1(i);
    
    idx1 = (cluster_array == cluster_temp);
    idx2 = (interval_temp(1) < age_array) & (interval_temp(2) > age_array);
    idx = idx1 & idx2;

    idx_master = idx_master | idx;    
end
DB_sorted_in4 = DB_sorted_in3(idx_master, :);

%Medicine: 2, 3, 4, 5 belong to puck 2
Database_modified = DB_sorted_in4.Database;
[a, ~] = ismember(Database_modified, [2, 3, 4, 5]);
Database_modified(a) = 2; %puck 2 = 2
DB_sorted_in5 = [array2table(Database_modified), DB_sorted_in4];


end