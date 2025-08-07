function [table_calculations] = geochemistry_calculation1a(input_table)
%Following Charlotte Allen guiding

idx_use = true([size(input_table, 1), 1]); %please, do not delete
n_rows = size(input_table, 1);
% all_columns = input_table.Properties.VariableNames;

%%
[name_full, name_element] = search_elements(input_table);

%Atomic weight mini-database
tags_db = {
    'Si', 'U', 'Th', 'Al', 'P', ...
    'Ti', 'Zr',	'Hf', 'Y', 'La', ...
    'Ce', 'Nd',	'Sm', 'Eu',	'Gd', ...
    'Tb', 'Dy',	'Ho', 'Er',	'Tm', ...
    'Yb', 'Lu',	'Nb', 'Ta', ...
    'Pr'
    };

atomicWeights_db = [
    28.09, 238.00, 232.00, 26.98, 30.97, ...
    47.87, 91.22, 178.50, 88.91, 138.90, ...
    140.10, 144.20,	150.40,	152.00,	157.30, ...
    158.90, 162.50, 164.90,	167.30,	168.90, ...	
    173.00, 175.00,	92.90, 180.90, ...
    140.9
    ];

%% Molarity and xenotime substitution

%Note: sum should also include Sc in participating_input
requested_list = {
    'P', 'Y', 'La', 'Ce', 'Pr', ...	
    'Nd', 'Sm', 'Eu', 'Gd', 'Dy', ...	
    'Er', 'Yb', 'Lu', ...
    };

list_n = length(requested_list);
tags2 = strcat(requested_list, '_molarity');

%Find columns in input table
[~, Locb] = ismember(requested_list, name_element);
missing_idx = (Locb == 0);
tags = name_full(Locb(~missing_idx));

%Find columns in database
[~, Locb] = ismember(requested_list, tags_db);
missing_idx = (Locb == 0);
atomicWeights = atomicWeights_db(Locb(~missing_idx));

%Calculate
temp_mtx = input_table{:, tags};
temp_mtx2 = temp_mtx./atomicWeights; %atoms or molarity

P_molarity = temp_mtx2(:, 1);
sum_REE = sum(temp_mtx2(:, 2:end), 2);
ratio_P_REE = P_molarity./sum_REE; %xenotime substitution slope proxy (x/y)

%Limiting output (may be an issue if idx_use is mostly =0)
sum_REE(~idx_use) = NaN; %this limits output (if idx_use is mostly =0)
ratio_P_REE(~idx_use) = NaN;

participating_input = [2, 3, 5, 6, 7, 8];
not_participating_input = setdiff(1:list_n, participating_input);
temp_mtx2(~idx_use, not_participating_input) = NaN;

%Zeroing
idx_negative = (temp_mtx < 0);
idx_negative2 = idx_negative(:, participating_input);
temp_1 = temp_mtx2(:, participating_input);
temp_1(idx_negative2) = NaN;
temp_mtx2(:, participating_input) = temp_1;

table_molarity0 = array2table(temp_mtx2, "VariableNames", tags2);
table_molarity = addvars(table_molarity0, sum_REE, ratio_P_REE);

%% Atoms per formula unit (apfu) and xenotime substitution slope
%Note: Dedicated to zircon. Modify for other mineral.

%Laboratory experimental data with 1 pt calibration to NIST-610 std (QUT CARF)
val_1 = 152200; %Si of 15.22 wt% based on stoichiometric zircon with 1 wt % Hf
val_2 = val_1/atomicWeights_db(1); %assumes that Si apfu = 1

[idx_Si, ~] = ismember(tags_db, 'Si');
tags_db2 = tags_db(~idx_Si);

Si_col = repmat(val_1, n_rows, 1);
Si_colname = {'Si_apfu'};

%Find mini-database columns
[~, Locb] = ismember(tags_db2, name_element);
missing_idx = (Locb == 0);
tags_mdb = name_full(Locb(~missing_idx));
tags_mdb2 = name_element(Locb(~missing_idx));
tags_mdb3 = strcat(tags_mdb2, '_apfu');

%Calculations 1
numeric_data1 = [Si_col, input_table{:, tags_mdb}]; %n_obs x n_elements
numeric_data2 = atomicWeights_db.*val_2; %1 x n_elements
numeric_data3 = numeric_data1./numeric_data2;

new_cols = [Si_colname; tags_mdb3];
table_apfu = array2table(numeric_data3, 'VariableNames', new_cols);
n_cols_apfu = size(table_apfu, 2);

%Calculations 2
Si_apfu = table_apfu{:, 'Si_apfu'};
Zr_apfu = table_apfu{:, 'Zr_apfu'};
Hf_apfu = table_apfu{:, 'Hf_apfu'};
P_apfu = table_apfu{:, 'P_apfu'};

total_apfu = sum(table_apfu{:, :}, 2);
total_REE_Al_apfu = sum(table_apfu{:, [4, 9:n_cols_apfu]}, 2);
ratio_Si_ZrHf_apfu = Si_apfu./(Zr_apfu + Hf_apfu); 
ratio_Si_all_apfu = Si_apfu./total_apfu;
ratio_totalREE_P_apfu = total_REE_Al_apfu./P_apfu; 

%Calculations 3 
%Yang et al., 2016. P-controlled TE distribution in zircon revealed by NanoSIMS

zircon_molarMass = 183.31; %gr/mol

%10^-6 mol/g
P_mol = (10^6)*P_apfu/zircon_molarMass;
total_REE_Al_mol = (10^6)*total_REE_Al_apfu/zircon_molarMass;
ratio_totalREE_P_mol = total_REE_Al_mol./P_mol; %xenotime substitution slope (y/x)

table_apfu2 = addvars(table_apfu, total_apfu, ...
    ratio_Si_ZrHf_apfu, ratio_Si_all_apfu, ...
    total_REE_Al_apfu, ratio_totalREE_P_apfu, ...
    P_mol, total_REE_Al_mol, ratio_totalREE_P_mol);

%% Append

table_calculations = [table_molarity, table_apfu2];

end