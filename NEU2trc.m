function [] = NEU2trc(filename)
%This function converts a neutral stance report from TMM into a static pose
%TRC file that OpenSim can use to scale a model
%Extracts data from the NEU file and transforms the coordinates:
%
%
%   Y ---> X
%   Z ---> Y
%   X ---> Z
% then writes the tab delimited TRC file
%**********************************************
% clear
% clc

% if iscell(filename)
%     filename = cell2str(filename);
% end
disp(filename)
fid = fopen(filename);

tab = sprintf('\t');
units = 'm';

line1 = fgetl(fid);%user name
line2 = fgetl(fid);%contains evaluation date (the day the data was collected, not exported)
line3 = fgetl(fid);%contains filename and timestamp

fclose(fid);%close low level reading after header info has been read

%finish defining additional header lines for static trc
writefilename = [filename(1:4) '_static.trc'];

s = importdata(filename,'\t',6);
data = s.data;
clear s;

%parse data with the transformation listed above...
RHEELx = data(2);
RHEELy = data(3);
RHEELz = data(1);
% RHEEL2x = data(5);%this was for an alternate marker set, not current use
% RHEEL2y = data(6);
% RHEEL2z = data(4);
RTOEx = data(8);
RTOEy = data(9);
RTOEz = data(7);
LHEELx = data(11);
LHEELy = data(12);
LHEELz = data(10);
% LHEEL2x = data(14);
% LHEEL2y = data(15);
% LHEEL2z = data(13);
LTOEx = data(17);
LTOEy = data(18);
LTOEz = data(16);
RTHIGHx = data(20);
RTHIGHy = data(21);
RTHIGHz = data(19);
LTHIGHx = data(23);
LTHIGHy = data(24);
LTHIGHz = data(22);
RSHANKx = data(26);
RSHANKy = data(27);
RSHANKz = data(25);
LSHANKx = data(29);
LSHANKy = data(30);
LSHANKz = data(28);
LASISx = data(32);
LASISy = data(33);
LASISz = data(31);
RASISx = data(35);
RASISy = data(36);
RASISz = data(34);
LPSISx = data(38);
LPSISy = data(39);
LPSISz = data(37);
RPSISx = data(41);
RPSISy = data(42);
RPSISz = data(40);
LKNEEx = data(44);
LKNEEy = data(45);
LKNEEz = data(43);
RKNEEx = data(47);
RKNEEy = data(48);
RKNEEz = data(46);
LLANKx = data(50);
LLANKy = data(51);
LLANKz = data(49);
RLANKx = data(53);
RLANKy = data(54);
RLANKz = data(52);

