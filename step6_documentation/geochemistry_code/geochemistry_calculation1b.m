function [table_calculations] = geochemistry_calculation1b(input_table, age_table)
%Following Charlotte Allen tables
%Note: the current version plugs in isoplot ages for convenience.

idx_fail = false([size(input_table, 1), 1]); %please, do not delete
n_rows = size(input_table, 1);
% all_columns = input_table.Properties.VariableNames;

%% Evaluate discordance: 

%Ratios (names after Iolite template)
array1 = input_table.('Final Pb207-U235_mean'); %'abs 207Pb/235U'
array2 = input_table.("Final Pb207-U235_2SE(prop)"); %"abs 207Pb/235U_2SE"
array3 = input_table.('Final Pb206-U238_mean'); %'abs 206Pb/238U'
array4 = input_table.('Final Pb206-U238_2SE(prop)'); %"abs 206Pb/238U_2SE"
array5 = input_table.("Final Pb206-U238 age_2SE(prop)");
array6 = input_table.("Final Pb207-U235 age_2SE(prop)");

%Calculation parameters
val = 0.00049; %lower age limit (very young 206/238)
val_1 = 0.000155125; %denominator for 206Pb/238U
val_2 = 0.00098485; %denominator for 207Pb/235U
uncertainty = 15; %15; allowed percentage of 2SE for concordia intercept

%Action 1

%Imprecise?
idx1 = (array1 == 0); %=0
idx2 = (abs(array2./array1) > 2); 
idx3 = ~(idx1 | idx2);
criteria1 = zeros([n_rows, 1]);
criteria1(idx2) = -1; %imprecise
criteria1(idx3) = 1;

idx3b = (array3 == 0); %=0
idx4 = (abs(array4./array3) > 2);
idx5 = ~(idx3b | idx4);
criteria2 = zeros([n_rows, 1]);
criteria2(idx4) = -1; %imprecise
criteria2(idx5) = 1;

idx6 = (array3 < val); %may cause issue with idx_use
idx7 = ~(idx_fail | idx6);
veryYoung = zeros([n_rows, 1]);
veryYoung(idx_fail) = -10; %due to mineral inclusions
veryYoung(idx6) = -3; %too young
veryYoung(idx7) = array3(idx7);

% Action 2

input_temp = array3(~idx_fail); %206Pb/238U ratio
output_temp = exp( (log(input_temp + 1)./val_1).*val_2 ) - 1; %calc. 207Pb/235U ratio

concord_calc207_235 = NaN([n_rows, 1]);
concord_calc207_235(~idx_fail) = output_temp; 

idx_N = (concord_calc207_235 < array1); %normally discordant
idx_R = ~idx_N; %reversely discordant

idx_works1 = idx7 & idx_N;
idx_works2 = idx7 & idx_R;
idx_works = idx_works1 | idx_works2;

concord_calc_3Ma = strings([n_rows, 1]);
concord_calc_3Ma(~idx7) = ""; %too young
concord_calc_3Ma(idx_works1) = 'Normal';
concord_calc_3Ma(idx_works2) = 'Reverse';

% Action 3

% uncertainty_pct = (100 - uncertainty)/100;
uncertainty_pct = (100 + uncertainty)/100;

input_temp = array3(idx_works);
output_temp = log(input_temp + 1)./val_1; %formula of geometric locus

age206_238_fromRatio = NaN([n_rows, 1]);
age206_238_fromRatio(idx_works) = output_temp;

input_temp = array1(idx_works);
output_temp = log(input_temp + 1)./val_2; %formula

age207_235_fromRatio = NaN([n_rows, 1]);
age207_235_fromRatio(idx_works) = output_temp;

%Verifying intersection (note: this section needs improvement)
a = age207_235_fromRatio - uncertainty_pct*array6; %normally discordant
b = age206_238_fromRatio + uncertainty_pct*array5;
c = age207_235_fromRatio + uncertainty_pct*array6; %reversely discordant
d = age206_238_fromRatio - uncertainty_pct*array5;

idx_concordant1 = (b > a) & idx_works1;
idx_concordant2 = (c > d) & idx_works2;
idx_concordant = idx_concordant1 | idx_concordant2;

%useful data
idx_use = zeros([n_rows, 1]);
idx_use(idx6) = 1; %were too young
idx_use(idx_concordant) = 1;

%% Alpha particle production
%Note: 238U/235U is 137.818

U_ppm = input_table.("U238_ppm_mean");
Th_ppm = input_table.("Th232_ppm_mean");

Th_atomicWeight = 232.038;
U_atomicWeight = 238.03;
avogadro_number = 6.0221*10^23;
denominator = 137.818; %Charlotte; 
lambda1 = 0.000155125; %years^-1
lambda2 = 0.00098485;
lambda3 = 0.000049475;
%decay constants 𝜆 238U, 𝜆 235U and 𝜆 232Th

idx_condition3 = (idx_use == 1) & idx6;
idx_condition4 = (idx_use == 1) & ~idx6;

alpha_age = NaN([n_rows, 1]);
alpha_age(idx_condition3) = 3;
alpha_age(idx_condition4) = age206_238_fromRatio(idx_condition4);

value = 1/denominator; 
factor1 = (10^-6)*(1/U_atomicWeight)*(1 - value)*avogadro_number;
factor2 = (10^-6)*(1/U_atomicWeight)*(value)*avogadro_number;
factor3 = (10^-6)*(1/Th_atomicWeight)*avogadro_number;

%number of particles
U238_atomsG = U_ppm*factor1; %atoms/mg
U235_atomsG = U_ppm*factor2;
Th232_atomsG = Th_ppm*factor3;

