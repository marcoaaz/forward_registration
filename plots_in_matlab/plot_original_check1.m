function plot_original_check1(img_ref_fg2, coord_labelled2, n_std)
%without class and grid

% n_std = 5; %5
Idouble = im2double(img_ref_fg2);
avg = mean2(Idouble);
sigma = std2(Idouble);
a = max(0, avg-n_std*sigma);
b = min(1, avg+n_std*sigma);
img2 = imadjust(img_ref_fg2, [a a a; b b b],[]); %[0.2 0.2 0.2; .8 .8 .8],[]

close all

hFig = figure;
hFig.WindowState = 'maximized'; 

imshow(img2) %img_ref_fg2
hold on
%inverse
plot(coord_labelled2(:, 2), coord_labelled2(:, 3), 'Color', 'red', ...
    'LineStyle','none', 'Marker','.', 'MarkerSize', 20)
text(coord_labelled2(:, 2), coord_labelled2(:, 3), num2str(coord_labelled2(:, 1)), ...
    "FontSize", 15, "Color", 'white');
hold off

end