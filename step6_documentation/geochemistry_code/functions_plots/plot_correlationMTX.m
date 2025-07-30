function [DB2, matrix_input, varNames] = plot_correlationMTX(DB1, threshold, file2)

n_vars = size(DB1, 2);

%Sorting columns by variable type
varTypes2 = varfun(@class, DB1, 'OutputFormat', 'cell');
double_idx = strcmp(varTypes2, 'double');
from_val = n_vars - sum(double_idx) + 1;
from_val
DB2 = [DB1(:, ~double_idx), DB1(:, double_idx)];

writetable(DB2, file2, "WriteMode","overwritesheet")
file2

%% Pearson correlation coefficient and masking

colnames2 = DB2.Properties.VariableNames;
range1 = [from_val:n_vars];
varNames = colnames2(range1);
matrix_input = DB2{:, range1}; %for correlation mtx plot
dim = size(matrix_input);
n_variables = dim(2);

correl_mtx = corrcoef(matrix_input);
temp_max = max(correl_mtx, [], 'all');
temp_min = min(correl_mtx, [], 'all');

idx = ones(size(correl_mtx)); %mask
low_triangular = tril(idx, 0);

mask1 = ~low_triangular;
mask2 = (abs(correl_mtx) < threshold);
mask = mask1 | mask2;

correl_mtx(mask) = 0;
correl_mtx2 = uint8(rescale(correl_mtx, 0, 255));

%% Plot

cmap_input = cool(256); %parula
RGB = ind2rgb(correl_mtx2, cmap_input);
RGB(repmat(mask, 1, 1, 3)) = 0;

x= 1:n_variables;
y = ones(1, n_variables);

close all

hFig = figure;

imshow(RGB, 'InitialMagnification', 1000)
colormap(cmap_input)

ax = gca;
ax.PositionConstraint = "outerposition";

%ticks
angle_val = 0;
axis on
xticks([1:dim(2)])
yticks([1:dim(2)])
xticklabels(varNames);
yticklabels(varNames);
xtickangle(angle_val + 90)
ytickangle(angle_val)
set(gca,"TickLabelInterpreter",'none')
% set(gca,'xaxisLocation','top')

%colours
cbh = colorbar;
cbh.Ticks = rescale(linspace(temp_min, temp_max, 10), 0, 1) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(linspace(temp_min, temp_max, 10));
ylabel(cbh,'Pearson correlation','FontSize', 10,'Rotation', 270)

title('Pearson correlation coefficient (heatmap)')

%Visualisation adjustments
factor = 1.9;
pos = hFig.Position;
hFig.Position = [100, 100, pos(3)*.75, pos(4)].*[1, 1, factor, factor];

end