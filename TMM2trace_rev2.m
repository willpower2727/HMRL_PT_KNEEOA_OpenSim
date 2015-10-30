function [] = TMM2trace_rev2(filename)
%This file takes a .exp file exported from TMM and formats it for a trace
%file to be used in Opensim

%The file is loaded, the header is parsed from the data.
% a new header is created in the trace file format based on the information
% from the exp file. Then the data is also formatted. 

%*********************************************************************************************
%parse the header for required information

if iscell(filename)
    filename = filename{1}
else
end

fid = fopen(filename);

tab = sprintf('\t');
% carriage = sprintf(['\n']);
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

tracefilename = [filename(1:end-4) '.trc'];

samplerate = line4(1:line4tabs(1));
samplerate = num2str(round(str2double(samplerate)));%make sure the sample rate is a rounded integer??

%find how many markers there are...
% markers = findstr(line9,'Marker');
% markernum = length(markers)/3;%markers come in sets of three columns xyz
%hard coded for the kneeOA marker set. This could be more robust if TMM wasn't so terrible at exporting data...
markernum = 16;
%***********************************************************************************************************

%now go and get the actual data
file = importdata(filename,'\t',9);
data = file.data;

%transform data so that it is resolved in the OpenSim Coordinates

rot = [0 -1 0;0 0 1;-1 0 0];

for z = 2:3:2+3*18-3%this is the # of markers, 
    for zz = 1:length(data);
    
    temp1 = [data(zz,z);data(zz,z+1);data(zz,z+2)];
    
    temp2 = rot*temp1;%transform the data
    
    data(zz,z) = temp2(1);
    data(zz,z+1) = temp2(2);
    data(zz,z+2) = temp2(3);
    
    end
%     keyboard
end
    
%call each marker in the x y z direction

RASISx = data(:,35);
RASISy = data(:,36);
RASISz = data(:,37);
LASISx = data(:,32);
LASISy = data(:,33);
LASISz = data(:,34);
RPSISx = data(:,41);
RPSISy = data(:,42);
RPSISz = data(:,43);
LPSISx = data(:,38);
LPSISy = data(:,39);
LPSISz = data(:,40);
RTHIGHx = data(:,20);
RTHIGHy = data(:,21);
RTHIGHz = data(:,22);
RKNEEx = data(:,47);
RKNEEy = data(:,48);
RKNEEz = data(:,49);
RSHANKx = data(:,26);
RSHANKy = data(:,27);
RSHANKz = data(:,28);
RLANKx = data(:,53); 
RLANKy = data(:,54);
RLANKz = data(:,55);
RHEELx = data(:,2);
RHEELy = data(:,3);
RHEELz = data(:,4);
RTOEx = data(:,8);
RTOEy = data(:,9);
RTOEz = data(:,10);
LTHIGHx = data(:,23);
LTHIGHy = data(:,24);
LTHIGHz = data(:,25);
LKNEEx = data(:,44);
LKNEEy = data(:,45);
LKNEEz = data(:,46);
LSHANKx = data(:,29);
LSHANKy = data(:,30);
LSHANKz = data(:,31);
LLANKx = data(:,50);
LLANKy = data(:,51);
LLANKz = data(:,52);
LHEELx = data(:,11);
LHEELy = data(:,12);
LHEELz = data(:,13);
LTOEx = data(:,17);
LTOEy = data(:,18);
LTOEz = data(:,19);



frames = data(:,1);
time = frames./str2double(samplerate);

