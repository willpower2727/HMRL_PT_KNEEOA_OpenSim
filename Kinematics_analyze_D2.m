
%09/27/2013
%WDA

clear all
close all
clc

names = uigetfiles('*.*');

if ~iscell(names)
    bla = 1;
else
    bla = names;
end

for z = 1:length(bla)

    
    if ~iscell(names)
        s = importdata(names,'\t',9);
    else
    s = importdata(names{z},'\t',9);
    end
    
    data = s.data;
    clear s;
    
    %parse data and filter 
    time{z} = data(:,1)/1000;
    RHIPext = data(:,2)*-1;%make hip flexion positive
    LHIPext = data(:,5)*-1;
    
%     RHIPadd = data(:,4)*-1;%make abd positive
%     LHIPabd = data(:,7);
    
%     RHIPerot = data(:,3);
%     LHIPirot = data(:,6)*-1;%make external rotation positive
    
    RKNEEflex = data(:,8);
    LKNEEflex = data(:,11);
    
    RKNEEadd = data(:,9)*-1;%make abd positive
    LKNEEabd = data(:,12);
    
%     RKNEEerot = data(:,10);
%     LKNEEirot = data(:,13)*-1;%make ext rot positive
    
    RANKplant = data(:,14)*-1-74.493;%plantar Flexion is positive here...
    LANKplant = data(:,17)*-1-73.042;
    
%     RANKirot = data(:,15)*-1;%make ext rotation positive
%     LANKerot = data(:,18);
    
%     RANKadd = data(:,16)*-1;%make abd positive
%     LANKabd = data(:,19);
    
%     Rflexmom = data(:,20)*1/height;
%     Raddmom = data(:,21)*-1/height;%make abduction positive moment
    
%     Lflexmom = data(:,22)*1/height;
%     Labdmom = data(:,23)*1/height;
    
    Rz = data(:,20);
    
%     if z == 5 || z == 6
%         Lz = data(:,20)+21.34;
%     else
        Lz = data(:,21);
%     end
    
    RHS = data(:,22);
    LHS = data(:,23);
    
    
%     figure(222)
%     plot(1:length(RKNEEflex),Rz,1:length(RKNEEflex),Lz);
%     
%     figure(223)
%     plot(1:length(RKNEEflex),Lz);
%     keyboard
          
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
    
%     figure(55)
%     plot(time{z},Rz);
%     
%     figure(66)
%     plot(time{z},Lz);
    

%do data reduction
rindex = find(RHS);

for zz = 1:length(rindex)-1
    
    if rindex(zz+1)-rindex(zz) > 1500%remove steps that are unreasonably wrong
        
        RHflex{z,zz} = nan(101,1);%flexion is now positive!!
%         RHabd{z,zz} = nan(101,1);%abd is now positive
%         RHrot{z,zz} = nan(101,1);
        
        RKflex{z,zz} = nan(101,1);
        RKabd{z,zz} = nan(101,1);
%         RKrot{z,zz} = nan(101,1);
        
        RAplant{z,zz} = nan(101,1);
%         RArot{z,zz} = nan(101,1);
%         RAabd{z,zz} = nan(101,1);
        
        Rzz{z,zz} = nan(101,1);
        
%         RKYmom{z,zz} = nan(101,1);
%         RKZmom{z,zz} = nan(101,1);
        
    else
        
        RHflex{z,zz} = interp1(linspace(0,1,length(RHIPext(rindex(zz):rindex(zz+1)))),RHIPext(rindex(zz):rindex(zz+1)),linspace(0,1,101));%flexion is now positive!!
%         RHabd{z,zz} = interp1(linspace(0,1,length(RHIPadd(rindex(zz):rindex(zz+1)))),RHIPadd(rindex(zz):rindex(zz+1)),linspace(0,1,101));%abd is now positive
%         RHrot{z,zz} = interp1(linspace(0,1,length(RHIPerot(rindex(zz):rindex(zz+1)))),RHIPerot(rindex(zz):rindex(zz+1)),linspace(0,1,101));
        
        RKflex{z,zz} = interp1(linspace(0,1,length(RKNEEflex(rindex(zz):rindex(zz+1)))),RKNEEflex(rindex(zz):rindex(zz+1)),linspace(0,1,101));
        RKabd{z,zz} = interp1(linspace(0,1,length(RKNEEadd(rindex(zz):rindex(zz+1)))),RKNEEadd(rindex(zz):rindex(zz+1)),linspace(0,1,101));%abd is now positive