%Alpha dose (Holland and Gottfried, 1955)
He4_G_fromPb = ( ...
    8*U238_atomsG.*(exp(lambda1*alpha_age) - 1) + ... %mistake? 1*
    7*U235_atomsG.*(exp(lambda2*alpha_age) - 1) + ...
    6*Th232_atomsG.*(exp(lambda3*alpha_age) - 1) );

idx_condition5 = (He4_G_fromPb > 1*10^18);
idx_metamict = zeros([n_rows, 1]);
idx_metamict(idx_condition5) = 1; %ruined

%% Geochemical calculations

Zr_ppm = input_table.("Zr91_ppm_mean");
Hf_ppm = input_table.("Hf177_ppm_mean");
Yb_ppm = input_table.("Yb172_ppm_mean");
Ce_ppm = input_table.("Ce140_ppm_mean");
Ti_ppm = input_table.("Ti49_ppm_mean");
Lu_ppm = input_table.("Lu175_ppm_mean");
Dy_ppm = input_table.("Dy163_ppm_mean");

%Magmatic differentiation indicator
%Claiborne et al. (2006) Tracking magmatic processes through Zr-Hf ratios
ratio_Zr_Hf = Zr_ppm./Hf_ppm;

%Continental/Oceanic zircon
Hf_ppm_modified = Hf_ppm;
Hf_ppm_modified(~idx_use) = NaN;

ratio_U_Yb = U_ppm./Yb_ppm;
ratio_U_Yb_modified = ratio_U_Yb;
ratio_U_Yb_modified(~idx_use) = 0;

idx_condition6 = (ratio_U_Yb_modified > 0.023*exp(0.0001552*Hf_ppm_modified)); %formula

tectonic_indicator = strings([n_rows, 1]);
tectonic_indicator(~idx_use) = "";
tectonic_indicator(idx_condition6) = "continental";
tectonic_indicator(idx_use & ~idx_condition6) = "oceanic";

%Uranium condition
U_ppm_less100 = NaN([n_rows, 1]);
idx_condition7 = idx_use & (U_ppm < 100);
U_ppm_less100(idx_condition7) = U_ppm(idx_condition7);

%% Hydrobarometer 
%Bob Loucks et al., 2020

age_isoplot = age_table.("age_isoplot");

var_pressure = 175; %MPa, assumptions
a_TiO = .54; %activity TiO2
a_SiO = 1; %SiO2 

Ti_temperature_K = ( (-4800 + (0.4748*(var_pressure - 1000)) ) ./ (log10(Ti_ppm) - 5.711 - log10(a_TiO) + log10(a_SiO)) );

log_fO = ( (-587474 + (1584.427.* Ti_temperature_K) - ...
    (203.3164*Ti_temperature_K.*log(Ti_temperature_K)) + ...
    (0.09271*(Ti_temperature_K.^2)))./(8.314511*Ti_temperature_K*log(10)) ); %log fO2@FMQ 

%age-corrected initial U (uses U238 ppm) and Th
initial_U = U_ppm.*( exp(age_isoplot*lambda1) + 0.0072*exp(age_isoplot*lambda2) ); 
initial_Th = Th_ppm.*exp(age_isoplot*lambda3);

ratio_iTh_iU = initial_Th./initial_U; 

%(Ce/U)*(U/Ti)^0.5
ratio1 = Ce_ppm./initial_U; 
ratio2 = initial_U./Ti_ppm;
ratio_CeUTi = ratio1.*(ratio2.^0.5); 

deltaFMQ = (3.998*log10(ratio_CeUTi)) + 2.284;

log_fO_sample = deltaFMQ + log_fO; %log fO2(sample)

%old snippet
% ratio_CeUTi = NaN([n_rows, 1]);
% idx_condition8 = (Ti_ppm < 0.01); %no Ti (Note: check for mistake. Ti~35ppm)
% idx_condition9 = idx_use & ~idx_condition8;
% ratio_CeUTi(idx_condition9) = ratio3(idx_condition9); 

% Fayalite-Magnetite-Quartz mineral redox buffer
idx_condition10 = idx_use & (ratio_CeUTi > 0.3) & (Ti_ppm > 0.01); %from Fig.9 (Loucks et al., 2020)
above_FMQ = zeros([n_rows, 1]);
above_FMQ(idx_condition10) = 1;

% Garnet signal
ratio_UTh = U_ppm./Th_ppm;
ratio_YbLu = Yb_ppm./Lu_ppm;
Lu_ppm_less10 = double(Lu_ppm < 10);
ratio_LuDy = Lu_ppm./Dy_ppm;
ratio_LuDy_normalised = double(10*ratio_LuDy < 3.5); %not normalised (header mistake?)
garnet_signal = Lu_ppm_less10 + ratio_LuDy_normalised;

ratio_UTh(~idx_use) = NaN;
ratio_YbLu(~idx_use) = NaN;
Lu_ppm_less10(~idx_use) = NaN;
ratio_LuDy_normalised(~idx_use) = NaN;
garnet_signal(~idx_use) = NaN;

%% Generate table

table_calculations = table(...
    criteria1, criteria2, veryYoung, ...
    concord_calc207_235, concord_calc_3Ma, ...
    age206_238_fromRatio, age207_235_fromRatio, idx_use, ...
    alpha_age, U238_atomsG, U235_atomsG, Th232_atomsG, He4_G_fromPb, idx_metamict, ...
    ratio_Zr_Hf, Hf_ppm_modified, ratio_U_Yb_modified, ...
    tectonic_indicator, U_ppm_less100, ...
    Ti_temperature_K, initial_U, ratio_iTh_iU, ratio_CeUTi, deltaFMQ, log_fO, log_fO_sample, above_FMQ, ...
    ratio_UTh, ratio_YbLu, Lu_ppm_less10, ratio_LuDy_normalised, garnet_signal ...
    );

end