%make new header line 1, #PathFileType 4 (X/Y/Z) filename#
newline1 = sprintf(['PathFileType' tab '4' tab '(X/Y/Z)' tab tracefilename(1:end-4) 'trc']);
newline2 = sprintf(['DataRate' tab 'CameraRate' tab 'NumFrames' tab 'NumMarkers' tab 'Units' tab 'OrigDataRate' tab 'OrigDataStartFrame' tab 'OrigNumFrames']);
newline3 = sprintf([samplerate tab samplerate tab num2str(length(frames)) tab num2str(markernum) tab units tab samplerate tab '1' tab num2str(length(frames))]);
% newline4 = sprintf(['Frame#' tab 'Time' tab 'PS1' tab 'PS2' tab 'PS3' tab 'PS4' tab 'RT1' tab 'RT2' tab 'RT3' tab 'RT4' tab 'RS1' tab 'RS2' tab 'RS3' tab 'RS4' tab 'RHEEL' tab 'RANK' tab 'RTOE' tab 'LT1' tab 'LT2' tab 'LT3' tab 'LT4' tab 'LS1' tab 'LS2' tab 'LS3' tab 'LS4' tab 'LHEEL' tab 'LANK' tab 'LTOE']);
newline4 = sprintf(['Frame#' tab 'Time' tab 'RASIS' tab tab tab 'LASIS' tab tab tab 'RPSIS' tab tab tab 'LPSIS' tab tab tab 'RTHIGH' tab tab tab 'RKNEE' tab tab tab 'RSHANK' tab tab tab 'RLANK' tab tab tab 'RHEEL' tab tab tab 'RTOE' tab tab tab 'LTHIGH' tab tab tab 'LKNEE' tab tab tab 'LSHANK' tab tab tab 'LLANK' tab tab tab 'LHEEL' tab tab tab 'LTOE']);
newline5 = sprintf([tab tab 'X1' tab 'Y1' tab 'Z1' tab 'X2' tab 'Y2' tab 'Z2' tab 'X3' tab 'Y3' tab 'Z3' tab 'X4' tab 'Y4' tab 'Z4' tab 'X5' tab 'Y5' tab 'Z5' tab 'X6' tab 'Y6' tab 'Z6' tab 'X7' tab 'Y7' tab 'Z7' tab 'X8' tab 'Y8' tab 'Z8' tab 'X9' tab 'Y9' tab 'Z9' tab 'X10' tab 'Y10' tab 'Z10' tab 'X11' tab 'Y11' tab 'Z11' tab 'X12' tab 'Y12' tab 'Z12' tab 'X13' tab 'Y13' tab 'Z13' tab 'X14' tab 'Y14' tab 'Z14' tab 'X15' tab 'Y15' tab 'Z15' tab 'X16' tab 'Y16' tab 'Z16']);
% newline5 = sprintf([tab tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y' tab 'Z' tab 'X' tab 'Y']);

newline6 = sprintf([' ']);

% m = [data(:,1) data(:,1)./str2double(samplerate) data(:,2:79)];%the marker data
% m = [data(:,1)+1 data(:,1)./str2double(samplerate) data(:,2:55)];

m = [data(:,1)+1 data(:,1)./str2double(samplerate) RASISx RASISy RASISz LASISx LASISy LASISz RPSISx RPSISy RPSISz LPSISx LPSISy LPSISz RTHIGHx RTHIGHy RTHIGHz RKNEEx RKNEEy RKNEEz RSHANKx RSHANKy RSHANKz RLANKx RLANKy RLANKz RHEELx RHEELy RHEELz RTOEx RTOEy RTOEz LTHIGHx LTHIGHy LTHIGHz LKNEEx LKNEEy LKNEEz LSHANKx LSHANKy LSHANKz LLANKx LLANKy LLANKz LHEELx LHEELy LHEELz LTOEx LTOEy LTOEz];

% m = [data(:,1)+1 data(:,1)./str2double(samplerate) data(:,2)*-1 data(:,3)*-1 data(:,4) data(:,5)*-1 data(:,6)*-1 data(:,7) data(:,8)*-1 data(:,9)*-1 data(:,10) data(:,11)*-1 data(:,12)*-1 data(:,13) data(:,14)*-1 data(:,15)*-1 data(:,16) data(:,17)*-1 data(:,18)*-1 data(:,19) data(:,20)*-1 data(:,21)*-1 data(:,22) data(:,23)*-1 data(:,24)*-1 data(:,25) data(:,26)*-1 data(:,27)*-1 data(:,28) data(:,29)*-1 data(:,30)*-1 data(:,31) data(:,32)*-1 data(:,33)*-1 data(:,34) data(:,35)*-1 data(:,36)*-1 data(:,37) data(:,38)*-1 data(:,39)*-1 data(:,40) data(:,41)*-1 data(:,42)*-1 data(:,43) data(:,44)*-1 data(:,45)*-1 data(:,46) data(:,47)*-1 data(:,48)*-1 data(:,49)];
% keyboard
%write to file!!
dlmwrite(tracefilename,newline1,'delimiter','');
dlmwrite(tracefilename,newline2,'delimiter','','-append');
dlmwrite(tracefilename,newline3,'delimiter','','-append');
dlmwrite(tracefilename,newline4,'delimiter','','-append');
dlmwrite(tracefilename,newline5,'delimiter','','-append');
dlmwrite(tracefilename,newline6,'delimiter','','-append');
dlmwrite(tracefilename,m,'delimiter',tab,'-append');


end