%         RKrot{z,zz} = interp1(linspace(0,1,length(RKNEEerot(rindex(zz):rindex(zz+1)))),RKNEEerot(rindex(zz):rindex(zz+1)),linspace(0,1,101));%ext rot is positive
        
        RAplant{z,zz} = interp1(linspace(0,1,length(RANKplant(rindex(zz):rindex(zz+1)))),RANKplant(rindex(zz):rindex(zz+1)),linspace(0,1,101));
%         RArot{z,zz} = interp1(linspace(0,1,length(RANKirot(rindex(zz):rindex(zz+1)))),RANKirot(rindex(zz):rindex(zz+1)),linspace(0,1,101));%ext is now positive!
%         RAabd{z,zz} = interp1(linspace(0,1,length(RANKadd(rindex(zz):rindex(zz+1)))),RANKadd(rindex(zz):rindex(zz+1)),linspace(0,1,101));%abd is now positive
        
        Rzz{z,zz} = interp1(linspace(0,1,length(Rz(rindex(zz):rindex(zz+1)))),Rz(rindex(zz):rindex(zz+1)),linspace(0,1,101));
        
%         RKYmom{z,zz} = interp1(linspace(0,1,length(Rflexmom(rindex(zz):rindex(zz+1)))),Rflexmom(rindex(zz):rindex(zz+1)),linspace(0,1,101));
%         RKZmom{z,zz} = interp1(linspace(0,1,length(Raddmom(rindex(zz):rindex(zz+1)))),Raddmom(rindex(zz):rindex(zz+1)),linspace(0,1,101));
        
    end
end

lindex = find(LHS);

for zz = 1:length(lindex)-1
    
    if lindex(zz+1)-lindex(zz) > 1500
        
        LHflex{z,zz} = nan(101,1);%flexion is now positive!!
%         LHabd{z,zz} = nan(101,1);%abd is now positive
%         LHrot{z,zz} = nan(101,1);
        
        LKflex{z,zz} = nan(101,1);
        LKabd{z,zz} = nan(101,1);
%         LKrot{z,zz} = nan(101,1);
        
        LAplant{z,zz} = nan(101,1);
%         LArot{z,zz} = nan(101,1);
%         LAabd{z,zz} = nan(101,1);
        
        Lzz{z,zz} = nan(101,1);
        
%         LKYmom{z,zz} = nan(101,1);
%         LKZmom{z,zz} = nan(101,1);
        
    else
        
        LHflex{z,zz} = interp1(linspace(0,1,length(LHIPext(lindex(zz):lindex(zz+1)))),LHIPext(lindex(zz):lindex(zz+1)),linspace(0,1,101));%flexion is now positive!!
%         LHabd{z,zz} = interp1(linspace(0,1,length(LHIPabd(lindex(zz):lindex(zz+1)))),LHIPabd(lindex(zz):lindex(zz+1)),linspace(0,1,101));
%         LHrot{z,zz} = interp1(linspace(0,1,length(LHIPirot(lindex(zz):lindex(zz+1)))),LHIPirot(lindex(zz):lindex(zz+1)),linspace(0,1,101));%extn rot is now positive!
        
        LKflex{z,zz} = interp1(linspace(0,1,length(LKNEEflex(lindex(zz):lindex(zz+1)))),LKNEEflex(lindex(zz):lindex(zz+1)),linspace(0,1,101));
        LKabd{z,zz} = interp1(linspace(0,1,length(LKNEEabd(lindex(zz):lindex(zz+1)))),LKNEEabd(lindex(zz):lindex(zz+1)),linspace(0,1,101));
%         LKrot{z,zz} = interp1(linspace(0,1,length(LKNEEirot(lindex(zz):lindex(zz+1)))),LKNEEirot(lindex(zz):lindex(zz+1)),linspace(0,1,101));%ext rot is now positive
        
        LAplant{z,zz} = interp1(linspace(0,1,length(LANKplant(lindex(zz):lindex(zz+1)))),LANKplant(lindex(zz):lindex(zz+1)),linspace(0,1,101));
%         LArot{z,zz} = interp1(linspace(0,1,length(LANKerot(lindex(zz):lindex(zz+1)))),LANKerot(lindex(zz):lindex(zz+1)),linspace(0,1,101));
%         LAabd{z,zz} = interp1(linspace(0,1,length(LANKabd(lindex(zz):lindex(zz+1)))),LANKabd(lindex(zz):lindex(zz+1)),linspace(0,1,101));%abd is now positive
        
        Lzz{z,zz} = interp1(linspace(0,1,length(Lz(lindex(zz):lindex(zz+1)))),Lz(lindex(zz):lindex(zz+1)),linspace(0,1,101));
        
