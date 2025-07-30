function [table_calculations, table_AND] = geochemistry_calculation1c(input_table)
%Detecting the analysis of mineral inclusions. Following Charlotte Allen guiding

%Filters used at QUT CARF:

% element_list = {'Hf177_ppm_mean', 'La139_ppm_mean', 'Ti49_ppm_mean', 'P31_ppm_mean'};
%element_operators = {'<', '>', '>', '>'}; %inclusions
% element_checks = [5000, 2, 65, 1500]; %Charlotte email 0 (Excel table)
% element_checks = [5000, 3, 85, 3000]; %Charlotte email 1

% element_list = {'Hf177_ppm_mean', 'Al27_ppm_mean', 'La139_ppm_mean', 'Ti49_ppm_mean', 'P31_ppm_mean'};
% element_operators = {'<', '>', '>', '>', '>'}; %inclusions
% element_checks = [5000, 15, 2, 20, 3000]; %Charlotte email 2
% element_checks = [5000, 150, 3, 100, 3000]; %Charlotte email 2 (flexible version)
% element_checks = [5000, 20, 1, 120, 2000]; %Charlotte email 3 (24-Jul-25)

%Filter values used by the broader literature:

%La139: 0.3-1 ppm, Carrasco= 1.5 %due to the low distribution coefficient in zircon
%Ti49: 40-80 ppm, Carrasco= 60 
%P31: Carrasco= 2000

%% Apply and permute filters

%Criteria for having inclusions and common lead ('stop and look' spots)

element_list = {'Hf177_ppm_mean', 'Al27_ppm_mean', ...
    'La139_ppm_mean', 'Ti49_ppm_mean', 'P31_ppm_mean', 'Pb206_ppm_mean'};
element_operators = {'<', '>', '>', '>', '>', '>'}; %relational operator
element_checks = [5000, 150, 3, 100, 3000, 20000]; 

close all
[idx_fail_array] = plot_threshold_histograms(input_table, element_list, element_checks, element_operators);

idx_inclusions = any(idx_fail_array, 2); %OR
total_OR = sum(idx_inclusions);
cell_row = {'Total_OR', total_OR};

element_list_b = strrep(element_list, '_ppm_mean', '_fail');
idx_fail_table = array2table(idx_fail_array, 'VariableNames', element_list_b);

%Find out combinations of idx_fail (inclusions)
n_arrays = size(idx_fail_array, 2);
table_AND = [];
for k = 1:n_arrays

    %Permutations
    choices_array = nchoosek(1:4, k);

    n_choices = size(choices_array, 1);
    for m = 1:n_choices
        choices_temp = choices_array(m, :);
        str_temp = sprintf('%s, ', element_list{choices_temp});
        str_temp = string(str_temp(1:end-2));

        AND_temp = all(idx_fail_array(:, choices_temp), 2);

        table_temp = table(str_temp, sum(AND_temp), ...
            'variableNames', {'Filter combinations', 'Total-AND'});
        table_AND = [table_AND; table_temp];
    end    
end
table_AND = [table_AND; cell_row];

% r = 100*corr(idx_fail_array);
% isupper = logical(triu(ones(size(r)),1));
% r(isupper) = NaN;
% 
% figure
% h = heatmap(r, 'MissingDataColor','w');
% h.XDisplayLabels = element_list;
% h.YDisplayLabels = element_list; 
% h.Interpreter = "none";

table_calculations = addvars(idx_fail_table, idx_inclusions);

end