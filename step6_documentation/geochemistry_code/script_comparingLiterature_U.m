clear 
clc
%Dependencies
scriptsFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts';
scriptsFolder1 = fullfile(scriptsFolder, "WMI/update_14-Jan-25/");
scriptsFolder2 = fullfile(scriptsFolder1, 'step2_grids');
scriptsFolder3 = fullfile(scriptsFolder1, 'step3_planning');
scriptsFolder4 = fullfile(scriptsFolder1, 'step3b_semi-automatic');
scriptsFolder5 = fullfile(scriptsFolder1, 'step6_documentation');
scriptsFolder6 = fullfile(scriptsFolder5, 'tblvertcat');
scriptsFolder7 = fullfile(scriptsFolder5, 'geochemistry_code');
scriptsFolder8 = fullfile(scriptsFolder7, 'functions_plots/');

addpath(scriptsFolder);
addpath(scriptsFolder1) 
addpath(scriptsFolder2) 
addpath(scriptsFolder3) 
addpath(scriptsFolder4) 
addpath(scriptsFolder5) 
addpath(scriptsFolder6) 
addpath(scriptsFolder7) 
addpath(scriptsFolder8) 

file1 = "E:\Feb-March_2024_zircon imaging\00_Paper 4_Forward image registration\puck 1 and 2\5-Jun-25_population 2 update\input_UPb_adapted_Fig.9_v3.xlsx";
DB_sorted = readtable(file1, 'VariableNamingRule','preserve');

temp_DB = DB_sorted.Database;
available_DB = unique(temp_DB);
n_bins = length(available_DB);
% str_temp = strsplit(sprintf('Database %02.f,', 1:n_bins), ','); 
% db_populations = str_temp(1:end-1);
db_populations = {
    'CA24MR-1 (238 Ma)', 'CA24MR-1 (246 Ma)', ...
    'Chisholm (241.7 Ma)', 'Cross (244.9 Ma)', 'Cross (247.1 Ma)'};

interrogation_columns = {
    'U_ppm', '232Th-238U'...
    }; 

% formal_name = interrogation_columns;
formal_name = {
    'U', 'Th/U'
    };

%Geochemical interrogation
number_bins = 8;

n_interrogation = length(interrogation_columns);
population_stats = cell(n_bins, n_interrogation);
population_kde = cell(n_bins, n_interrogation);
for ii = 1:n_bins  %1:n_bins     

    idx = (temp_DB == ii);
    DB_sorted2 = DB_sorted(idx, :);
    
    for p = 1:n_interrogation

        temp_variable = interrogation_columns{p};
        temp_array = DB_sorted2{:, temp_variable};
        %Note: no need for capping if removing inclusion-bearing spots

        %Histograms
        [N_counts, ~] = histcounts(temp_array, number_bins); %automatic
        [N, edges] = histcounts(temp_array, number_bins, 'Normalization','pdf');        
        sum_population = sum(N_counts);
        info_histogram = [[0, N]; edges];

        %KDE
        [f1, xf1] = kde(temp_array);        
        
        population_stats{ii, p} = {sum_population, info_histogram};
        population_kde{ii, p} = {f1, xf1};
    end

end

plot_population_histograms(db_populations, population_stats, population_kde, formal_name)
plot_population_KDEs(interrogation_columns, db_populations, population_stats, population_kde, formal_name)