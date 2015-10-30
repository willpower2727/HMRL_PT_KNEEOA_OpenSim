%Script calculates the step length by finding the time between HS and TO,
%and finds distance based on speed of the treadmill.
%WDA 7/22/2014

clear
clc

names = uigetfiles;

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
    
    time{z} = data(:,1)/1000;
    
    RHS = data(:,4);
    LHS = data(:,5);
    RTO = data(:,6);
    LTO = data(:,7);
    
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
    
    %clean up the RHS and LHS data to only zeros and ones
    for u=1:length(RTO)
        temp1 = RTO;
        if temp1(u) ~= 0 && temp1(u) ~= 1
            temp1(u) = 0;
        else
        end
        RTO = temp1;
    end
    
    for u=1:length(LTO)
        temp1 = LTO;
        if temp1(u) ~= 0 && temp1(u) ~= 1
            temp1(u) = 0;
        else
        end
        LTO = temp1;
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
    
    %make sure there is only one hs in a row
    for u = 1:length(RTO)-1
        if RTO(u+1) == 1 && RTO(u) == 0
            RTO(u+2:u+100) = 0;
        end
    end
    for u = 1:length(LTO)-1
        if LTO(u+1) == 1 && LTO(u) == 0
            LTO(u+2:u+100) = 0;
        end
    end
    
    RTO = 2*RTO;
    LTO = 2*LTO;
    
    Rindex = find(RHS);
    Lindex = find(LHS);
    Rindext = find(RTO);
    Lindext = find(LTO);
    
    %check to see which event comes first, then crop to same # of steps R
    %and L
    if length(Lindex) > length(Lindext)
        Lindex(end) = [];
    elseif length(Lindext) > length(Lindex)
        Lindext(end) = [];
    end
    if length(Rindex) > length(Rindext)
        Rindex(end) = [];
    elseif length(Rindext) > length(Rindex)
        Rindext(end) = [];
    end
        
    
    if Rindex(1) < Rindext(1)
        
        Rall = (Rindext-Rindex)/1000;
    else
        Rindext(1) = [];
        Rindex(end) = [];
        Rall = (Rindext-Rindex)/1000;
    end
    if Lindex(1) < Lindext(1)
        
        Lall = (Lindext-Lindex)/1000;
    else
        Lindext(1) = [];
        Lindex(end) = [];
        Lall = (Lindext-Lindex)/1000;
    end
    
    Rstancel{z} = Rall*1.31;
    Lstancel{z} = Lall*1.31;
    Rcad{z} = (length(Rindex)/(max(Rindex)/1000))*60;%right leg cadence
    Lcad{z} = (length(Lindex)/(max(Lindex)/1000))*60;%left
    Rstride{z} = diff(Rindex)*1.31;
    Lstride{z} = diff(Lindex)*1.31;

end

for z=1:length(Rstancel)
    
    len(z) = length(Rstancel{z});
    len2(z) = length(Rstride{z});
    len3(z) = length(Lstancel{z});
    len4(z) = length(Lstride{z});
end

cap = min(len);
cap2 = min(len2);
cap3 = min(len3);
cap4 = min(len4);

for z=1:length(Rstancel)
    
    temp = Rstancel{z};
    temp2 = Lstancel{z};
    temp3 = Rstride{z};
    temp4 = Lstride{z};
    if length(temp) > cap
        temp(cap+1:end) = [];
    end
    if length(temp2) > cap3
        temp2(cap3+1:end) = [];
    end
    if length(temp3) > cap2
        temp3(cap2+1:end) = [];
    end
    if length(temp4) > cap4
        temp4(cap4+1:end) = [];
    end
    
    Rstancel{z} = temp;
    Lstancel{z} = temp2;
    Rstride{z} = temp3;
    Lstride{z} = temp4;
end

Rstancel = cell2mat(Rstancel);
Lstancel = cell2mat(Lstancel);
Rcad = cell2mat(Rcad);
Lcad = cell2mat(Lcad);
Rstride = cell2mat(Rstride)./1000;%convert to meters
Lstride = cell2mat(Lstride)./1000;


stancelengthD1('OA77',Rstancel,Lstancel,Rcad,Lcad,Rstride,Lstride);































    