%         LKYmom{z,zz} = interp1(linspace(0,1,length(Lflexmom(lindex(zz):lindex(zz+1)))),Lflexmom(lindex(zz):lindex(zz+1)),linspace(0,1,101));
%         LKZmom{z,zz} = interp1(linspace(0,1,length(Labdmom(lindex(zz):lindex(zz+1)))),Labdmom(lindex(zz):lindex(zz+1)),linspace(0,1,101));
    end
end


%perform some arduous eliminating of bad steps!!
for zz = 1:length(rindex)-1
    
    temp = Rzz{z,zz};%look at the forceplate Z direction loading profile to look for bad steps where maybe subject stepped on both forceplates at the smae time by mistake
    
    if temp(12) > -40 %(N) if forceplate isn't fully loaded by 12% gait cycle then it must be a bad step
        
        RHflex{z,zz} = nan(101,1);
%         RHabd{z,zz} = nan(101,1);
%         RHrot{z,zz} = nan(101,1);
        
        RKflex{z,zz} = nan(101,1);
        RKabd{z,zz} = nan(101,1);
%         RKrot{z,zz} = nan(101,1);
        
        RAplant{z,zz} = nan(101,1);
%         RArot{z,zz} = nan(101,1);
%         RAabd{z,zz} = nan(101,1);
        
        Rzz{z,zz} = nan(101,1);
        
%         RKYmom{z,zz} = nan(101,1);
%         RKZmom{z,zz} = nan(101,1);
        
        LHflex{z,zz} = nan(101,1);
%         LHabd{z,zz} = nan(101,1);
%         LHrot{z,zz} = nan(101,1);
        
        LKflex{z,zz} = nan(101,1);
        LKabd{z,zz} = nan(101,1);
%         LKrot{z,zz} = nan(101,1);
        
        LAplant{z,zz} = nan(101,1);
%         LArot{z,zz} = nan(101,1);
%         LAabd{z,zz} = nan(101,1);
        
        Lzz{z,zz} = nan(101,1);
        
%         LKYmom{z,zz} = nan(101,1);
%         LKZmom{z,zz} = nan(101,1);
        
    elseif temp(70) ~= 0  %Toe off occurs at 62% gait cycle, std is 2%, so at 66% if the force on the plate isn't back to zero, there is a bad step
        
        RHflex{z,zz} = nan(101,1);
%         RHabd{z,zz} = nan(101,1);
%         RHrot{z,zz} = nan(101,1);
        
        RKflex{z,zz} = nan(101,1);
        RKabd{z,zz} = nan(101,1);
%         RKrot{z,zz} = nan(101,1);
        
        RAplant{z,zz} = nan(101,1);
%         RArot{z,zz} = nan(101,1);
%         RAabd{z,zz} = nan(101,1);
        
        Rzz{z,zz} = nan(101,1);
        
%         RKYmom{z,zz} = nan(101,1);
%         RKZmom{z,zz} = nan(101,1);
        
        LHflex{z,zz} = nan(101,1);
%         LHabd{z,zz} = nan(101,1);
%         LHrot{z,zz} = nan(101,1);
        
        LKflex{z,zz} = nan(101,1);
        LKabd{z,zz} = nan(101,1);
%         LKrot{z,zz} = nan(101,1);
        
        LAplant{z,zz} = nan(101,1);
%         LArot{z,zz} = nan(101,1);
%         LAabd{z,zz} = nan(101,1);
        
        Lzz{z,zz} = nan(101,1);
        
%         LKYmom{z,zz} = nan(101,1);
%         LKZmom{z,zz} = nan(101,1);
        
    else %if temp passes these two criteria then the stride is most likely good for analysis
    end

end

%perform some arduous eliminating of bad steps!!
for zz = 1:length(lindex)-1
    
    temp = Lzz{z,zz};%look at the forceplate Z direction loading profile to look for bad steps where maybe subject stepped on both forceplates at the smae time by mistake
    
    if temp(12) > -40 %(N) if forceplate isn't fully loaded by 12% gait cycle then it must be a bad step
        
        LHflex{z,zz} = nan(101,1);
%         LHabd{z,zz} = nan(101,1);
%         LHrot{z,zz} = nan(101,1);
        
        LKflex{z,zz} = nan(101,1);
        LKabd{z,zz} = nan(101,1);
%         LKrot{z,zz} = nan(101,1);
        
        LAplant{z,zz} = nan(101,1);
%         LArot{z,zz} = nan(101,1);
%         LAabd{z,zz} = nan(101,1);
        
        Lzz{z,zz} = nan(101,1);
        
%         LKYmom{z,zz} = nan(101,1);
%         LKZmom{z,zz} = nan(101,1);
        
        RHflex{z,zz} = nan(101,1);
%         RHabd{z,zz} = nan(101,1);
%         RHrot{z,zz} = nan(101,1);
        
        RKflex{z,zz} = nan(101,1);
        RKabd{z,zz} = nan(101,1);
