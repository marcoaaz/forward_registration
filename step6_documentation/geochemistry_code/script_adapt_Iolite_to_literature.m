
%Script to get Iolite export (CARF) ready for Isoplot-R webpage and
%geochemical comparison (Figure 10).

%Created: 7-Jun-25, M.A.

%Option 1: Google search > SE(1/x) standard error
% delta method or by using the formula SE(1/X) = (SE(X) / X^2)

%Option 2: SE(1/x) = |x| * SE(x) / x^2

%User input 

folder1 = "E:\Feb-March_2024_zircon imaging\00_Paper 4_Forward image registration\puck 1 and 2\merge_grid_test\project_9-Jun_granites\age_isoplot_age_isoplot_1\Population_01"; %very new
% folder1 = "E:\Feb-March_2024_zircon imaging\00_Paper 4_Forward image registration\puck 1 and 2\merge_grid_test\project_5-Jun_granites\age_isoplot_age_isoplot_1\Population_01"; %new
% folder1 = "E:\Feb-March_2024_zircon imaging\00_Paper 4_Forward image registration\puck 1 and 2\merge_grid_test\project_26-May_granite\age_isoplot_age_isoplot_1\Population_01"; %old

file1 = fullfile(folder1, "input_UPb.csv"); %old
file2 = fullfile(folder1, "population_data.xlsx");

%% Script 

outputFile1 = strrep(file1, '.csv', '_adapted.csv');

%Grid data
table2 = readtable(file2, VariableNamingRule="preserve");

%Data for Isoplot-R website
table1 = readtable(file1, VariableNamingRule="preserve");

Pb206U238 = table1.Pb206U238;
U238Pb206 = 1./Pb206U238;

sePb206U238 = table1.sePb206U238; %2SE abs
sePb206U238_1 = sePb206U238/2; %1SE abs

seU238Pb206 = sePb206U238_1./(Pb206U238.^2); %1SE abs
seU238Pb206_1 = 100*(seU238Pb206./U238Pb206); %1SE %

Pb207Pb206 = table1.Pb207Pb206;
sePb207Pb206 = table1.sePb207Pb206; %2SE abs
sePb207Pb206_1 = sePb207Pb206/2; %1SE abs
sePb207Pb206_2 = 100*(sePb207Pb206_1./Pb207Pb206); %1SE %

isoplot_table = table(U238Pb206, seU238Pb206_1, sePb207Pb206_2); %Pb207Pb206, 

%Append
table3 = [table1, table2, isoplot_table];

table4 = table3(:, {'Label', 'U238_ppm_mean', 'Th_U_ratio', 'Final Pb206-U238 age_mean', 'U238Pb206', 'seU238Pb206_1', 'Pb207Pb206', 'sePb207Pb206_2', 'Var1'});
%input_UPb_adapted_Fig.9_v2.xlsx
%Grain	U_ppm	232Th-238U	206Pb-238U_age	U238Pb206	errU238Pb206	Pb207Pb206	errPb207Pb206

writetable(table4, outputFile1);