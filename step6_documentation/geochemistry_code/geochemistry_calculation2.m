function [table_calculations] = geochemistry_calculation2(sample_data2, file_db1)
%Following Pizarro et al. 2020

%Filtering out columns
colnames = sample_data2.Properties.VariableNames;
not_to_include1 = {'_CPS_', 'rho', '_2SE', 'PbTotal'};
idx1 = contains(colnames, not_to_include1);
sample_data4 = sample_data2(:, ~idx1);

%% Filtering out data

[name_full, name_element] = search_elements(sample_data4);

%% Process 1: Spyder diagram (REE)
%redundant with geochemistry_calculation4() 'Carrasco table'

%Normalisation database: McDonough & Sun 1995 (edit for choosing other Chondrite)
table1 = readtable(file_db1, 'Delimiter', 'tab', 'NumHeaderLines', 4);
idx1 = strcmp(table1.Reservoir, 'CI Chondrites');
idx2 = contains(table1.Notes, 'Based on measurements');
idx = idx1 & idx2;
table_db1 = table1(idx, :);

%Spyder diagram
x_labels_ree = {
    'La', 'Ce', 'Pr', 'Nd', 'Sm', 'Eu', ...
    'Gd', 'Tb', 'Dy', 'Ho', 'Er', 'Yb', 'Lu'};

[~, Locb] = ismember(x_labels_ree, name_element);
missing_idx = (Locb == 0);
wantedVars1 = name_element(Locb(~missing_idx)); %some are missing

%subsetting database
available_elements = table_db1.Element;
[~, Locb2] = ismember(wantedVars1, available_elements);
temp = table_db1(Locb2, :);
chondrite_values_REE = (temp.Value)/1000; %ppb conversion to ppm

%Normalising
requested_cols = name_full(Locb(~missing_idx));
y = sample_data4{:, requested_cols}./chondrite_values_REE'; %normalising

table_spyder = array2table(y);
table_spyder.Properties.VariableNames = strcat(wantedVars1, '_spyder');

%% Process 2: Ti-in-zircon temperature

Ti_val = sample_data4.Ti49_ppm_mean;
Hf_val = sample_data4.Hf177_ppm_mean;

%medicine
Ti_val(Ti_val > 3000) = 3000;
Ti_val(Ti_val < 0) = 0.01; %cannot be 0
Hf_val(Ti_val < 0) = 0;

a_SiO2 = 1; %values after Pizarro et al. (2020)
a_TiO2 = 0.7;

%Formula by Ferry and Watson (2007)
uncertainty1_val = 0; %0.072
uncertainty2_val = 0; %86

T_C_pos = -273.15 + ((4800 + uncertainty2_val)./...
    ((5.711 + uncertainty1_val) - log10(Ti_val) - log10(a_SiO2) + log10(a_TiO2)) );

T_C_neg = -273.15 + ((4800 - uncertainty2_val)./...
    ((5.711 - uncertainty1_val) - log10(Ti_val) - log10(a_SiO2) + log10(a_TiO2)) );

table_TiTemp = array2table([Ti_val, Hf_val, T_C_pos]);
table_TiTemp.Properties.VariableNames = {'Ti', 'Hf', 'Ti-temperature'};

%% Process 3: Europium and Cerium anomalies

wantedVars2 = {'Eu', 'Gd', 'Sm', 'Ce', 'Nd', 'Y'};

%subsetting database
available_elements = table_db1.Element;
[~, Locb2] = ismember(wantedVars2, available_elements);
temp = table_db1(Locb2, :);
chondrite_values = (temp.Value)/1000; %ppb

Eu_fix = sample_data4.Eu153_ppm_mean;
Gd_fix = sample_data4.Gd157_ppm_mean;
Sm_fix = sample_data4.Sm147_ppm_mean;
Ce_fix = sample_data4.Ce140_ppm_mean;
Nd_fix = sample_data4.Nd146_ppm_mean;
Y_fix = sample_data4.Y89_ppm_mean;

Eu_fix(Eu_fix < 0) = 0;
Gd_fix(Gd_fix < 0) = 0;
Sm_fix(Sm_fix < 0) = 0;
Ce_fix(Ce_fix < 0) = 0;
Nd_fix(Nd_fix < 0) = 0;
Y_fix(Y_fix < 0) = 0;

%normalising
Eu_val = Eu_fix/chondrite_values(1);
Gd_val = Gd_fix/chondrite_values(2);
Sm_val = Sm_fix/chondrite_values(3);
Ce_val = Ce_fix/chondrite_values(4);
Nd_val = Nd_fix/chondrite_values(5);
Y_val = Y_fix/chondrite_values(6); %in ppm (therefore x1000)

%ratios
Eu_ratio = real(Eu_val./((Sm_val.*Gd_val).^0.5)); %Eu anomaly (Eu/Eu*)
Ce_ratio = 1000*real((Ce_val./Nd_val)./Y_val); %Ce anomaly/Y

table_anomalies = array2table([Eu_ratio, Ce_ratio]);
table_anomalies.Properties.VariableNames = {'Eu_ratio', 'Ce_ratio'};

%% Process 4: Element ratios
% Th/U and Dy/Yb ratios (Pizarro et al., 2020, Fig.8)
% Ce/Nd and Gd/Yb (Carrasco et al., 2024)

val_min = 0.01;

Th_fix = sample_data4.Th232_ppm_mean;
U_fix = sample_data4.U238_ppm_mean;
Dy_fix = sample_data4.Dy163_ppm_mean;
Yb_fix = sample_data4.Yb172_ppm_mean;
Nd_fix = sample_data4.Nd146_ppm_mean;

Th_fix(Th_fix < 0) = 0;
Dy_fix(Dy_fix < 0) = 0;
U_fix(U_fix < 0) = val_min;
Yb_fix(Yb_fix < 0) = val_min;
Nd_fix(Nd_fix < 0) = val_min;

Th_U_ratio = real(Th_fix./U_fix);
Dy_Yb_ratio = real(Dy_fix./Yb_fix);
Ce_Nd_ratio = real(Ce_fix./Nd_fix);
Gd_Yb_ratio = real(Gd_fix./Yb_fix);

table_ratios = array2table([Th_U_ratio, Dy_Yb_ratio, Ce_Nd_ratio, Gd_Yb_ratio]);
table_ratios.Properties.VariableNames = {'Th_U_ratio', 'Dy_Yb_ratio', 'Ce_Nd_ratio', 'Gd_Yb_ratio'};

%% Append

table_calculations = [
    table_spyder, table_TiTemp, table_anomalies, table_ratios
    ];

end