%         RKrot{z,zz} = nan(101,1);
        
        RAplant{z,zz} = nan(101,1);
%         RArot{z,zz} = nan(101,1);
%         RAabd{z,zz} = nan(101,1);
        
        Rzz{z,zz} = nan(101,1);
        
%         RKYmom{z,zz} = nan(101,1);
%         RKZmom{z,zz} = nan(101,1);
        
    elseif temp(70)<-5  %Toe off occurs at 62% gait cycle, std is 2%, so at 66% if the force on the plate isn't back to zero, there is a bad step
        
        LHflex{z,zz} = nan(101,1);
%         LHabd{z,zz} = nan(101,1);
%         LHrot{z,zz} = nan(101,1);
        
        LKflex{z,zz} = nan(101,1);
        LKabd{z,zz} = nan(101,1);
%         LKrot{z,zz} = nan(101,1);
        
        LAplant{z,zz} = nan(101,1);
%         LArot{z,zz} = nan(101,1);
%         LAabd{z,zz} = nan(101,1);
        
        Lzz{z,zz} = nan(101,1);
        
%         LKYmom{z,zz} = nan(101,1);
%         LKZmom{z,zz} = nan(101,1);
        
        RHflex{z,zz} = nan(101,1);
%         RHabd{z,zz} = nan(101,1);
%         RHrot{z,zz} = nan(101,1);
        
        RKflex{z,zz} = nan(101,1);
        RKabd{z,zz} = nan(101,1);
%         RKrot{z,zz} = nan(101,1);
        
        RAplant{z,zz} = nan(101,1);
%         RArot{z,zz} = nan(101,1);
%         RAabd{z,zz} = nan(101,1);
        
        Rzz{z,zz} = nan(101,1);
        
%         RKYmom{z,zz} = nan(101,1);
%         RKZmom{z,zz} = nan(101,1);
        
    else %if temp passes these two criteria then the stride is most likely good for analysis
    end

end

%**************************************************************************
%for this subject only, 00min3 has the last 8 steps bad, need to exclude!

if z == 5
    for zz = 21:29
        RHflex{5,zz} = nan(101,1);
        RKflex{5,zz} = nan(101,1);
        RKabd{5,zz} = nan(101,1);
        RAplant{5,zz} = nan(101,1);
        Rzz{5,zz} = nan(101,1);
        
        LHflex{5,zz} = nan(101,1);
        LKflex{5,zz} = nan(101,1);
        LKabd{5,zz} = nan(101,1);
        LAplant{5,zz} = nan(101,1);
        Lzz{5,zz} = nan(101,1);
    end
else
    
end


%}
% keyboard
%now finally find Toe offs for good steps...
%find toe offs
for zz = 1:length(rindex)-1
        temp = Rzz{z,zz};
        for u = 1:100
           
            if temp(u+1) == 0 && temp(u) < 0
                temp2(u) = 1;
            else
                temp2(u) = 0;
            end
            temp2(101) = 0;
        end
        RTO{z,zz} = temp2;
        clear temp temp2;
end
%         keyboard
%find toe offs
for zz = 1:length(lindex)-1
        temp = Lzz{z,zz};
        for u = 1:100
           
            if temp(u+1) == 0 && temp(u) < 0
                temp2(u) = 1;
            else
                temp2(u) = 0;
            end
            temp2(101) = 0;
        end
       
        LTO{z,zz} = temp2;
        clear temp temp2;
end
% keyboard
%make plots of individual steps, look for bad steps, they should have all
%been removed by now...
% for zz = 1:length(Lzz)-1
%     figure(54)
%     hold on
%     plot(0:100,Lzz{z,zz});%,0:100,LKflex{z,zz});
%     xlim([0 102]);
%     
%     figure(12)
%     hold on
%     plot(1:101,RKflex{z,zz},1:101,LKflex{z,zz});
%     title('knee flexion');
%     
%     figure(13)
%     hold on
%     plot(1:101,RKYmom{z,zz},1:101,LKYmom{z,zz});
%     title('knee flexion moment');
    
% end
% keyboard

