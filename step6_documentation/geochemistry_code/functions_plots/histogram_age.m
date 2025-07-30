function histogram_age(AND_all5, n_observations)

var1 = "age 207Pb/206Pb";
var2 = "age 207Pb/235U";
var3 = "age 206Pb/238U";

x1 = AND_all5.(var1);
x2 = AND_all5.(var2);
x3 = AND_all5.(var3);

n_notNegatives = size(AND_all5, 1);
text0 = sprintf('Grains in the database = %.0f', n_observations);
text1 = sprintf('Grains without negative columns = %.0f', n_notNegatives);


n_bins = 80;
x_min = 0;
x_max = 5000;
edges = linspace(x_min, x_max, n_bins);

hFig = figure;
hFig.Position = [200, 200, 1500, 500];

subplot(1, 3, 1)
histogram(x2, 'BinEdges', edges)
grid on
xlim([x_min, x_max])
set(gca, 'YScale', 'log')
title(var2)

subplot(1, 3, 2)
histogram(x3, 'BinEdges', edges)
grid on
xlim([x_min, x_max])
set(gca, 'YScale', 'log')
title(var3)

subplot(1, 3, 3)
histogram(x1, 'BinEdges', edges)
grid on
xlim([x_min, x_max])
title(var1)
sgtitle({text0; text1})


end