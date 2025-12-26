%% Supplementary information Figure S5
% Import 'merge_grids_v9.m' output

%Documentation
%https://au.mathworks.com/matlabcentral/answers/458470-coloring-the-dots-in-biplot-chart
%https://au.mathworks.com/help/stats/mdscale.html

%User input
input_folder = 'E:\Feb-March_2024_zircon imaging\00_Paper 4_Forward image registration\puck 1 and 2\merge_grid_test\project_24-Dec-25\age_isoplot_age_isoplot_2';
file1 = "interrogation_metadata.mat";
file2 = "populations_data_interrogated.xlsx";
compCols = {
    'Hf177_ppm_mean', 'P31_ppm_mean', 'Y89_ppm_mean', ...
    'Yb172_ppm_mean', 'Ti49_ppm_mean', ...
    };
numCols = {
    'Convexity', 'MeanIntensity_V', 'ratio_Zr_Hf', ...
    'initial_U', 'ratio_iTh_iU', 'Dy_Yb_ratio', ...
    'ratio_totalREE_P_mol', 'Eu_ratio', 'Ce_Nd_ratio', ...
    'ratio_CeUTi', 'lambda_3', ...
    };
catCols = {};

%% Run script

load(fullfile(input_folder, file1));
populations_table = readtable(fullfile(input_folder, file2), 'VariableNamingRule','preserve');

formal_name = interrogation_metadata.formal_name;
interrogation_columns = interrogation_metadata.interrogation_columns;

%Delete redundant rows (Population 2)
labels0 = populations_table.age_bin;
criteria1 = interrogation_columns{2}; %MeanIntensity_V
var_names = formal_name; %for Latex

idx_keep = (labels0 == 5 | labels0 == 6);
table1 = populations_table(~idx_keep, :);
table2 = populations_table(idx_keep, :);
n_rows_keep = size(table2, 1);

remove_array = zeros(n_rows_keep, 1);
for i = 1:n_rows_keep
    temp_val = table2{i, criteria1};

    idx1 = (table1{:, criteria1} == temp_val);
    remove_array(i) = find(idx1);
end
table3 = table1(~ismember(1:size(table1, 1), remove_array), :);
table4 = [table3; table2];
table4 = sortrows(table4, 'age_isoplot', 'ascend');

%Process column data
table5 = table4(:, [interrogation_columns, 'age_bin']);
var_names0 = table5.Properties.VariableNames;

labels1 = table5.age_bin;


X = table5{:, 1:end-1};

%Removing NaN
nan_idx = isnan(X);
yes_idx = ~any(nan_idx, 2);
labels = labels1(yes_idx); %age bin
X = X(yes_idx, :);

%nonmetric MDS
table6 = table4(yes_idx, interrogation_columns); 
[dissimilarities, table7] = pdist_gower(table6, compCols, numCols, catCols); %mixed dataset%optional
X_scaled = zscore(table7{:, :}); %standardising

%Optional:
% dissimilarities = pdist(X_scaled, 'euclidean'); %compositional dataset
% [dissimilarities] = pdist_Kolmogorov(X_scaled); %distributional dataset

[Y, stress, disparities] = mdscale(dissimilarities, 2, 'criterion', 'stress'); %nonmetric
[dum, ord] = sortrows([disparities(:) dissimilarities(:)]);
distances = pdist(Y);
x_max = max(distances, [], "all");
stress

%PCA 
[coeff, score, latent] = pca(X_scaled);
% Xcentered = score*coeff';

close all

%Colour convention
cmap_1 = [
    1, 0, 0, 0.8;
    0.5, 0, 1, 0.8; %pop 2
    0, 1, 1, 0.8;
    0.5, 1, 0, 0.8;
    0.5, 0, 1, 0.8; %pop 2 age group 1
    0.5, 0, 1, 0.8; %pop 2 age group 2
    ];      

plot_pca_marco(coeff, score, var_names, labels, cmap_1)
plot_mds_marco(Y, labels, cmap_1)
plot_mds_dissimilarity(dissimilarities, distances, disparities, ord, x_max)

cond1 = false; %'metricstress'
cond2 = true; %plot
cond3 = true; %NN lines
plot_mds(dissimilarities, num2str(labels), cond1, cond2, cond3)