%before going to get means and stdevs, calculate key indicators for each
%stride on the various joints
%right leg first
for zz = 1:length(rindex)-1
    
    %knee joint*********************************************************
    temp1 = RKflex{z,zz};
    temp2 = RTO{z,zz};
    temp3 = RKabd{z,zz};
    
    Rk1{zz,z} = temp1(1);%K1 is flexion angle at HS
    Rk2{zz,z} = max(temp1(1:40));%K2 is max flexion at loading response
    Rk3{zz,z} = min(temp1(25:60));%K3 is max extension during load response
    
    if isnan(temp2(1))  
        Rk4{zz,z} = nan;
    else
        Rk4{zz,z} = temp1(find(temp2,1));
    end
    
    Rk5{zz,z} = max(temp1(60:90));
    Rk6{zz,z} = Rk2{zz,z}-min(temp1);%saggital plane excursion during loading response
    
    Rk7{zz,z} = abs(max(temp3)-min(temp3));%excursion of Abd DOF
    Rk8{zz,z} = min(temp3(5:40));% Abduction min during loading response
    Rk9{zz,z} = min(temp3);%global min of abduction (max adduction)

    clear temp1 temp2 temp3
    %**********************************************************************
    
    %**********************************************************************
    %Hip joint
    
    temp1 = RHflex{z,zz};
    
    Rh1{zz,z} = temp1(1);%hip flexion at HS
    Rh3{zz,z} = min(temp1);%max hip extension?
    Rh5{zz,z} = max(temp1);%max hip flexion?
    Rh6{zz,z} = abs(Rh5{zz,z}-Rh3{zz,z});
    
    clear temp1
    %**********************************************************************
    
    %**********************************************************************
    %Ankle Joint
    temp1 = RAplant{z,zz};
    
    Ra1{zz,z} = temp1(1);
    Ra3{zz,z} = max(temp1(30:70));
    Ra5{zz,z} = min(temp1);
    
    clear temp1

end

%left side *****************
for zz = 1:length(lindex)-1
    
    %**********************************************************************
    %left knee
    temp1 = LKflex{z,zz};
    temp2 = LTO{z,zz};
    temp3 = LKabd{z,zz};
    
    Lk1{zz,z} = temp1(1);%K1 is flexion angle at HS
    Lk2{zz,z} = max(temp1(1:40));%K2 is max flexion at loading response
    Lk3{zz,z} = min(temp1(25:60));%K3 is max extension during load response
    
    if isnan(temp2(1)) 
        Lk4{zz,z} = nan;
    else
        Lk4{zz,z} = temp1(find(temp2,1));
    end
    
    Lk5{zz,z} = max(temp1(60:90));
    Lk6{zz,z} = Lk2{zz,z}-min(temp1);%saggital plane excursion during loading response
    
    Lk7{zz,z} = abs(max(temp3)-min(temp3));
    Lk8{zz,z} = min(temp3(5:40));
    Lk9{zz,z} = min(temp3);
    clear temp1 temp2 temp3;
    %**********************************************************************
    
    %**********************************************************************
    %left hip
    
    temp1 = LHflex{z,zz};
    
    Lh1{zz,z} = temp1(1);
    Lh3{zz,z} = min(temp1);%max hip extension?
    Lh5{zz,z} = max(temp1);%max hip flexion?
    Lh6{zz,z} = abs(Lh5{zz,z}-Lh3{zz,z});
    
    clear temp1
    %**********************************************************************
    
    %**********************************************************************
    %left ankle joint
    temp1 = LAplant{z,zz};
    
    La1{zz,z} = temp1(1);
    La3{zz,z} = max(temp1(30:70));
    La5{zz,z} = min(temp1);
    
    clear temp1;
    
    
end


%create temporary matrices to use to get means and standard devs of trials
for u = 1:length(rindex)-1
    
    temp11(:,u) = RHflex{z,u};
%     temp22(:,u) = RHabd{z,u};
%     temp33(:,u) = RHrot{z,u};
    
    temp77(:,u) = RKflex{z,u};
    temp88(:,u) = RKabd{z,u};
%     temp99(:,u) = RKrot{z,u};
    
    temp444(:,u) = RAplant{z,u};
%     temp555(:,u) = RArot{z,u};
%     temp666(:,u) = RAabd{z,u};
    
%     temp1111(:,u) = RKYmom{z,u};
%     temp3333(:,u) = RKZmom{z,u};
    
end

for u = 1:length(lindex)-1
    
    temp44(:,u) = LHflex{z,u};
%     temp55(:,u) = LHabd{z,u};
%     temp66(:,u) = LHrot{z,u};
    
    temp111(:,u) = LKflex{z,u};
    temp222(:,u) = LKabd{z,u};
%     temp333(:,u) = LKrot{z,u};
    
    temp777(:,u) = LAplant{z,u};
%     temp888(:,u) = LArot{z,u};
%     temp999(:,u) = LAabd{z,u};
    
%     temp2222(:,u) = LKYmom{z,u};
%     temp4444(:,u) = LKZmom{z,u};
    
end

