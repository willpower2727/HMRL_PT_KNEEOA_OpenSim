%% Analyze GRF data
%This script averages grf in the Z direction for each trial then reports in
%a excel sheet
%WDA 11/21/2014

clear
clc

[filename,path] = uigetfiles('*.*','Select file to Reduce:');

if iscell(filename)
    
    for z = 1:length(filename)
        
        load('C:\Users\Engineer\Documents\MATLAB\massheight.mat');
        
        tempfname = filename(z);
        tempfname = tempfname{1};
        
        %figure out mass to normalize by
        [C,IA,IB] = intersect(tempfname(1:4),massheight(:,1));%figure out what the mass/height should be
        mass = cell2mat(massheight(IB,2));
        BW = mass*9.8
        
        %load grf
        s = importdata([path{z} tempfname],'\t',9);
        data = s.data;
        clear s
        
        
        Rz = data(:,21)./BW;%normalize by body weight
        Lz = data(:,20)./BW;
        
        RHS = data(:,22);
        LHS = data(:,23);
        
        %clean up the RHS and LHS data to only zeros and ones
        for u=1:length(RHS)
            temp1 = RHS;
            if temp1(u) ~= 0 && temp1(u) ~= 1
                temp1(u) = 0;
            else
            end
            RHS = temp1;
        end
        
        for u=1:length(LHS)
            temp1 = LHS;
            if temp1(u) ~= 0 && temp1(u) ~= 1
                temp1(u) = 0;
            else
            end
            LHS = temp1;
        end
        
        %make sure there is only one hs in a row
        for u = 1:length(RHS)-1
            if RHS(u+1) == 1 && RHS(u) == 0
                RHS(u+2:u+100) = 0;
            end
        end
        for u = 1:length(LHS)-1
            if LHS(u+1) == 1 && LHS(u) == 0
                LHS(u+2:u+100) = 0;
            end
        end
        
        rindex = find(RHS);
        lindex = find(LHS);
        
        for zz = 1:length(rindex)-1 % reduce R
            
            if rindex(zz+1)-rindex(zz) > 1500%remove steps that are unreasonably wrong
                Rzz{z,zz} = nan(101,1);
            else
                Rzz{z,zz} = interp1(linspace(0,1,length(Rz(rindex(zz):rindex(zz+1)))),Rz(rindex(zz):rindex(zz+1)),linspace(0,1,101));
            end
        end
        for zz = 1:length(lindex)-1 % Reduce L
            
            if lindex(zz+1)-lindex(zz) > 1500
                Lzz{z,zz} = nan(101,1);
            else
                Lzz{z,zz} = interp1(linspace(0,1,length(Lz(lindex(zz):lindex(zz+1)))),Lz(lindex(zz):lindex(zz+1)),linspace(0,1,101));
            end
        end
        
        %perform some arduous eliminating of bad steps!!
        for zz = 1:length(rindex)-1
            
            temp = Rzz{z,zz};%look at the forceplate Z direction loading profile to look for bad steps where maybe subject stepped on both forceplates at the smae time by mistake
            
            if temp(12) > -0.06 %(N) if forceplate isn't fully loaded by 12% gait cycle then it must be a bad step
                Lzz{z,zz} = nan(101,1);
                Rzz{z,zz} = nan(101,1);
                
            elseif temp(70) ~= 0  %Toe off occurs at 62% gait cycle, std is 2%, so at 66% if the force on the plate isn't back to zero, there is a bad step
                
                Rzz{z,zz} = nan(101,1);
                Lzz{z,zz} = nan(101,1);
                
            else %if temp passes these two criteria then the stride is most likely good for analysis
            end
            
        end
        
        for zz = 1:length(lindex)-1
            
            temp = Lzz{z,zz};%look at the forceplate Z direction loading profile to look for bad steps where maybe subject stepped on both forceplates at the smae time by mistake
            
            if temp(12) > -0.06 %(N) if forceplate isn't fully loaded by 12% gait cycle then it must be a bad step
                
                Lzz{z,zz} = nan(101,1);
                Rzz{z,zz} = nan(101,1);
                
            elseif temp(70)<-5  %Toe off occurs at 62% gait cycle, std is 2%, so at 66% if the force on the plate isn't back to zero, there is a bad step
                
                Lzz{z,zz} = nan(101,1);
                Rzz{z,zz} = nan(101,1);
                
            else %if temp passes these two criteria then the stride is most likely good for analysis
            end
            
        end
        
        %delete anything more than 30 steps
        %         Rzz{z,31:end} = [];
        %         Lzz{z,31:end} = [];
        
        
        %make plots of individual steps, look for bad steps, they should have all
        %been removed by now...
        %         for zz = 1:length(Lzz)-1
        %             figure(54)
        %             hold on
        %             plot(0:100,Lzz{z,zz},0:100,Rzz{z,zz});%,0:100,LKflex{z,zz});
        %             xlim([0 102]);
        %
        %             %     figure(12)
        %             %     hold on
        %             %     plot(1:101,RKflex{z,zz},1:101,LKflex{z,zz});
        %             %     title('knee flexion');
        %             %
        %             %     figure(13)
        %             %     hold on
        %             %     plot(1:101,RKYmom{z,zz},1:101,LKYmom{z,zz});
        %             %     title('knee flexion moment');
        %
        %         end
        
        %find two peaks
        for zz = 1:length(rindex)-1
            tp = Rzz{z,zz};
            Rz1{zz,z} = abs(min(tp(1:30)));
            Rz2{zz,z} = abs(min(tp(31:60)));
        end
        
        for zz = 1:length(lindex)-1
            tp = Lzz{z,zz};
            Lz1{zz,z} = abs(min(tp(1:30)));
            Lz2{zz,z} = abs(min(tp(31:60)));
        end
        
        for u = 1:length(rindex)-1
            temp11(:,u) = Rzz{z,u};
        end
        for u = 1:length(lindex)-1
            temp22(:,u) = Lzz{z,u};
        end
        
        Rzmean{z} = nanmean(temp11,2);
        Lzmean{z} = nanmean(temp22,2);
        
    end
    
    