%***********************************
%Introduce some gaussian white noise to provide some more data points
%for scale.exe to use, one data point is too little information
noise = 0.0001*wgn(200,1,0.01);%adds white noise with amplitude scale of ~0.1 mm
%%
%add this noise to the data
RASISx = RASISx+noise;
noise = 0.0001*wgn(200,1,0.01);
RASISy = RASISy+noise;
noise = 0.0001*wgn(200,1,0.01);
RASISz = RASISz+noise;
noise = 0.0001*wgn(200,1,0.01);
LASISx = LASISx+noise;
noise = 0.0001*wgn(200,1,0.01);
LASISy = LASISy+noise;
noise = 0.0001*wgn(200,1,0.01);
LASISz = LASISz+noise;
noise = 0.0001*wgn(200,1,0.01);
RPSISx = RPSISx+noise;
noise = 0.0001*wgn(200,1,0.01);
RPSISy = RPSISy+noise;
noise = 0.0001*wgn(200,1,0.01);
RPSISz = RPSISz+noise;
noise = 0.0001*wgn(200,1,0.01);
LPSISx = LPSISx+noise;
noise = 0.0001*wgn(200,1,0.01);
LPSISy = LPSISy+noise;
noise = 0.0001*wgn(200,1,0.01);
LPSISz = LPSISz+noise;
noise = 0.0001*wgn(200,1,0.01);
RTHIGHx = RTHIGHx+noise;
noise = 0.0001*wgn(200,1,0.01);
RTHIGHy = RTHIGHy+noise;
noise = 0.0001*wgn(200,1,0.01);
RTHIGHz = RTHIGHz+noise;
noise = 0.0001*wgn(200,1,0.01);
RKNEEx = RKNEEx+noise;
noise = 0.0001*wgn(200,1,0.01);
RKNEEy = RKNEEy+noise;
noise = 0.0001*wgn(200,1,0.01);
RKNEEz = RKNEEz+noise;
noise = 0.0001*wgn(200,1,0.01);
RSHANKx = RSHANKx+noise;
noise = 0.0001*wgn(200,1,0.01);
RSHANKy = RSHANKy+noise;
noise = 0.0001*wgn(200,1,0.01);
RSHANKz = RSHANKz+noise;
noise = 0.0001*wgn(200,1,0.01);
RLANKx = RLANKx+noise;
noise = 0.0001*wgn(200,1,0.01);
RLANKy = RLANKy+noise;
noise = 0.0001*wgn(200,1,0.01);
RLANKz = RLANKz+noise;
noise = 0.0001*wgn(200,1,0.01);
RHEELx = RHEELx+noise;
noise = 0.0001*wgn(200,1,0.01);
RHEELy = RHEELy+noise;
noise = 0.0001*wgn(200,1,0.01);
RHEELz = RHEELz+noise;
noise = 0.0001*wgn(200,1,0.01);
RTOEx = RTOEx+noise;
noise = 0.0001*wgn(200,1,0.01);
RTOEy = RTOEy+noise;
noise = 0.0001*wgn(200,1,0.01);
RTOEz = RTOEz+noise;
noise = 0.0001*wgn(200,1,0.01);
LTHIGHx = LTHIGHx+noise;
noise = 0.0001*wgn(200,1,0.01);
LTHIGHy = LTHIGHy+noise;
noise = 0.0001*wgn(200,1,0.01);
LTHIGHz = LTHIGHz+noise;
noise = 0.0001*wgn(200,1,0.01);
LKNEEx = LKNEEx+noise;
noise = 0.0001*wgn(200,1,0.01);
LKNEEy = LKNEEy+noise;
noise = 0.0001*wgn(200,1,0.01);
LKNEEz = LKNEEz+noise;
noise = 0.0001*wgn(200,1,0.01);
LSHANKx = LSHANKx+noise;
noise = 0.0001*wgn(200,1,0.01);
LSHANKy = LSHANKy+noise;
noise = 0.0001*wgn(200,1,0.01);
LSHANKz = LSHANKz+noise;
noise = 0.0001*wgn(200,1,0.01);
LLANKx = LLANKx+noise;
noise = 0.0001*wgn(200,1,0.01);
LLANKy = LLANKy+noise;
noise = 0.0001*wgn(200,1,0.01);
LLANKz = LLANKz+noise;
noise = 0.0001*wgn(200,1,0.01);
LHEELx = LHEELx+noise;
noise = 0.0001*wgn(200,1,0.01);
LHEELy = LHEELy+noise;
noise = 0.0001*wgn(200,1,0.01);
LHEELz = LHEELz+noise;
noise = 0.0001*wgn(200,1,0.01);
LTOEx = LTOEx+noise;
noise = 0.0001*wgn(200,1,0.01);
LTOEy = LTOEy+noise;
noise = 0.0001*wgn(200,1,0.01);
LTOEz = LTOEz+noise;

frame = [1:200]';
time = frame*0.01-0.01;


%%
%make data array to write:
m = [frame time RASISx RASISy RASISz LASISx LASISy LASISz RPSISx RPSISy RPSISz LPSISx LPSISy LPSISz RTHIGHx RTHIGHy RTHIGHz RKNEEx RKNEEy RKNEEz RSHANKx RSHANKy RSHANKz RLANKx RLANKy RLANKz RHEELx RHEELy RHEELz RTOEx RTOEy RTOEz LTHIGHx LTHIGHy LTHIGHz LKNEEx LKNEEy LKNEEz LSHANKx LSHANKy LSHANKz LLANKx LLANKy LLANKz LHEELx LHEELy LHEELz LTOEx LTOEy LTOEz];

