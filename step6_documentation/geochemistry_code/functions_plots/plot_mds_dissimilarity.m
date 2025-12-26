function plot_mds_dissimilarity(dissimilarities, distances, disparities, ord, x_max)

hFig3 = figure;
hFig3.Position = [90, 90, 900, 900];

plot(dissimilarities, distances,'bo')
hold on
plot(dissimilarities(ord), disparities(ord),'r.-')
plot([0 x_max],[0 x_max],'k-')
hold off

xlabel('Dissimilarities')
ylabel('Distances/Disparities')
legend({'Distances' 'Disparities' '1:1 Line'},...
       'Location','NorthWest');

fontsize(14, 'points')

end