MRHflex{z} = nanmean(temp11,2);%right hip
SRHflex{z} = std(temp11');
% MRHabd{z} = nanmean(temp22,2);
% SRHabd{z} = std(temp22');
% MRHrot{z} = nanmean(temp33,2);
% SRHrot{z} = std(temp33');

MLHflex{z} = nanmean(temp44,2);%left hip
SLHflex{z} = std(temp44');
% MLHabd{z} = nanmean(temp55,2);
% SLHabd{z} = std(temp55');
% MLHrot{z} = nanmean(temp66,2);
% SLHrot{z} = std(temp66');

MRKflex{z} = nanmean(temp77,2);%right knee
SRKflex{z} = nanstd(temp77');
MRKabd{z} = nanmean(temp88,2);
SRKabd{z} = nanstd(temp88');
% MRKrot{z} = nanmean(temp99,2);
% SRKrot{z} = std(temp99');

MLKflex{z} = nanmean(temp111,2);%left knee
SLKflex{z} = nanstd(temp111');
MLKabd{z} = nanmean(temp222,2);
SLKabd{z} = nanstd(temp222');
% MLKrot{z} = nanmean(temp333,2);
% SLKrot{z} = std(temp333');

MRAplant{z} = nanmean(temp444,2);%right ankle
SRAplant{z} = std(temp444');
% MRArot{z} = nanmean(temp555,2);
% SRArot{z} = std(temp555');
% MRAabd{z} = nanmean(temp666,2);
% SRAabd{z} = nanmean(temp666');
% 
MLAplant{z} = nanmean(temp777,2);%left ankle
SLAplant{z} = std(temp777');
% MLArot{z} = nanmean(temp888,2);
% SLArot{z} = std(temp888');
% MLAabd{z} = nanmean(temp999,2);
% SLAabd{z} = nanmean(temp999');

%the moments
% MRKYmom{z} = nanmean(temp1111,2);
% SRKYmom{z} = nanstd(temp1111');
% 
% MRKZmom{z} = nanmean(temp3333,2);
% SRKZmom{z} = nanstd(temp3333');
% 
% MLKYmom{z} = nanmean(temp2222,2);
% SLKYmom{z} = std(temp2222');
% 
% MLKZmom{z} = nanmean(temp4444,2);
% SLKZmom{z} = nanstd(temp4444');

%clear temp11 temp22 temp33 temp44 temp55 temp66 temp77 temp88 temp99 tmep111 temp222 temp333 temp444 temp555 temp666 temp777 temp888 temp999 temp1111 temp2222;
end

colors = {'blue','green','red','cyan','black','yellow'};

for z = 1:length(bla)
%     
        figure(111)
        hold on
        plot(0:100,MRHflex{z},colors{z},'LineWidth',2);
        plot(0:100,(MRHflex{z}+SRHflex{z}'),'--k');
        plot(0:100,MRHflex{z}-SRHflex{z}','--k');
        title('Right Hip Flexion');
        xlabel('% Gait Cycle');
        ylabel('Hip Flexion (deg)');
    %
    %     figure(2)
    %     hold on
    %     plot(0:100,MRHabd{z},colors{z},'LineWidth',2);
    % %     plot(0:100,(MRHabd{z}+SRHabd{z}'),'--k');
    % %     plot(0:100,MRHabd{z}-SRHabd{z}','--k');
    %     title('Right Hip Abduction');
    %     xlabel('% Gait Cycle');
    %     ylabel('Abduction (deg)');
    
    %     figure(3)
    %     hold on
    %     plot(0:100,MRHrot{z},colors{z},'LineWidth',2);
    % %     plot(0:100,(MRHrot{z}+SRHrot{z}'),'--k');
    % %     plot(0:100,MRHrot{z}-SRHrot{z}','--k');
    %     title('Right Hip Rotation');
    %     xlabel('% Gait Cycle');
    %     ylabel('Rotation (deg)');
    %
        figure(44)
        hold on
        plot(0:100,MLHflex{z},colors{z},'LineWidth',2);
        plot(0:100,(MLHflex{z}+SLHflex{z}'),'--k');
        plot(0:100,MLHflex{z}-SLHflex{z}','--k');
        title('Left Hip flexion');
        xlabel('% Gait Cycle');
        ylabel('Flexion (deg)');
    %
    %     figure(5)
    %     hold on
    %     plot(0:100,MLHabd{z},colors{z},'LineWidth',2);
    % %     plot(0:100,(MLHabd{z}+SLHabd{z}'),'--k');
    % %     plot(0:100,MLHabd{z}-SLHabd{z}','--k');
    %     title('Left Hip Abduction');
    %     xlabel('% Gait Cycle');
    %     ylabel('Abduction (deg)');
    
    %     figure(6)
    %     hold on
    %     plot(0:100,MLHrot{z},colors{z},'LineWidth',2);
    % %     plot(0:100,(MLHtor{z}+SLHrot{z}'),'--k');
    % %     plot(0:100,MLHrot{z}-SLHrot{z}','--k');
%     title('Left Hip Rotation');
%     xlabel('% Gait Cycle');
%     ylabel('Rotation (deg)');

    figure(7)
    hold on
    plot(0:100,MRKflex{z},colors{z},'LineWidth',2);
    plot(0:100,(MRKflex{z}+SRKflex{z}'),'--k');
    plot(0:100,MRKflex{z}-SRKflex{z}','--k');
    title('Right Knee flexion');
    xlabel('% Gait Cycle');
    ylabel('Hip Flexion (deg)');
%     
    figure(8)
    hold on
    plot(0:100,MRKabd{z},colors{z},'LineWidth',2);
    plot(0:100,(MRKabd{z}+SRKabd{z}'),'--k');
    plot(0:100,MRKabd{z}-SRKabd{z}','--k');
    title('Right Knee Abduction');
    xlabel('% Gait Cycle');
    ylabel('Abduction (deg)');
    
%     figure(9)
%     hold on
%     plot(0:100,MRKrot{z},colors{z},'LineWidth',2);
%     plot(0:100,(MRKrot{z}+SRKrot{z}'),'--k');
%     plot(0:100,MRKrot{z}-SRKrot{z}','--k');
%     title('Right Knee Rotation');
%     xlabel('% Gait Cycle');
%     ylabel('Rotation (deg)');
    
    figure(10)
    hold on
    plot(0:100,MLKflex{z},colors{z},'LineWidth',2);
    plot(0:100,(MLKflex{z}+SLKflex{z}'),'--k');
    plot(0:100,MLKflex{z}-SLKflex{z}','--k');
    title('Left Knee flexion');
    xlabel('% Gait Cycle');
    ylabel('Flexion (deg)');
% %     
    figure(11)
    hold on
    plot(0:100,MLKabd{z},colors{z},'LineWidth',2);
    plot(0:100,(MLKabd{z}+SLKabd{z}'),'--k');
    plot(0:100,MLKabd{z}-SLKabd{z}','--k');
    title('Left Knee Abduction');
    xlabel('% Gait Cycle');
    ylabel('Abduction (deg)');
%     
%     figure(12)
%     hold on
%     plot(0:100,MLKrot{z},colors{z},'LineWidth',2);
% %     plot(0:100,(MLKrot{z}+SLKrot{z}'),'--k');
% %     plot(0:100,MLKrot{z}-SLKrot{z}','--k');
%     title('Left Knee Rotation');
%     xlabel('% Gait Cycle');
%     ylabel('Rotation (deg)');

%     figure(13)
%     hold on
%     plot(0:100,MRKYmom{z},colors{z},'LineWidth',2);
%     plot(0:100,(MRKYmom{z}+SRKYmom{z}'),'--k');
%     plot(0:100,MRKYmom{z}-SRKYmom{z}','--k');
%     title('Right Knee Flexion Moment');
%     xlabel('% Gait Cycle');
%     ylabel('Moment (N-m)');
%     
%     figure(14)
%     hold on
%     plot(0:100,MLKYmom{z},colors{z},'LineWidth',2);
%     plot(0:100,(MLKYmom{z}+SLKYmom{z}'),'--k');
%     plot(0:100,MLKYmom{z}-SLKYmom{z}','--k');
%     title('Left Knee Flexion Moment');
%     xlabel('% Gait Cycle');
%     ylabel('Moment (N-m)');

    figure(15)
    hold on
    plot(0:100,MRAplant{z},colors{z},'LineWidth',2);
    plot(0:100,(MRAplant{z}+SRAplant{z}'),'--k');
    plot(0:100,MRAplant{z}-SRAplant{z}','--k');
    title('Right Ankle Plantar Flexion');
    xlabel('% Gait Cycle');
    ylabel('Dorsi Flexion (deg)');
    
    figure(16)
    hold on
    plot(0:100,MLAplant{z},colors{z},'LineWidth',2);
    plot(0:100,(MLAplant{z}+SLAplant{z}'),'--k');
    plot(0:100,MLAplant{z}-SLAplant{z}','--k');
    title('Left Ankle Plantar Flexion');
    xlabel('% Gait Cycle');
    ylabel('Dorsi Flexion (deg)');
    
    %}
end

[m,n] = size(Rk1);
%get rid of uneven cell lengths in order to write matrix to xls
for z = 1:m
    for zz = 1:n

        if isempty(Rk1{z,zz}) || isnan(Rk1{z,zz})
            Rk1{z,zz} = 0;
            Rk2{z,zz} = 0;
            Rk3{z,zz} = 0;
            Rk4{z,zz} = 0;
            Rk5{z,zz} = 0;
            Rk6{z,zz} = 0;
            Rk7{z,zz} = 0;
            Rk8{z,zz} = 0;
            Rk9{z,zz} = 0;
            
            Rh1{z,zz} = 0;
            Rh3{z,zz} = 0;
            Rh5{z,zz} = 0;
            Rh6{z,zz} = 0;
            
            Ra1{z,zz} = 0;
            Ra3{z,zz} = 0;
            Ra5{z,zz} = 0;
            
        end
    end
end

[m,n] = size(Lk1);
%get rid of uneven cell lengths in order to write matrix to xls
for z = 1:m
    for zz = 1:n

        if isempty(Lk1{z,zz}) || isnan(Lk1{z,zz})
            Lk1{z,zz} = 0;
            Lk2{z,zz} = 0;
            Lk3{z,zz} = 0;
            Lk4{z,zz} = 0;
            Lk5{z,zz} = 0;
            Lk6{z,zz} = 0;
            Lk7{z,zz} = 0;
            Lk8{z,zz} = 0;
            Lk9{z,zz} = 0;
            
            Lh1{z,zz} = 0;
            Lh3{z,zz} = 0;
            Lh5{z,zz} = 0;
            Lh6{z,zz} = 0;
            
            La1{z,zz} = 0;
            La3{z,zz} = 0;
            La5{z,zz} = 0;
        end
        
        if isempty(Lk4{z,zz})
            Lk4{z,zz} = 0;
        else
        end
    end
end

%write Ankle curves
curves2excelD2('OA77','F:\HMRL Pitt\Knee OA Pain Markers\Results\Curves\Ankle Dorsi Flexion Curves Day 2',MRAplant,MLAplant);
%write hip curves
curves2excelD2('OA77','F:\HMRL Pitt\Knee OA Pain Markers\Results\Curves\Hip Flexion Curves Day 2',MRHflex,MLHflex);
%write knee abd curves
curves2excelD2('OA77','F:\HMRL Pitt\Knee OA Pain Markers\Results\Curves\Knee Abduction Curves Day 2',MRKabd,MLKabd);
%write knee flex curves
curves2excelD2('OA77','F:\HMRL Pitt\Knee OA Pain Markers\Results\Curves\Knee Flexion Curves Day 2',MRKflex,MLKflex);

kneeABD2excelD2('OA77',Rk7,Rk8,Rk9,Lk7,Lk8,Lk9);
kneeFLEX2excelD2('OA77',Rk1,Rk2,Rk3,Rk4,Rk5,Rk6,Lk1,Lk2,Lk3,Lk4,Lk5,Lk6);
kneeHIPexcelD2('OA77',Rh1,Rh3,Rh5,Lh1,Lh3,Lh5);
kneeANKexcelD2('OA77',Ra1,Ra3,Ra5,La1,La3,La5);

%{
write results to XLS
sheetname = names{1};
sheetname = sheetname(1:4);
tab = sprintf('\t');

header1 = {'Right Knee Kinematics'};
header2 = {['Subject ' sheetname]};
header3 = {'Rk1' tab 'Rk2'};
header = {header1 header2 header3};
colnames = {'00min' '15min' '30min' '45min' '00min' '15min' '30min' '45min' '00min' '15min' '30min' '45min' '00min' '15min' '30min' '45min' '00min' '15min' '30min' '45min' '00min' '15min' '30min' '45min'};
filename = 'KneeOA Day 1';

write knee indicators to file
xlswrite([cell2mat(Rk1) cell2mat(Rk2) cell2mat(Rk3) cell2mat(Rk4) cell2mat(Rk5) cell2mat(Rk6)],'knee flex Right file');
xlswrite([cell2mat(Lk1) cell2mat(Lk2) cell2mat(Lk3) cell2mat(Lk4) cell2mat(Lk5) cell2mat(Lk6)],'knee flex Left file');

%write hip indicators to file
xlswrite([cell2mat(Rh1) cell2mat(Rh3) cell2mat(Rh5)],'hip right');
xlswrite([cell2mat(Lh1) cell2mat(Lh3) cell2mat(Lh5)],'hip left');

%write knee abduction indicators
xlswrite([cell2mat(Rk7) cell2mat(Rk8) cell2mat(Rk9)],'knee right abduction');
xlswrite([cell2mat(Lk7) cell2mat(Lk8) cell2mat(Lk9)],'knee left abduction');

%write ankle indicators
xlswrite([cell2mat(Ra1) cell2mat(Ra3) cell2mat(Ra5)],'right ankle');
xlswrite([cell2mat(La1) cell2mat(La3) cell2mat(La5)],'left ankle');
%}