figure(1)
scatter3(RASISx,RASISy,RASISz);
hold on
scatter3(LASISx,LASISy,LASISz);
scatter3(RPSISx,RPSISy,RPSISz);
scatter3(LPSISx,LPSISy,LPSISz);
scatter3(RTHIGHx,RTHIGHy,RTHIGHz);
scatter3(LTHIGHx,LTHIGHy,LTHIGHz);
scatter3(RKNEEx,RKNEEy,RKNEEz);
scatter3(LKNEEx,LKNEEy,LKNEEz);
scatter3(RSHANKx,RSHANKy,RSHANKz);
scatter3(LSHANKx,LSHANKy,LSHANKz);
scatter3(RLANKx,RLANKy,RLANKz);
scatter3(LLANKx,LLANKy,LLANKz);
scatter3(RHEELx,RHEELy,RHEELz);
scatter3(LHEELx,LHEELy,LHEELz);
scatter3(RTOEx,RTOEy,RTOEz);
scatter3(LTOEx,LTOEy,LTOEz);

%write the trc file
%define header lines
hline1 = sprintf(['PathFileType' tab '4' tab '(X/Y/Z)' tab writefilename]);
hline2 = sprintf(['DataRate' tab 'CameraRate' tab 'NumFrames' tab 'NumMarkers' tab 'Units' tab 'OrigDataRate' tab 'OrigDataStartFrame' tab 'OrigNumFrames']);
hline3 = sprintf(['100' tab '100' tab '200' tab '16' tab 'm' tab '100' tab '1' tab '1']);
hline4 = sprintf(['Frame#' tab 'Time' tab 'RASIS' tab tab tab 'LASIS' tab tab tab 'RPSIS' tab tab tab 'LPSIS' tab tab tab 'RTHIGH' tab tab tab 'RKNEE' tab tab tab 'RSHANK' tab tab tab 'RLANK' tab tab tab 'RHEEL' tab tab tab 'RTOE' tab tab tab 'LTHIGH' tab tab tab 'LKNEE' tab tab tab 'LSHANK' tab tab tab 'LLANK' tab tab tab 'LHEEL' tab tab tab 'LTOE']);
% hline5 = sprintf([tab tab 'X1' tab 'Y1' tab 'Z1' tab 'X2' tab 'Y2' tab 'Z2' tab 'X3' tab 'Y3' tab 'Z3' tab 'X4' tab 'Y4' tab 'Z4' tab 'X5' tab 'Y5' tab 'Z5' tab 'X6' tab 'Y6' tab 'Z6' tab 'X7' tab 'Y7' tab 'Z7' tab 'X8' tab 'Y8' tab 'Z8' tab 'X9' tab 'Y9' tab 'Z9' tab 'X10' tab 'Y10' tab 'Z10' tab 'X11' tab 'Y11' tab 'Z11' tab 'X12' tab 'Y12' tab 'Z12' tab 'X13' tab 'Y13' tab 'Z13' tab 'X14' tab 'Y14' tab 'Z14' tab 'X15' tab 'Y15' tab 'Z15' tab 'X16' tab 'Y16' tab 'Z16']);
hline5 = sprintf([tab tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z' tab 'x' tab 'y' tab 'z']);
%write data
dlmwrite(writefilename,hline1,'delimiter','');
dlmwrite(writefilename,hline2,'delimiter','','-append');
dlmwrite(writefilename,hline3,'delimiter','','-append');
dlmwrite(writefilename,hline4,'delimiter','','-append');
dlmwrite(writefilename,hline5,'delimiter','','-append');
dlmwrite(writefilename,m,'delimiter',tab,'-append');%write the data


% keyboard
end

