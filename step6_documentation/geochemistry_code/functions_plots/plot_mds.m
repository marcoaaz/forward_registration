
function plot_mds(dissimilarity, names, cond1, cond2, cond3)
%Download
%https://www.ucl.ac.uk/~ucfbpve/mudisc/#matlab

%Citation:
%2015_Vermeesch and Garzanti_Making geological sense of big data in sedimentary provenance analysis
%https://www.sciencedirect.com/science/article/pii/S0009254115002387

diss = squareform(dissimilarity); %matrix

% plot MDS map
if cond1
    [XY,stress,disparities] = mdscale(diss,2,'Criterion','metricstress');
else
    [XY,stress,disparities] = mdscale(diss,2,'Criterion','stress');
end
stress 

X = XY(:,1); 
Y = XY(:,2);
if cond2
    Xrange = max(X)-min(X);
    Yrange = max(Y)-min(Y);
    buffer = 0.1;
    minX = min(X)-Xrange*buffer;
    maxX = max(X)+Xrange*buffer;
    minY = min(Y)-Yrange*buffer;
    maxY = max(Y)+Yrange*buffer;
    
    hFig3 = figure('Name','MDS map','NumberTitle','off');
    hFig3.Position = [80, 80, 900, 900];
    
    
    set(gca,'FontUnits','normalized');
    fsize = get(gca,'FontSize')/4;
    set(gca,'FontUnits','points');   

    plot(X,Y,'.k'); 
    hold on; 
    box on; 
    grid on

    text(X+fsize,Y,names,'Color','r');

    if cond3 % plot nearest neighbour lines

        [foo,i] = sort(diss,1,'ascend');
        first = i(2,:);
        second = i(3,:);
        plot([X X(first)]',[Y Y(first)]','-k', ...
            [X X(second)]',[Y Y(second)]',':k');
    end
    hold off
    
    xlim([minX,maxX]); ylim([minY,maxY]); 
    axis equal;
    
    ax = gca;
    ax.Color = [1, 0, 1, 0.02]; 
    title('MDS nearest and second-nearest neighbours')
    xlabel('MDS-1')
    ylabel('MDS-2')

    fontsize(14, 'Points')
end

