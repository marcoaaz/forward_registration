function [DB_merged2, BB_merged1] = merge_two_grids(DB_1, DB_2, BB_1, BB_2)


%% Merging grain databases

issue_col = {'Image'}; %add issue variables

colnames = DB_1.Properties.VariableNames;
idx = ~ismember(colnames, issue_col);
DB_a3 = DB_1(:, idx);

colnames = DB_2.Properties.VariableNames;
idx = ~ismember(colnames, issue_col);
DB_b3 = DB_2(:, idx);

DB_merged = outerjoin(DB_a3, DB_b3,'MergeKeys', true);

%medicine (cell columns cannot be joined)
sel_cols = [{'Database', 'Label'}, issue_col];
ex1 = DB_1(:, sel_cols);
ex2 = DB_2(:, sel_cols);
ex = sortrows(vertcat(ex1, ex2), {'Database', 'Label'}, {'ascend', 'ascend'});

DB_merged1 = [DB_merged, ex(:, issue_col)];

%delete useless variables
not_to_include1 = {'knn_'};
not_to_include2 = {'Group'};
colnames = DB_merged1.Properties.VariableNames;
idx1 = contains(colnames, not_to_include1);
idx2 = ismember(colnames, not_to_include2);
idx = ~(idx1 | idx2);
DB_merged2 = DB_merged1(:, idx);

%% Merging Bounding boxes

issue_col = {'tform', 'corners_t1'};

colnames = BB_1.Properties.VariableNames;
idx = ~ismember(colnames, issue_col);
test1_b3 = BB_1(:, idx);

colnames = BB_2.Properties.VariableNames;
idx = ~ismember(colnames, issue_col);
test2_b3 = BB_2(:, idx);

BB_merged = outerjoin(test1_b3, test2_b3, 'MergeKeys', true);

%medicine (cell columns cannot be joined)
sel_cols = [{'Database', 'Class', 'Grid', 'Label'}, issue_col];
ex1 = BB_1(:, sel_cols);
ex2 = BB_2(:, sel_cols);
ex = sortrows(vertcat(ex1, ex2), ...
    {'Database', 'Class', 'Grid', 'Label'}, {'ascend', 'ascend', 'ascend', 'ascend'});

BB_merged1 = [BB_merged, ex(:, issue_col)];

%delete useless variables


end