[m,n] = size(Rz1);
%get rid of uneven cell lengths in order to write matrix to xls
for z = 1:m
    for zz = 1:n
        if isempty(Rz1{z,zz}) || isnan(Rz1{z,zz})
            Rz1{z,zz} = 0;
            Rz2{z,zz} = 0;
        end
    end
end

[m,n] = size(Lz1);
%get rid of uneven cell lengths in order to write matrix to xls
for z = 1:m
    for zz = 1:n
        if isempty(Lz1{z,zz}) || isnan(Lz1{z,zz})
            Lz1{z,zz} = 0;
            Lz2{z,zz} = 0;
        end
    end
end
%     keyboard
    %write to file
%     curves2excelD1(tempfname(1:4),['F:\HMRL_Pitt\Knee OA Pain Markers\Results\GRF_day1.xlsx'],Rzmean,Lzmean);
    curves2excelD2(tempfname(1:4),['F:\HMRL_Pitt\Knee OA Pain Markers\Results\GRF_day2.xlsx'],Rzmean,Lzmean);

%     GRFpeaksD1(tempfname(1:4),['F:\HMRL_Pitt\Knee OA Pain Markers\Results\GRF_day1_peaks.xlsm'],Rz1,Rz2,Lz1,Lz2);
    GRFpeaksD2(tempfname(1:4),['F:\HMRL_Pitt\Knee OA Pain Markers\Results\GRF_day2_peaks.xlsm'],Rz1,Rz2,Lz1,Lz2);



else
    
    load('C:\Users\Engineer\Documents\MATLAB\massheight.mat');
    
    tempfname = filename;
    tempfname = tempfname;
    
    %figure out mass to normalize by
    [C,IA,IB] = intersect(tempfname(1:4),massheight(:,1));%figure out what the mass/height should be
    mass = cell2mat(massheight(IB,2));
    BW = mass*9.8
    
    %load grf
    s = importdata([path tempfname]);
    data = s.data;
    clear s
    
    
end



