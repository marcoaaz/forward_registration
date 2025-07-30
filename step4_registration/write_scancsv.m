function [fileDest2] = write_scancsv(filePath, value)

[workingDir, fileName, ~] = fileparts(filePath);

%The importable fields are (9 / 15 total): 
% description, position, laser output, rep rate, shot count, 
% dwell time, Z depth, iteration count, spot size

% User input
val_scanType = value.scanType;
val_description = value.description; %updates
val_selected = value.selected;
val_lockEdit = value.lockEdit;
val_vertexCount = value.vertexCount;
val_x = value.x; %updates
val_y = value.y; %updates
val_z = value.z; %updates

n_spots = length(val_description);

%ablation
val_dosage = value.dosage; val_dwellTime = value.dwellTime; val_lineSpacing = value.lineSpacing; 
val_laserOutput = value.laserOutput; val_laserFluence = value.laserFluence; val_lineScanMode = value.lineScanMode; val_passCount = value.passCount;
val_laserRepRate = value.laserRepRate; val_scanSpeed = value.scanSpeed; val_passEnabled = value.passEnabled; val_shotCount = value.shotCount; 
val_spotSpacing = value.spotSpacing; val_laserSpotSize = value.laserSpotSize; val_laserSpotRotation = value.laserSpotRotation; val_zDepth = value.zDepth;

%pre-ablation
val_dosage2 = value.dosage2; val_dwellTime2 = value.dwellTime2; val_lineSpacing2 = value.lineSpacing2; 
val_laserOutput2 = value.laserOutput2; val_laserFluence2 = value.laserFluence2; val_lineScanMode2 = value.lineScanMode2; val_passCount2 = value.passCount2;
val_laserRepRate2 = value.laserRepRate2; val_scanSpeed2 = value.scanSpeed2; val_passEnabled2 = value.passEnabled2; val_shotCount2 = value.shotCount2; 
val_spotSpacing2 = value.spotSpacing2; val_laserSpotSize2 = value.laserSpotSize2; val_laserSpotRotation2 = value.laserSpotRotation2; val_zDepth2 = value.zDepth2;

%Formatting for Chromium
scanType = char(val_scanType); 
selected = sprintf('%.f', val_selected); 
lockEdit = sprintf('%.f', val_lockEdit); 
vertexCount = sprintf('%.f', val_vertexCount);

dosage = sprintf('%.f', val_dosage); dwellTime = sprintf('%.2f', val_dwellTime); lineSpacing = sprintf('%.2f', val_lineSpacing);
laserOutput = sprintf('%.2f', val_laserOutput); laserFluence = sprintf('%.2f', val_laserFluence); lineScanMode = sprintf('%.f', val_lineScanMode); passCount = sprintf('%.f', val_passCount); 
laserRepRate = sprintf('%.2f', val_laserRepRate); scanSpeed = sprintf('%.2f', val_scanSpeed); passEnabled = sprintf('%.f', val_passEnabled); shotCount = sprintf('%.f', val_shotCount); 
spotSpacing = sprintf('%.2f', val_spotSpacing); laserSpotSize = [sprintf('%.f', val_laserSpotSize), char(181), 'm Circle']; laserSpotRotation = sprintf('%.2f', val_laserSpotRotation); zDepth = sprintf('%.2f', val_zDepth);

dosage2 = sprintf('%.f', val_dosage2); dwellTime2 = sprintf('%.2f', val_dwellTime2); lineSpacing2 = sprintf('%.2f', val_lineSpacing2);
laserOutput2 = sprintf('%.2f', val_laserOutput2); laserFluence2 = sprintf('%.2f', val_laserFluence2); lineScanMode2 = sprintf('%.f', val_lineScanMode2); passCount2 = sprintf('%.f', val_passCount2); 
laserRepRate2 = sprintf('%.2f', val_laserRepRate2); scanSpeed2 = sprintf('%.2f', val_scanSpeed2); passEnabled2 = sprintf('%.f', val_passEnabled2); shotCount2 = sprintf('%.f', val_shotCount2); 
spotSpacing2 = sprintf('%.2f', val_spotSpacing2); laserSpotSize2 = [sprintf('%.f', val_laserSpotSize2), char(181), 'm Circle']; laserSpotRotation2 = sprintf('%.2f', val_laserSpotRotation2); zDepth2 = sprintf('%.2f', val_zDepth2);

%% Saving

%Header
output_header = [char('Scan Type,Description,Selected,Lock Edit,Vertex Count,Vertex List,Preablation Settings,Ablation Settings,Data'), newline];

%Body
char_new = char;
for j = 1:n_spots
    description = ['"', char(val_description{j}), '"'] ; 
    x_char = sprintf('%.2f', val_x(j));
    y_char = sprintf('%.2f', val_y(j));
    z_char = sprintf('%.2f', val_z(j));

    char_update = [
        scanType, ',', description, ',', selected, ',', lockEdit, ',', vertexCount, ',"', ...
        x_char, ',', y_char, ',', z_char, ...        
        '","Dosage=', dosage, ';DwellTime=', dwellTime, ';LineSpacing=', lineSpacing, ...
        ';Laser.Output=', laserOutput, ';Laser.Fluence=', laserFluence, ';LineScanMode=', lineScanMode, ';PassCount=', passCount, ... %preablate
        ';Laser.RepRate=', laserRepRate, ';ScanSpeed=', scanSpeed,';PassEnabled=', passEnabled,';ShotCount=', shotCount, ...
        ';SpotSpacing=', spotSpacing, ';Laser.SpotSize=', laserSpotSize, ';Laser.SpotRotation=', laserSpotRotation, ';ZDepth=', zDepth, ...        
        '","Dosage=', dosage2, ';DwellTime=', dwellTime2, ';LineSpacing=', lineSpacing2, ... %ablate
        ';Laser.Output=', laserOutput2, ';Laser.Fluence=', laserFluence2, ';LineScanMode=', lineScanMode2, ';PassCount=', passCount2, ...
        ';Laser.RepRate=', laserRepRate2, ';ScanSpeed=', scanSpeed2,';PassEnabled=', passEnabled2,';ShotCount=', shotCount2, ...
        ';SpotSpacing=', spotSpacing2, ';Laser.SpotSize=', laserSpotSize2, ';Laser.SpotRotation=', laserSpotRotation2, ';ZDepth=', zDepth2, ...
        '",""', newline
        ];

    char_new = [char_new, char_update];
end

%Formatting
text_lines = {output_header;
               char_new;               
               };

%Saving
fileName2 = strcat(fileName, '_copycat.scancsv');
fileDest2 = fullfile(workingDir, fileName2);
  
fid = fopen(fileDest2, 'wt', 'n', "windows-1252"); %works in Cr software
% fid = fopen(fileDest2, 'wt'); %default MatLab    
% fid = fopen(fileDest2, 'wt', 'n', "US-ASCII"); %ANSI (notepad)  

for m = 1:numel(text_lines)
    
    fprintf(fid, '%s', text_lines{m});    
end
fclose(fid); 

end