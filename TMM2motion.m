function [] = TMM2motion(filename)
%TMM2motion takes .exp files with grf data and transforms the coordinates
%to be read by OpenSim. creates a .mot file
%   the file must contain forceplate forces, moments, and center of
%   pressure
if iscell(filename)
    filename = filename{1};
    motfilename = [filename(1:end-4) '.mot'];
else
    motfilename = [filename(1:end-4) '.mot'];
end
disp(motfilename);
fid = fopen(filename);

tab = sprintf('\t');
units = 'm';

%parse each line, .exp files exhibit complicated delimeters, cannot use
%higher level importing functions like importdata() or textscan()
line1 = fgetl(fid);%contains user name
line2 = fgetl(fid);%contains evaluation date (the day the data was collected, not exported)
line3 = fgetl(fid);%contains filename and timestamp
line4 = fgetl(fid);%sontains measurement rate
line5 = fgetl(fid);%contains length of data capture in seconds
line6 = fgetl(fid);%info about smoothing parameters
line7 = fgetl(fid);%info about bad data
line8 = fgetl(fid);%blank
line9 = fgetl(fid);%column headers
fclose(fid);

line3tabs = findstr(line3,tab);
line4tabs = findstr(line4,tab);

colnum = 19;%time and then 9 columns per force plate

samplerate = line4(1:line4tabs(1));
samplerate = num2str(round(str2double(samplerate)));%make sure the sample rate is a rounded integer??

stuff = importdata(filename,'\t',9);
data = stuff.data;
data2 = [data(:,64)*-1 data(:,65)*-1 data(:,66)*-1 data(:,58) data(:,59) data(:,67) data(:,60)*-1 data(:,61)*-1 data(:,62)*-1 data(:,56) data(:,57) data(:,63) data(:,68) data(:,69) data(:,70)*-1 data(:,71) data(:,72) data(:,73)];

rot = [0 -1 0;0 0 1;-1 0 0];%transform matrix (rotation matrix)

for z = 1:3:21-3
    for zz = 1:length(data2);
    
    temp1 = [data2(zz,z);data2(zz,z+1);data2(zz,z+2)];
    
    temp2 = rot*temp1;%transform the data
    
    data2(zz,z) = temp2(1);
    data2(zz,z+1) = temp2(2);
    data2(zz,z+2) = temp2(3);
    
    end
end

%make sure that GRF are positive, acting against gravity...
% data2(:,7) = data2(:,7)*-1;
% data2(:,8) = data2(:,8)*-1;
% data2(:,10) = data2(:,10)*-1;
% data2(:,11) = data2(:,11)*-1;
% data2(:,1) = data2(:,1)*-1;

frames = data(:,1);
time = frames./str2double(samplerate);

% m = [data(:,1)./str2double(samplerate) data(:,80:end)];%the marker data
% m = [data(:,1)./str2double(samplerate) data(:,50)*-1 data(:,51)*-1 data(:,52)*-1 data(:,53)*-1 data(:,54)*-1 data(:,55)*-1 data(:,56) data(:,57)*-1 data(:,58)*-1 data(:,59) data(:,60) data(:,61) data(:,62)*-1 data(:,63)*-1 data(:,64) data(:,65)*-1 data(:,66)*-1 data(:,67)];
m = [data(:,1)./str2double(samplerate) data2];

%define header lines
% newline1 = sprintf(['name' tab motfilename(1:end-4) 'mot']);
newline1 = sprintf([motfilename(1:end-4) 'mot']);
newline11 = sprintf(['version=1']);
% newline2 = sprintf(['datacolumns' tab num2str(colnum)]);
newline2 = sprintf(['nRows=' num2str(length(m))]);
% newline3 = sprintf(['datarows' tab num2str(length(m))]);
newline3 = sprintf(['nColumns=' num2str(colnum)]);
% newline4 = sprintf(['range' tab num2str(m(1,1)) tab num2str(m(end,1))]);
newline4 = sprintf(['inDegrees=yes']);
newline5 = sprintf(['endheader']);
% newline6 = sprintf(['time' tab 'LFx' tab 'LFy' tab 'LFz' tab 'LCx' tab 'LCy' tab 'LCz' tab 'LMx' tab 'LMy' tab 'LMz' tab 'RFx' tab 'RFy' tab 'RFz' tab 'RCx' tab 'RCy' tab 'RCz' tab 'RMx' tab 'RMy' tab 'RMz']);
newline6 = sprintf(['time' tab 'ground_force_vx' tab 'ground_force_vy' tab 'ground_force_vz' tab 'ground_force_px' tab 'ground_force_py' tab 'ground_force_pz' tab '1_ground_force_vx' tab '1_ground_force_vy' tab '1_ground_force_vz' tab '1_ground_force_px' tab '1_ground_force_py' tab '1_ground_force_pz' tab 'ground_torque_x' tab 'ground_torque_y' tab 'ground_torque_z' tab '1_ground_torque_x' tab '1_ground_torque_y' tab '1_ground_torque_z']); 
% keyboard

dlmwrite(motfilename,newline1,'delimiter','');
dlmwrite(motfilename,newline11,'delimiter','','-append');
dlmwrite(motfilename,newline2,'delimiter','','-append');
dlmwrite(motfilename,newline3,'delimiter','','-append');
dlmwrite(motfilename,newline4,'delimiter','','-append');
dlmwrite(motfilename,newline5,'delimiter','','-append');
dlmwrite(motfilename,newline6,'delimiter','','-append');
dlmwrite(motfilename,m,'delimiter',tab,'-append');%write the data




end