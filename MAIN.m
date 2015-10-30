%This script performs batch processing of OpenSim tasks, taking data from
%raw marker data all the way to joint reaction loads
%
%OpenSim tasks are divided into sections, clicking run or pressing F-9 will
%run all sections. To run one section, click "Run Section" instead
%
%William Anderton 8/1/2014
%wda5@pitt.edu
%
%*************************************************************
clear
clc
%% Create Neutral Pose(s)
%*********************************************************************

%Create Static Pose TRC file from TMM EXP file, nuetral stance report
[filename,path] = uigetfile('*.*','Select NEU file to convert:');

cd(path)%go to file location

NEU2trc(filename);%call function that takes marker data from the static pose and creates a trace file to scale models with

%}
%% Create Motion and Trace Files
%**********************************************************************************

%Transform MotionMonitor .exp files to TRC and MOT files
%Select Working folder and EXP files to work on
[filename,path] = uigetfiles('*.*','Select EXP file(s) to analyze:');
if iscell(path)
    path = path{1};
    path = strrep(path,'\\','\');%make sure the path string is formatted correctly
else
    path = strrep(path,'\\','\'); 
end
addpath(path)%go to file location
%check to see if files are ready exist
if iscell(filename)
    parfor z=1:length(filename)   
        TMM2trace_rev2(filename{z});%function that tranforms marker data to the OpenSim coordinates
        TMM2motion(filename{z});%function that transforms forceplate data to OpenSim coordinates
    end
else
    TMM2trace_rev2(filename);
    TMM2motion(filename);
end
%}
%*****************************************************************************
%% Scale model(s)
% [filename,path] = uigetfiles('*.*','Select EXP file to scale:');

load OAfilenames.mat%this mat file contains the "root" file names for all 290 files to be processed
load OApathnames.mat%the associated global path names the the locations of the 290 files

% if iscell(path)
%     path = path{1};
%     path = strrep(path,'\\','\'); 
% else
%     path = strrep(path,'\\','\'); 
% end
% addpath(path);

if iscell(filename)
    for z= 1:4%length(filename)
        
        path = paths{z};
        path = strrep(path,'\\','\');
        addpath(path);
        tempfname = filename{z};
        tempfname = tempfname(2:end-5);%cut off the file extension
        disp(['iteration is: ' num2str(z)]);
        disp(tempfname)

        %create scale setup file
        load('C:\Users\Engineer\Documents\MATLAB\massheight.mat');% a mat file containing the subject mass and height for each individual
        OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Scale_Setup.xml');%read in a template scale setup file
        subject = tempfname;
        [C,IA,IB] = intersect(subject(1:4),massheight(:,1));%figure out what the mass/height should be
        mass = cell2mat(massheight(IB,2));
        height = cell2mat(massheight(IB,3));
        %define important instructions in xml scale setup file:
        OpenSimDocument.ScaleTool.GenericModelMaker.model_file = ['C:\Users\Engineer\Desktop\Knee_OA_OpenSim\ModelwithKneeLigaments_rev1.osim'];%path and name of generic model to scale
        OpenSimDocument.ScaleTool.mass = mass;%mass in kg
        OpenSimDocument.ScaleTool.height = height*10;%convert to mm
        OpenSimDocument.ScaleTool.ATTRIBUTE.name = [subject '_scaled'];%name of output
        OpenSimDocument.ScaleTool.ModelScaler.marker_file = [path '\' subject(1:4) '_static.trc'];%static trial to scale with
        OpenSimDocument.ScaleTool.ModelScaler.output_model_file = [path '\' subject '_scaled_model.osim'];%name of the scaled model to use later
        OpenSimDocument.ScaleTool.ModelScaler.output_scale_file = [subject '_scale_output.xml'];%name of the scale output file, this will contain the results of the scaling. We will use this later when we check to see if scaling is good enough.
        OpenSimDocument.ScaleTool.MarkerPlacer.marker_file = [path '\' subject(1:4) '_static.trc'];%name of static trc file to use for scaling
        OpenSimDocument.ScaleTool.ModelScaler.preserve_mass_distribution = 'true';
        OpenSimDocument.ScaleTool.MarkerPlacer.output_model_file = [path '\' subject '_scaled_model.osim'];%name of the scaled model to use later
        OpenSimDocument.ScaleTool.ModelScaler.time_range = num2str(OpenSimDocument.ScaleTool.ModelScaler.time_range);
        OpenSimDocument.ScaleTool.MarkerPlacer.time_range = num2str(OpenSimDocument.ScaleTool.MarkerPlacer.time_range);
        xml_write([path '\' tempfname '_scale_setup.xml'],OpenSimDocument);%write scale setup file
%         clear OpenSimDocument
        addpath('C:\OpenSim 3.2\bin');%can't pass in full path to command line, since there is a #$%@&*@ space between "OpenSim" and "3.2" in the path..tedious...
        addpath('C:\Users\Engineer\Desktop\Knee_OA_OpenSim');
        cd([path '\']);%change the cd
        Command = ['scale -S ' tempfname '_scale_setup.xml'];%create string command to execute scale.exe
        disp(['Running initial scale:']);
        system(Command);%execute the scale.exe with input as the new scale setup file
        
        %evaluate the quality of the first scale
        load('C:\Users\Engineer\Documents\MATLAB\markerlist.mat');%list of all the markers
        %check results, determine whether or not the errors are low enough
        fid = fopen('out.log');%open the output log that contains the RMS errors
        H = textscan(fid,'%s',100,'delimiter','\t');%parse it
        H = H{1};
        H = char(H(28));%line 28 contains the errors, this can change often for some reason
        G = sscanf(H,'total squared error = %f, marker error: RMS=%f, max=%f %*s');%read numbers
        worstmarker = sscanf(H,'total squared error = %*f, marker error: RMS=%*f, max=%*f %s');%read name of the worst marker
        worstmarker = char(worstmarker(2:end-1))';%name of the worst marker during scale
        fclose(fid);
        delete('out.log');
        totalserror = G(1);
        markererror = G(2);
        maxerror = G(3);
        %find which # marker is the worst
        [~,bad,~] = intersect(markerlist,worstmarker);
        
        for zz = 1:20%Try to rescale the model up to 20 times to reduce the error
            if totalserror >0.01%only rescale if the error was large enough
                %re-scale to see if it improves
                OpenSimDocument = xml_read([path '\' tempfname '_Scale_Setup.xml']);%need to make some changes to the scale setup file
                for u = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]%reset all weights to 1
                    OpenSimDocument.ScaleTool.MarkerPlacer.IKTaskSet.objects.IKMarkerTask(u).weight = 1;
                end
                OpenSimDocument.ScaleTool.MarkerPlacer.IKTaskSet.objects.IKMarkerTask(bad).weight = OpenSimDocument.ScaleTool.MarkerPlacer.IKTaskSet.objects.IKMarkerTask(bad).weight + 2;%increase the weight on the worst marker, then run again
                %make sure to use the previously scaled model
                OpenSimDocument.ScaleTool.GenericModelMaker.model_file = [path '\' tempfname '_scaled_model.osim'];
                OpenSimDocument.ScaleTool.ATTRIBUTE.name = [tempfname '_scaled_model.osim'];
                OpenSimDocument.ScaleTool.ModelScaler.output_model_file = [path '\' tempfname '_scaled_model.osim'];
                OpenSimDocument.ScaleTool.MarkerPlacer.output_model_file = [path '\' tempfname '_scaled_model.osim'];
                xml_write([path '\' tempfname '_scale_setup.xml'],OpenSimDocument);%write scale setup file again
%                                 keyboard
                %run scale.exe again
                disp(['Running scale # ' num2str(zz) ':']);
                system(Command);
%                 clear OpenSimDocument
                fid = fopen('out.log');%open the output log that contains the RMS errors
                H = textscan(fid,'%s',100,'delimiter','\t');%parse it
                H = H{1};
                H = char(H(28));%line 28 contains the errors
                G = sscanf(H,'total squared error = %f, marker error: RMS=%f, max=%f %*s');%read numbers
                worstmarker = sscanf(H,'total squared error = %*f, marker error: RMS=%*f, max=%*f %s');%read name of the worst marker
                worstmarker = char(worstmarker(2:end-1))';
                fclose(fid);
                totalserror = G(1)
                markererror = G(2);
                maxerror = G(3);
                %find which # marker is the worst
                [~,bad,~] = intersect(markerlist,worstmarker);
                delete('out.log');
            else
                break
            end
        end
        if zz == 20
            disp(['Scale.exe did not find a suitable solution, please check setup files']);
            
        end
    end
    
else
    
    %create scale setup file
    load('C:\Users\Engineer\Documents\MATLAB\massheight.mat');
    OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Scale_Setup.xml');
    subject = filename(1:end-4);
    %get mass and height for this subject from table of subjects
    [C,IA,IB] = intersect(subject(1:4),massheight(:,1));
    mass = cell2mat(massheight(IB,2));
    height = cell2mat(massheight(IB,3));
    %define important instructions in xml setup file:
    OpenSimDocument.ScaleTool.GenericModelMaker.model_file = ['C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Arnoldetal2010_2Legs_v2.osim'];%path and name of generic model to scale
    OpenSimDocument.ScaleTool.mass = mass;%mass in kg
    OpenSimDocument.ScaleTool.height = height*10;%convert to mm
    OpenSimDocument.ScaleTool.ATTRIBUTE.name = [subject '_scaled'];%name of output
    OpenSimDocument.ScaleTool.ModelScaler.marker_file = [path subject(1:4) '_static.trc'];%static trial to scale with
    OpenSimDocument.ScaleTool.ModelScaler.output_model_file = [path subject '_scaled_model.osim'];%name of the scaled model to use later
    OpenSimDocument.ScaleTool.ModelScaler.output_scale_file = [path subject '_scale_output.xml'];%name of the scale output file, this will contain the results of the scaling. We will use this later when we check to see if scaling is good enough.
    OpenSimDocument.ScaleTool.MarkerPlacer.marker_file = [path subject(1:4) '_static.trc'];%name of static trc file to use for scaling
    OpenSimDocument.ScaleTool.ModelScaler.preserve_mass_distribution = 'true';
    OpenSimDocument.ScaleTool.ModelScaler.time_range = num2str(OpenSimDocument.ScaleTool.ModelScaler.time_range);
    OpenSimDocument.ScaleTool.MarkerPlacer.time_range = num2str(OpenSimDocument.ScaleTool.MarkerPlacer.time_range);

    xml_write([path filename(1:4) '_scale_setup.xml'],OpenSimDocument);%write scale setup file
    clear OpenSimDocument
    %try is out:
    addpath('C:\OpenSim 3.2\bin');%can't pass in full path to command line, since there is a #$%@&*@ space between "OpenSim" and "3.2" in the path...idiots...
    addpath('C:\Users\Engineer\Desktop\Knee_OA_OpenSim');
    Command = ['scale -S ' filename(1:4) '_scale_setup.xml'];%create command to execute scale.exe
    disp('Running initial scale:');
    system(Command);
    load('C:\Users\Engineer\Documents\MATLAB\markerlist.mat');
    %check results, determine whether or not the errors are low enough
    fid = fopen('out.log');%open the output log that contains the RMS errors
    H = textscan(fid,'%s',100,'delimiter','\t');%parse it
    H = H{1};
    H = char(H(28));%line 11 contains the errors
    G = sscanf(H,'total squared error = %f, marker error: RMS=%f, max=%f %*s');%read numbers
    worstmarker = sscanf(H,'total squared error = %*f, marker error: RMS=%*f, max=%*f %s');%read name of the worst marker
    worstmarker = char(worstmarker(2:end-1))';
    fclose(fid);
    totalserror = G(1);
    markererror = G(2);
    maxerror = G(3);
    %find which # marker is the worst
    [~,bad,~] = intersect(markerlist,worstmarker);
%     keyboard
    %logic to check to see if scaling needs to be re-run
    for zz = 1:20
        if totalserror >0.01
            %re-scale to see if it improves
            OpenSimDocument = xml_read([path filename(1:4) '_Scale_Setup.xml']);
            for u = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]
                OpenSimDocument.ScaleTool.MarkerPlacer.IKTaskSet.objects.IKMarkerTask(u).weight = 1;
            end
            OpenSimDocument.ScaleTool.MarkerPlacer.IKTaskSet.objects.IKMarkerTask(bad).weight = OpenSimDocument.ScaleTool.MarkerPlacer.IKTaskSet.objects.IKMarkerTask(bad).weight + 2;
            %make sure to use the previously scaled model
            OpenSimDocument.ScaleTool.GenericModelMaker.model_file = [filename(1:end-4) '_scaled_model.osim'];
            OpenSimDocument.ScaleTool.ATTRIBUTE.name = [filename(1:end-4) '_scaled_model.osim'];
            OpenSimDocument.ScaleTool.ModelScaler.output_model_file = [path filename(1:end-4) '_scaled_model.osim'];
            OpenSimDocument.ScaleTool.MarkerPlacer.output_model_file = [path filename(1:end-4) '_scaled_model.osim'];
            xml_write([filename(1:4) '_scale_setup.xml'],OpenSimDocument);%write scale setup file again
%             keyboard
            %run scale.exe again
            disp(['Running scale # ' num2str(zz) ':']);
            system(Command);
            clear OpenSimDocument
            fid = fopen('out.log');%open the output log that contains the RMS errors
            H = textscan(fid,'%s',100,'delimiter','\t');%parse it
            H = H{1};
            H = char(H(28));%line 11 contains the errors
            G = sscanf(H,'total squared error = %f, marker error: RMS=%f, max=%f %*s');%read numbers
            worstmarker = sscanf(H,'total squared error = %*f, marker error: RMS=%*f, max=%*f %s');%read name of the worst marker
            worstmarker = char(worstmarker(2:end-1))';
            fclose(fid);
            totalserror = G(1);
            markererror = G(2);
            maxerror = G(3);
            %find which # marker is the worst
            [~,bad,~] = intersect(markerlist,worstmarker);
        else
            break
        end
        if zz == 20
            disp(['Scale.exe did not find a suitable solution, please check setup files']);
        end
    end
end
%}
%% Inverse Kinematics
% [filename,path] = uigetfiles('*.*','Select EXP to run IK on:');

load OAfilenames.mat
load OApathnames.mat
% if iscell(path)
%     path = path{1};
%     path = strrep(path,'\\','\'); 
% else
%     path = strrep(path,'\\','\'); 
% end
% addpath(path);
if iscell(filename)
    
    parfor z = 1:4%length(filename)%use parallel computing to speed things up
        tempfname = filename{z};
        tempfname = tempfname(2:end-5);
        disp(['iteration is: ' num2str(z)]);
        disp(tempfname);
        
        path = paths{z};
        path = strrep(path,'\\','\');
        addpath(path);
        %create IK_setup file
        OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\IK_Setup.xml');%load a generic setup file
        OpenSimDocument.InverseKinematicsTool.model_file = [path '\' tempfname '_scaled_model.osim'];
        OpenSimDocument.InverseKinematicsTool.marker_file = [path '\' tempfname '.trc'];
        OpenSimDocument.InverseKinematicsTool.output_motion_file = [path '\' tempfname '_ik.mot'];
        OpenSimDocument.InverseKinematicsTool.report_errors = 'false';
        OpenSimDocument.InverseKinematicsTool.time_range = num2str('0 30');
        xml_write([path '\' tempfname '_IK_Setup.xml'],OpenSimDocument);%write scale setup file again
        addpath('C:\OpenSim 3.2\bin');%can't pass in full path to command line, since there is a #$%@&*@ space between "OpenSim" and "3.2" in the path
        addpath('C:\Users\Engineer\Desktop\Knee_OA_OpenSim');
        %format command
        Command = ['ik -S ' path '\' tempfname '_IK_Setup.xml'];
        disp(Command);
        system(Command);%run
    end
    
else
    %create IK_setup file
    OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\IK_Setup.xml');
    OpenSimDocument.InverseKinematicsTool.model_file = [path filename(1:end-4) '_scaled_model.osim'];
    OpenSimDocument.InverseKinematicsTool.marker_file = [path filename(1:end-4) '.trc'];
    OpenSimDocument.InverseKinematicsTool.output_motion_file = [path filename(1:end-4) '_ik.mot'];
    OpenSimDocument.InverseKinematicsTool.report_errors = 'false';
    OpenSimDocument.InverseKinematicsTool.time_range = num2str('0 30');
    xml_write([filename(1:4) '_IK_Setup.xml'],OpenSimDocument);%write scale setup file again
    addpath('C:\OpenSim 3.2\bin');%can't pass in full path to command line, since there is a #$%@&*@ space between "OpenSim" and "3.2" in the path
    addpath('C:\Users\Engineer\Desktop\Knee_OA_OpenSim');
    %format command
    Command = ['ik -S ' filename(1:4) '_IK_Setup.xml'];
    system(Command);
end
%}
%% RRA

% [filename,paths] = uigetfiles('*.*','Select EXP to run IK on:');

load OAfilenames.mat
load OApathnames.mat

% disp(paths)
if iscell(filename)
    try
        parfor z = 1:4%length(filename)-1
            
            path = paths{z};
            path = strrep(path,'\\','\');
            
            addpath(path);
            tempfname = filename{z};
            tempfname = tempfname(2:end-5)
            disp(['iteration is: ' num2str(z)]);
            disp(tempfname)
            %setup actuators file
            %go and get pelvis COM from scaled model
%             [path '\' tempfname(1:end-4) '_scaled_model.osim']
%             [path tempfname(1:end-4) '_scaled_model.osim']
            %         keyboard
%             OpenSimDocument = xml_read([path '\' tempfname(1:end-4) '_scaled_model.osim']);

            %open the scaled model
            OpenSimDocument = xml_read([path '\' tempfname '_scaled_model.osim']);
            pCOM = OpenSimDocument.Model.BodySet.objects.Body(2).mass_center;
            pCOM = num2str(pCOM);
            %         clear OpenSimDocument
            %pelvis C.O.M. needs to be inserted into the RRA actuators xml
            %file
            OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\RRA_Actuators.xml');
            OpenSimDocument.ForceSet.objects.PointActuator(1).point = pCOM;
            OpenSimDocument.ForceSet.objects.PointActuator(2).point = pCOM;
            OpenSimDocument.ForceSet.objects.PointActuator(3).point = pCOM;
            OpenSimDocument.ForceSet.objects.PointActuator(1).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(1).direction);
            OpenSimDocument.ForceSet.objects.PointActuator(2).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(2).direction);
            OpenSimDocument.ForceSet.objects.PointActuator(3).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(3).direction);
            OpenSimDocument.ForceSet.objects.TorqueActuator(1).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(1).axis);
            OpenSimDocument.ForceSet.objects.TorqueActuator(2).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(2).axis);
            OpenSimDocument.ForceSet.objects.TorqueActuator(3).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(3).axis);
%             xml_write([path '\' tempfname(1:end-4) '_rra_actuators.xml'],OpenSimDocument);
            xml_write([path '\' tempfname '_rra_actuators.xml'],OpenSimDocument);
            %         clear OpenSimDocument
            %the tasks file does not need to be altered, it's generic form applies
            %to all RRA runs
            
            %setup grf.xml
            OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\OAgrf.xml');%open generic grf setup file
%             OpenSimDocument.ExternalLoads.datafile = [path '\' tempfname(1:end-4) '.mot'];
            OpenSimDocument.ExternalLoads.datafile = [path '\' tempfname '.mot'];
%             OpenSimDocument.ExternalLoads.external_loads_model_kinematics_file = [path '\' tempfname(1:end-4) '_ik.mot'];
            OpenSimDocument.ExternalLoads.external_loads_model_kinematics_file = [path '\' tempfname '_ik.mot'];
%             xml_write([path  '\' tempfname(1:end-4) '_grf.xml'],OpenSimDocument);
            xml_write([path '\' tempfname '_grf.xml'],OpenSimDocument);
            %         clear OpenSimDocument
            
            %create RRA setup file
            OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\RRA_Setup.xml');%open generic RRA setup file
%             OpenSimDocument.RRATool.model_file = [path '\' tempfname(1:end-4) '_scaled_model.osim'];%model to use
            OpenSimDocument.RRATool.model_file = [path '\' tempfname '_scaled_model.osim'];%model to use
%             OpenSimDocument.RRATool.force_set_files = [path '\' tempfname(1:end-4) '_rra_actuators.xml'];%actuators file
            OpenSimDocument.RRATool.force_set_files = [path '\' tempfname '_rra_actuators.xml'];%actuators file
%             OpenSimDocument.RRATool.results_directory = [path '\'];%where to write output file to
            OpenSimDocument.RRATool.results_directory = [path '\'];%where to write output file to
%             OpenSimDocument.RRATool.external_loads_file = [path '\' tempfname(1:end-4) '_grf.xml'];%grf to use
            OpenSimDocument.RRATool.external_loads_file = [path '\' tempfname '_grf.xml'];%grf to use
%             OpenSimDocument.RRATool.desired_kinematics_file = [path '\' tempfname(1:end-4) '_ik.mot'];%desired kinematics (output of IK)
            OpenSimDocument.RRATool.desired_kinematics_file = [path '\' tempfname '_ik.mot'];%desired kinematics (output of IK)
            OpenSimDocument.RRATool.task_set_file = ['C:\Users\Engineer\Desktop\Knee_OA_OpenSim\RRA_tasks.xml'];
%             OpenSimDocument.RRATool.output_model_file = [path '\' tempfname(1:end-4) '_rra_model.osim'];
            OpenSimDocument.RRATool.output_model_file = [path '\' tempfname '_rra_model.osim'];
            OpenSimDocument.RRATool.ATTRIBUTE.name = [tempfname '_rra_out'];
%             xml_write([path '\' tempfname(1:end-4) '_RRA_Setup.xml'],OpenSimDocument);
            xml_write([path '\' tempfname '_RRA_Setup.xml'],OpenSimDocument);
            %         clear OpenSimDocument
            %run RRA
            addpath('C:\OpenSim 3.2\bin');%can't pass in full path to command line, since there is a #$%@&*@ space between "OpenSim" and "3.2" in the path
            addpath('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\');
%             Command = ['rra -S ' path '\' tempfname(1:end-4) '_RRA_Setup.xml'];
            Command = ['rra -S ' path '\' tempfname '_RRA_Setup.xml'];
            system(Command);
            

        end
    catch me
        %if something goes wrong, this will display but loop keeps going
        disp('An error has occured during RRA processing');
    end
else
    clc
    
    path = paths;
    path = strrep(path,'\\','\');
    addpath(path);
    %setup actuators file
    %go and get pelvis COM from scaled model
    OpenSimDocument = xml_read([path filename(1:end-4) '_scaled_model.osim']);
    pCOM = OpenSimDocument.Model.BodySet.objects.Body(2).mass_center;
    pCOM = num2str(pCOM);
    clear OpenSimDocument
    OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\RRA_Actuators.xml');
    OpenSimDocument.ForceSet.objects.PointActuator(1).point = pCOM;
    OpenSimDocument.ForceSet.objects.PointActuator(2).point = pCOM;
    OpenSimDocument.ForceSet.objects.PointActuator(3).point = pCOM;
    OpenSimDocument.ForceSet.objects.PointActuator(1).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(1).direction);
    OpenSimDocument.ForceSet.objects.PointActuator(2).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(2).direction);
    OpenSimDocument.ForceSet.objects.PointActuator(3).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(3).direction);
    OpenSimDocument.ForceSet.objects.TorqueActuator(1).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(1).axis);
    OpenSimDocument.ForceSet.objects.TorqueActuator(2).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(2).axis);
    OpenSimDocument.ForceSet.objects.TorqueActuator(3).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(3).axis);
    xml_write([path filename(1:end-4) '_rra_actuators.xml'],OpenSimDocument);
    clear OpenSimDocument
    %the tasks file does not need to be altered, it's generic form applies
    %to all RRA runs

    %setup grf.xml
    OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\OAgrf.xml');
    OpenSimDocument.ExternalLoads.datafile = [path filename(1:end-4) '.mot'];
    OpenSimDocument.ExternalLoads.external_loads_model_kinematics_file = [path filename(1:end-4) '_ik.mot'];
    xml_write([path filename(1:end-4) '_grf.xml'],OpenSimDocument);
    clear OpenSimDocument
    
    %create RRA setup file
    OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\RRA_Setup.xml');
    OpenSimDocument.RRATool.model_file = [path filename(1:end-4) '_scaled_model.osim'];%model to use
    OpenSimDocument.RRATool.force_set_files = [path filename(1:end-4) '_rra_actuators.xml'];%actuators file
    OpenSimDocument.RRATool.results_directory = pwd;%where to write output file to
    OpenSimDocument.RRATool.external_loads_file = [path filename(1:end-4) '_grf.xml'];%grf to use
    OpenSimDocument.RRATool.desired_kinematics_file = [path filename(1:end-4) '_ik.mot'];%desired kinematics (output of IK)
    OpenSimDocument.RRATool.task_set_file = ['C:\Users\Engineer\Desktop\Knee_OA_OpenSim\RRA_tasks.xml'];
    OpenSimDocument.RRATool.output_model_file = [path filename(1:end-4) '_rra_model.osim'];
    OpenSimDocument.RRATool.ATTRIBUTE.name = [filename(1:end-4) '_rra_out'];
    xml_write([path filename(1:end-4) '_RRA_Setup.xml'],OpenSimDocument);
    clear OpenSimDocument
    %run RRA
    addpath('C:\OpenSim 3.2\bin');%can't pass in full path to command line, since there is a #$%@&*@ space between "OpenSim" and "3.2" in the path
    addpath('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\');
    Command = ['rra -S ' filename(1:end-4) '_RRA_Setup.xml'];
    system(Command);
    
end
%}
%% SO

% [filename,path] = uigetfiles('*.*','Select EXP to run IK on:');
% if iscell(path)
%     path = path{1};
%     path = strrep(path,'\\','\'); 
% else
%     path = strrep(path,'\\','\'); 
% end
% addpath(path);
load OAfilenames.mat
load OApathnames.mat

if iscell(filename)
    clc
    try
        parfor z =215:220%length(filename)
        
            path = paths{z};
            addpath(path);
            tempfname = filename{z};
            tempfname = tempfname(2:end-5)
            disp(['iteration is: ' num2str(z)]);
            disp(tempfname);
            disp(path);

            %move COM of actuator in pelvis to have the same COM as model
            OpenSimDocument = xml_read([path '\' tempfname '_scaled_model.osim']);
            pCOM = OpenSimDocument.Model.BodySet.objects.Body(2).mass_center;

            %move the COM of the weak actuators
            OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\OA_CMC_Actuators.xml');
            OpenSimDocument.ForceSet.objects.PointActuator(1).point = num2str(pCOM);
            OpenSimDocument.ForceSet.objects.PointActuator(2).point = num2str(pCOM);
            OpenSimDocument.ForceSet.objects.PointActuator(3).point = num2str(pCOM);
            OpenSimDocument.ForceSet.objects.PointActuator(1).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(1).direction);
            OpenSimDocument.ForceSet.objects.PointActuator(2).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(2).direction);
            OpenSimDocument.ForceSet.objects.PointActuator(3).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(3).direction);
            OpenSimDocument.ForceSet.objects.TorqueActuator(1).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(1).axis);
            OpenSimDocument.ForceSet.objects.TorqueActuator(2).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(2).axis);
            OpenSimDocument.ForceSet.objects.TorqueActuator(3).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(3).axis);
            xml_write([path '\' tempfname '_SO_actuators.xml'],OpenSimDocument);

            
            OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\OAgrf.xml');
            OpenSimDocument.ExternalLoads.datafile = [path '\' tempfname '.mot'];
            OpenSimDocument.ExternalLoads.external_loads_model_kinematics_file = [path '\' tempfname '_ik.mot'];
            OpenSimDocument.ExternalLoads.lowpass_cutoff_frequency_for_load_kinematics = num2str(6);
            xml_write([path '\' tempfname '_grf.xml'],OpenSimDocument);
            
            OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\SO_setup.xml');
            OpenSimDocument.AnalyzeTool.ATTRIBUTE.name = [tempfname '_SO'];
            OpenSimDocument.AnalyzeTool.model_file = [path '\' tempfname '_scaled_model.osim'];
            OpenSimDocument.AnalyzeTool.force_set_files = [path '\' tempfname '_SO_actuators.xml'];
            OpenSimDocument.AnalyzeTool.results_directory = path;
            OpenSimDocument.AnalyzeTool.external_loads_file = [path '\' tempfname '_grf.xml'];
            OpenSimDocument.AnalyzeTool.coordinates_file = [path '\' tempfname '_ik.mot'];
            OpenSimDocument.AnalyzeTool.lowpass_cutoff_frequency_for_coordinates = num2str(6);
            xml_write([path '\' tempfname '_SO_setup.xml'],OpenSimDocument);

            addpath('C:\OpenSim 3.2\bin');%can't pass in full path to command line, since there is a #$%@&*@ space between "OpenSim" and "3.2" in the path...idiots...
            addpath('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\');
            Command = ['analyze -S ' path '\' tempfname '_SO_setup.xml'];
            
            %check to see if file already exists
%             if exist([path '\' tempfname '_SO_StaticOptimization_force.sto'],'file') == 2
%             else
                system(Command);
                
                if exist([path '\' tempfname '_SO_StaticOptimization_force.sto'],'file') == 2
                    %success, return
                else
                    %report an error but continue working
                    disp(['Batch Error Simtk', tempfname, ' Has failed in SO']);
                end
%             end


        end
            %{
            stop = 0;
            index = 1;
            oldcrashtime = 100;
            %loop through, solving SO in a piecewise manner
            while ~stop
                delete([path '\' tempfname '_diary']);
                diary([path '\' tempfname '_diary']);%keep track of stuff returned to the command line
                system(Command);
                diary off
                %Read the diary to the last line, check to see if an error occured.
                fid = fopen([path '\' tempfname '_diary']);
                while 1
                    line = fgetl(fid);
                    if strcmp(' ** On entry to DLASD4 parameter number -1 had an illegal value ',line) == 1
                        break;
                    else
                    end
                    pline = line;
                end
                fclose(fid);
                %check what time point caused the crash
                if strcmp(' ** On entry to DLASD4 parameter number -1 had an illegal value ',line) == 1
                    crashtime = textscan(pline,'%s %s %f');
                    crashtime = crashtime{3};
                    OpenSimDocument = xml_read([path '\' tempfname '_SO_setup.xml']);
                    %             if oldcrashtime == crashtime || ischar(crashtime)%if the program crashes at the next start point, adjust times
                    %                 OpenSimDocument.AnalyzeTool.initial_time = num2str(crashtime+0.01);
                    %                 OpenSimDocument.AnalyzeTool.AnalysisSet.objects.StaticOptimization.start_time = num2str(crashtime+0.01);
                    %                 OpenSimDocument.AnalyzeTool.final_time = num2str(5);
                    %                 OpenSimDocument.AnalyzeTool.AnalysisSet.objects.StaticOptimization.end_time = num2str(5);
                    %             else
                    %             end
                    oldcrashtime = crashtime;
                    %reset setup files to run for the next chunk of time
                    OpenSimDocument.AnalyzeTool.final_time = num2str(crashtime-0.01);
                    OpenSimDocument.AnalyzeTool.AnalysisSet.objects.StaticOptimization.end_time = num2str(crashtime-0.01);
                    OpenSimDocument.AnalyzeTool.model_file = [path '\' tempfname '_scaled_model.osim'];
                    OpenSimDocument.AnalyzeTool.force_set_files = [path '\' tempfname '_SO_actuators.xml'];
                    OpenSimDocument.AnalyzeTool.results_directory = path;
                    OpenSimDocument.AnalyzeTool.external_loads_file = [path '\' tempfname '_grf.xml'];
                    OpenSimDocument.AnalyzeTool.coordinates_file = [path '\' tempfname '_ik.mot'];
                    OpenSimDocument.AnalyzeTool.ATTRIBUTE.name = [tempfname '_SO_' num2str(index)];%increment output of each run so as to not overwrite any data
                    xml_write([path '\' tempfname '_SO_setup.xml'],OpenSimDocument);
%                     clear OpenSimDocument
                    system(Command);%run SO up until the point where it crashed last time.
                    
                    %now run again after the recent crash time...
                    OpenSimDocument = xml_read([path '\' tempfname '_SO_setup.xml']);
                    
                    OpenSimDocument.AnalyzeTool.initial_time = num2str(crashtime+0.01);
                    OpenSimDocument.AnalyzeTool.AnalysisSet.objects.StaticOptimization.start_time = num2str(crashtime+0.01);
                    OpenSimDocument.AnalyzeTool.final_time = num2str(5);
                    OpenSimDocument.AnalyzeTool.AnalysisSet.objects.StaticOptimization.end_time = num2str(5);
                    OpenSimDocument.AnalyzeTool.model_file = [path '\' tempfname '_scaled_model.osim'];
                    OpenSimDocument.AnalyzeTool.force_set_files = [path '\' tempfname '_SO_actuators.xml'];
                    OpenSimDocument.AnalyzeTool.results_directory = path;
                    OpenSimDocument.AnalyzeTool.external_loads_file = [path '\' tempfname '_grf.xml'];
                    OpenSimDocument.AnalyzeTool.coordinates_file = [path '\' tempfname '_ik.mot'];
                    OpenSimDocument.AnalyzeTool.ATTRIBUTE.name = [tempfname '_SO_' num2str(index)];%increment output of each run so as to not overwrite any data
                    xml_write([path '\' tempfname '_SO_setup.xml'],OpenSimDocument);
%                     clear OpenSimDocument
                else
                    disp(['some other problem has occured or it finished']);
                    stop = 1;
                end
                
                index = index+1;
            end
        end
            %}
    catch me
        disp('An error has occured during SO');
        disp(me);%display the error message
    end
    
else %if only one file selected
    clc
    %filter coordinates
    %     SIMTK_storage_filter([path filename(1:end-4) '_ik.mot']);
    %move COM of actuator in pelvis to have the same COM
    OpenSimDocument = xml_read([path filename(1:end-4) '_scaled_model.osim']);
    pCOM = OpenSimDocument.Model.BodySet.objects.Body(2).mass_center;
    clear OpenSimDocument
    %move the COM of the weak actuators
    OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\OA_CMC_Actuators.xml');
    OpenSimDocument.ForceSet.objects.PointActuator(1).point = num2str(pCOM);
    OpenSimDocument.ForceSet.objects.PointActuator(2).point = num2str(pCOM);
    OpenSimDocument.ForceSet.objects.PointActuator(3).point = num2str(pCOM);
    OpenSimDocument.ForceSet.objects.PointActuator(1).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(1).direction);
    OpenSimDocument.ForceSet.objects.PointActuator(2).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(2).direction);
    OpenSimDocument.ForceSet.objects.PointActuator(3).direction = num2str(OpenSimDocument.ForceSet.objects.PointActuator(3).direction);
    OpenSimDocument.ForceSet.objects.TorqueActuator(1).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(1).axis);
    OpenSimDocument.ForceSet.objects.TorqueActuator(2).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(2).axis);
    OpenSimDocument.ForceSet.objects.TorqueActuator(3).axis = num2str(OpenSimDocument.ForceSet.objects.TorqueActuator(3).axis);
    xml_write([path filename(1:end-4) '_SO_actuators.xml'],OpenSimDocument);
    clear OpenSimDocument
    
    OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\OAgrf.xml');
    OpenSimDocument.ExternalLoads.datafile = [path filename(1:end-4) '.mot'];
    OpenSimDocument.ExternalLoads.external_loads_model_kinematics_file = [path filename(1:end-4) '_ik.mot'];
    OpenSimDocument.ExternalLoads.lowpass_cutoff_frequency_for_load_kinematics = num2str(6);
    xml_write([path filename(1:end-4) '_grf.xml'],OpenSimDocument);
    
    OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\SO_setup.xml');
    OpenSimDocument.AnalyzeTool.ATTRIBUTE.name = [filename(1:end-4) '_SO'];
    OpenSimDocument.AnalyzeTool.model_file = [path filename(1:end-4) '_scaled_model.osim'];
    OpenSimDocument.AnalyzeTool.force_set_files = [path filename(1:end-4) '_SO_actuators.xml'];
    OpenSimDocument.AnalyzeTool.results_directory = path;
    OpenSimDocument.AnalyzeTool.external_loads_file = [path filename(1:end-4) '_grf.xml'];
    OpenSimDocument.AnalyzeTool.coordinates_file = [path filename(1:end-4) '_ik.mot'];
    OpenSimDocument.AnalyzeTool.lowpass_cutoff_frequency_for_coordinates = num2str(6);
    xml_write([path filename(1:end-4) '_SO_setup.xml'],OpenSimDocument);
%     keyboard
    clear OpenSimDocument
    addpath('C:\OpenSim 3.2\bin');%can't pass in full path to command line, since there is a #$%@&*@ space between "OpenSim" and "3.2" in the path
    addpath('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\');
    Command = ['analyze -S ' filename(1:end-4) '_SO_setup.xml'];
    system(Command);
    
%     stop = 0;
%     index = 1;
%     oldcrashtime = 100;
    %loop through, solving SO in a piecewise manner
%     while ~stop
% %         delete([path 'diary']);
%         delete diary
%         diary on%keep track of stuff returned to the command line
%         system(Command);
%         diary off
%         %Read the diary to the last line, check to see if an error occured.
%         fid = fopen([path 'diary']);
%         while 1
%             line = fgetl(fid);
%             if strcmp(' ** On entry to DLASD4 parameter number -1 had an illegal value ',line) == 1
%                 break;
%             else
%             end
%             pline = line;
%         end
%         fclose(fid);
%         %check what time point caused the crash
%         if strcmp(' ** On entry to DLASD4 parameter number -1 had an illegal value ',line) == 1
%             crashtime = textscan(pline,'%s %s %f');
%             crashtime = crashtime{3};
%             OpenSimDocument = xml_read([path filename(1:end-4) '_SO_setup.xml']);
% %             if oldcrashtime == crashtime || ischar(crashtime)%if the program crashes at the next start point, adjust times
% %                 OpenSimDocument.AnalyzeTool.initial_time = num2str(crashtime+0.01);
% %                 OpenSimDocument.AnalyzeTool.AnalysisSet.objects.StaticOptimization.start_time = num2str(crashtime+0.01);
% %                 OpenSimDocument.AnalyzeTool.final_time = num2str(5);
% %                 OpenSimDocument.AnalyzeTool.AnalysisSet.objects.StaticOptimization.end_time = num2str(5);
% %             else
% %             end
%             oldcrashtime = crashtime;
%             %reset setup files to run for the next chunk of time
%             OpenSimDocument.AnalyzeTool.final_time = num2str(crashtime-0.01);
%             OpenSimDocument.AnalyzeTool.AnalysisSet.objects.StaticOptimization.end_time = num2str(crashtime-0.01);
%             OpenSimDocument.AnalyzeTool.model_file = [path filename(1:end-4) '_scaled_model.osim'];
%             OpenSimDocument.AnalyzeTool.force_set_files = [path filename(1:end-4) '_SO_actuators.xml'];
%             OpenSimDocument.AnalyzeTool.results_directory = path;
%             OpenSimDocument.AnalyzeTool.external_loads_file = [path filename(1:end-4) '_grf.xml'];
%             OpenSimDocument.AnalyzeTool.coordinates_file = [path filename(1:end-4) '_ik.mot'];
%             OpenSimDocument.AnalyzeTool.ATTRIBUTE.name = [filename(1:end-4) '_' num2str(index)];%increment output of each run so as to not overwrite any data
%             xml_write([path filename(1:end-4) '_SO_setup.xml'],OpenSimDocument);
%             clear OpenSimDocument
%             system(Command);%run SO up until the point where it crashed last time.
%             
%             %now run again after the recent crash time...
%             OpenSimDocument = xml_read([path filename(1:end-4) '_SO_setup.xml']);
%             
%             OpenSimDocument.AnalyzeTool.initial_time = num2str(crashtime+0.1);
%             OpenSimDocument.AnalyzeTool.AnalysisSet.objects.StaticOptimization.start_time = num2str(crashtime+0.1);
%             OpenSimDocument.AnalyzeTool.final_time = num2str(5);
%             OpenSimDocument.AnalyzeTool.AnalysisSet.objects.StaticOptimization.end_time = num2str(5);
%             OpenSimDocument.AnalyzeTool.model_file = [path filename(1:end-4) '_scaled_model.osim'];
%             OpenSimDocument.AnalyzeTool.force_set_files = [path filename(1:end-4) '_SO_actuators.xml'];
%             OpenSimDocument.AnalyzeTool.results_directory = path;
%             OpenSimDocument.AnalyzeTool.external_loads_file = [path filename(1:end-4) '_grf.xml'];
%             OpenSimDocument.AnalyzeTool.coordinates_file = [path filename(1:end-4) '_ik.mot'];
%             OpenSimDocument.AnalyzeTool.ATTRIBUTE.name = [filename(1:end-4) '_' num2str(index)];%increment output of each run so as to not overwrite any data
% %             keyboard
%             xml_write([path filename(1:end-4) '_SO_setup.xml'],OpenSimDocument);
%             clear OpenSimDocument
%         else
%             disp(['some other problem has occured or it finished']);
%             stop = 1;
%         end
%         
%         index = index+1;
%     end
    
end
%}
%% JRA

% [filename,path] = uigetfiles('*.*','Select file to run JRA on:');
% if iscell(path)
%     path = path{1};
%     path = strrep(path,'\\','\'); 
% else
%     path = strrep(path,'\\','\'); 
% end

load OAfilenames.mat
load OApathnames.mat
% 

if iscell(filename)
    clc
    try
        parfor z=215:220%length(filename)
            
            path = paths{z};
            addpath(path);
            tempfname = filename{z};
            tempfname = tempfname(2:end-5)
            disp(['iteration is: ' num2str(z)]);
            disp(tempfname);
            disp(path);
            
            %check if this trial has already been JRA'ed
%             if exist([path '\' tempfname '_JointReaction_ReactionLoads.sto'],'file') == 2
%             else
                %load SO setup file to check what time points to run JRA on
                %(SO did not run for the whole 30 seconds, as per the SO
                %setup files)
                OpenSimDocument = xml_read([path '\' tempfname '_SO_setup.xml']);
                starttime = OpenSimDocument.AnalyzeTool.initial_time;
                stoptime = OpenSimDocument.AnalyzeTool.final_time;
                
                OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\JRA_setup.xml');%load generic JRA setup file
                OpenSimDocument.AnalyzeTool.ATTRIBUTE.name = tempfname;
                OpenSimDocument.AnalyzeTool.model_file = [path '\' tempfname '_scaled_model.osim'];
                OpenSimDocument.AnalyzeTool.force_set_files = [path '\' tempfname '_SO_actuators.xml'];
                OpenSimDocument.AnalyzeTool.results_directory = path;
                OpenSimDocument.AnalyzeTool.AnalysisSet.objects.JointReaction.forces_file = [path '\' tempfname '_SO_StaticOptimization_force.sto'];
                OpenSimDocument.AnalyzeTool.external_loads_file = [path '\' tempfname '_grf.xml'];
                OpenSimDocument.AnalyzeTool.coordinates_file = [path '\' tempfname '_ik.mot'];
                OpenSimDocument.AnalyzeTool.initial_time = starttime;
                OpenSimDocument.AnalyzeTool.final_time = stoptime;
                OpenSimDocument.AnalyzeTool.AnalysisSet.objects.JointReaction.start_time = starttime;
                OpenSimDocument.AnalyzeTool.AnalysisSet.objects.JointReaction.end_time = stoptime;
                xml_write([path '\' tempfname '_JRA_setup.xml'],OpenSimDocument);
                
                %         clear OpenSimDocument
                addpath('C:\OpenSim 3.2\bin');%can't pass in full path to command line, since there is a #$%@&*@ space between "OpenSim" and "3.2" in the path...idiots...
                addpath('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\');
                Command = ['analyze -S ' path '\' tempfname '_JRA_setup.xml'];
                
                system(Command);
                
                if exist([path '\' tempfname '_JointReaction_ReactionLoads.sto'],'file') == 2
                    %success
                else
                    disp(['Batch Error Simtk',tempfname, ' Has failed in JRA']);
                end
%             end
        end
    catch me
        disp('Batch Error Simtk Error has occured during JRA');
    end
else
    clc
    OpenSimDocument = xml_read('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\JRA_setup.xml');
    OpenSimDocument.AnalyzeTool.ATTRIBUTE.name = filename(1:end-4);
    OpenSimDocument.AnalyzeTool.model_file = [path filename(1:end-4) '_scaled_model.osim'];
    OpenSimDocument.AnalyzeTool.force_set_files = [path filename(1:end-4) '_SO_actuators.xml'];
    OpenSimDocument.AnalyzeTool.results_directory = path;
    OpenSimDocument.AnalyzeTool.AnalysisSet.objects.JointReaction.forces_file = [path filename(1:end-4) '_SO_StaticOptimization_force.sto'];
    OpenSimDocument.AnalyzeTool.external_loads_file = [path filename(1:end-4) '_grf.xml'];
    OpenSimDocument.AnalyzeTool.coordinates_file = [path filename(1:end-4) '_ik.mot'];
    xml_write([path filename(1:end-4) '_JRA_setup.xml'],OpenSimDocument);
    
    clear OpenSimDocument
    addpath('C:\OpenSim 3.2\bin');%can't pass in full path to command line, since there is a #$%@&*@ space between "OpenSim" and "3.2" in the path...idiots...
    addpath('C:\Users\Engineer\Desktop\Knee_OA_OpenSim\');
    Command = ['analyze -S ' filename(1:end-4) '_JRA_setup.xml'];
    system(Command);
      
    
end
%}
%% Reduce Data
% 

% clear
[filename,path] = uigetfiles('*.*','Select file to Reduce:');

temp = filename;
filename{2} = temp{4};
filename{3} = temp{2};
filename{4} = temp{5};
filename{5} = temp{3};
clear temp;
% keyboard
% load OAfilenames.mat
% load OApathnames.mat

if iscell(filename)
    
    clc
    for z = 1:length(filename)
        
        load('C:\Users\Engineer\Documents\MATLAB\massheight.mat');
        
        tempfname = filename(z);
        tempfname = tempfname{1};
        
        %figure out mass to normalize by
        [C,IA,IB] = intersect(tempfname(1:4),massheight(:,1));%figure out what the mass/height should be
        mass = cell2mat(massheight(IB,2));
        BW = mass*9.8
        
        %load knee joint loads
        s = importdata([path{z} tempfname(1:end-4) '_JointReaction_ReactionLoads.sto']);
%         s = importdata([path{z} tempfname(1:end-4) '.sto']);
        data = s.data;
        clear s
        %knee loads
        Rfx = data(:,29)./BW;%normalize by body weight (force, not mass)
        Rfy = data(:,30)./BW;
        Rfz = data(:,31)./BW;
        Rmx = data(:,32)./BW;
        Rmy = data(:,33)./BW;
        Rmz = data(:,34)./BW;
        
        Lfx = data(:,110)./BW;
        Lfy = data(:,111)./BW;
        Lfz = data(:,112)./BW;
        Lmx = data(:,113)./BW;
        Lmy = data(:,114)./BW;
        Lmz = data(:,115)./BW;
%         keyboard
        start = data(1,1);
        stop = data(end,1);
        clear data
        
        %open GRF data to determine when each gait cycle starts
        s = importdata([path{z} tempfname(1:end-4) '.mot']);
        data = s.data;
        
        [~,~,startindex] = intersect(start,data(:,1));%make sure to use data from the same time points
        [~,~,stopindex] = intersect(stop,data(:,1));
        
        Rgz = data(startindex:stopindex,3);%forceplate z directions
        Lgz = data(startindex:stopindex,9);
        for zz=1:length(Rgz)-1
            if Rgz(zz)== 0 && Rgz(zz+1) > 0
                RHS(zz) = 1;
            elseif Rgz(zz) > 0 && Rgz(zz+1) == 0
                RTO(zz) = 1;
            else
                RHS(zz) = 0;
                RTO(zz) = 0;
            end
        end
%             figure(1)
%             plot(1:length(Rgz),Rgz,1:length(RHS),RHS);
        for zz=1:length(Lgz)-1
            if Lgz(zz)== 0 && Lgz(zz+1) > 0
                LHS(zz) = 1;
            elseif Lgz(zz) > 0 && Lgz(zz+1) == 0
                LTO(zz) = 1;
            else
                LHS(zz) = 0;
                LTO(zz) = 0;
            end
        end
        
%         figure(2)
%         plot(1:length(Rgz),Rgz,1:length(RTO),RTO*10);
%         keyboard
        Rindex = find(RHS);%the indexs where HS and TO occur
        Rtindex = find(RTO);
        Lindex = find(LHS);
        Ltindex = find(LTO);
        
        if Rtindex(1) < Rindex(1)
            Rtindex(1) = [];
        end
        if Ltindex(1) < Lindex(1)
            Ltindex(1) = [];
        end
        [~,~,check1] = intersect(Rindex,Rtindex);
        Rtindex(check1) = [];
        Rindex(check1) = [];
        [~,~,check2] = intersect(Lindex,Ltindex);
        Ltindex(check2) = [];
        Lindex(check2) = [];
        
%         keyboard
        %calculate area under the curve for knee joint vertical contact
        %force during stance phase.
        
        for zz = 1:min([length(Rindex) length(Rtindex)])
            temp = Rfy(Rindex(zz):Rtindex(zz));
            figure(1)
            hold on
            plot(temp)
            temp2(zz) = simps(temp)*0.01;
            Rfyauc(z) = mean(temp2);
        end
        
        for zz = 1:min([length(Lindex) length(Ltindex)])
            temp3 = Lfy(Lindex(zz):Ltindex(zz));
%             figure(2)
% %             hold on
%             plot(temp)
            temp4(zz) = simps(temp3)*0.01;
            Lfyauc(z) = mean(temp4);
        end
        
%         Rfyauc = Rfyauc';
%         Lfyauc = Lfyauc';
        
%         clear RFX RFY RFZ RMX RMY RMZ LFX LFY LFZ LMX LMY LMZ
%         keyboard
        for zz = 1:length(Rindex)-1%normalize to % gait cycle
            
            RFX{zz} = interp1(linspace(0,1,length(Rfx(Rindex(zz):Rindex(zz+1)))),Rfx(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            RFY{zz} = interp1(linspace(0,1,length(Rfy(Rindex(zz):Rindex(zz+1)))),Rfy(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            RFZ{zz} = interp1(linspace(0,1,length(Rfz(Rindex(zz):Rindex(zz+1)))),Rfz(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            RMX{zz} = interp1(linspace(0,1,length(Rmx(Rindex(zz):Rindex(zz+1)))),Rmx(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            RMY{zz} = interp1(linspace(0,1,length(Rmy(Rindex(zz):Rindex(zz+1)))),Rmy(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            RMZ{zz} = interp1(linspace(0,1,length(Rmz(Rindex(zz):Rindex(zz+1)))),Rmz(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            
        end
        
        RFX = cell2mat(RFX);
        RFY = cell2mat(RFY);
        RFZ = cell2mat(RFZ);
        RMX = cell2mat(RMX);
        RMY = cell2mat(RMY);
        RMZ = cell2mat(RMZ);
        
        for zz = 1:length(Lindex)-1
            
            LFX{zz} = interp1(linspace(0,1,length(Lfx(Lindex(zz):Lindex(zz+1)))),Lfx(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            LFY{zz} = interp1(linspace(0,1,length(Lfy(Lindex(zz):Lindex(zz+1)))),Lfy(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            LFZ{zz} = interp1(linspace(0,1,length(Lfz(Lindex(zz):Lindex(zz+1)))),Lfz(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            LMX{zz} = interp1(linspace(0,1,length(Lmx(Lindex(zz):Lindex(zz+1)))),Lmx(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            LMY{zz} = interp1(linspace(0,1,length(Lmy(Lindex(zz):Lindex(zz+1)))),Lmy(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            LMZ{zz} = interp1(linspace(0,1,length(Lmz(Lindex(zz):Lindex(zz+1)))),Lmz(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            
        end
        
        LFX = cell2mat(LFX);
        LFY = cell2mat(LFY);
        LFZ = cell2mat(LFZ);
        LMX = cell2mat(LMX);
        LMY = cell2mat(LMY);
        LMZ = cell2mat(LMZ);
%         keyboard
        %take averages of curves
        RFXmean{z} = nanmean(RFX,2);
        RFYmean{z} = nanmean(RFY,2);
        RFZmean{z} = nanmean(RFZ,2);
        Rabdmean{z} = nanmean(RMX,2);%abd axis moment
        Rrotmean{z} = nanmean(RMY,2);%axial rot moment
        Rflexmean{z} = nanmean(RMZ,2);%flex moment
        LFXmean{z} = nanmean(LFX,2);
        LFYmean{z} = nanmean(LFY,2);
        LFZmean{z} = nanmean(LFZ,2).*-1;
        Labdmean{z} = nanmean(LMX,2).*-1;
        Lrotmean{z} = nanmean(LMY,2).*-1;
        Lflexmean{z} = nanmean(LMZ,2);
        
        % Find key indicators for vertical knee contact load
        for zz = 1:length(Rindex)-1
            tempry = RFY(:,zz);
            RY1(zz) = min(tempry(1:20));%first peak
            RY2(zz) = min(tempry(21:60));%second peak
        end
        for zz = 1:length(Lindex)-1
            temply = LFY(:,zz);
            LY1(zz) = min(temply(1:20));
            LY2(zz) = min(temply(21:60));
        end
        
        %Find key indicators for knee flexion moment
        for zz = 1:length(Rindex)-1
           temprmz = RMZ(:,zz);
           RFlex1(zz) = max(temprmz(1:30));
           RFlex2(zz) = max(temprmz(31:60));
        end
        for zz = 1:length(Lindex)-1
           templmz = LMZ(:,zz);
           LFlex1(zz) = max(templmz(1:30));
           LFlex2(zz) = max(templmz(31:60));
        end
        
        %Find key indicators for knee ABD moment
        for zz = 1:length(Rindex)-1
            temprmx = RMX(:,zz);
            RAbd1(zz) = min(temprmx(1:30));
            RAbd2(zz) = min(temprmx(45:60));
        end
        for zz = 1:length(Lindex)-1
            templmx = LMX(:,zz);
            LAbd1(zz) = min(templmx(1:30));
            LAbd2(zz) = min(templmx(45:60));
        end
        
        %find key indicators for knee flexion kinematics
        %load kinematics file
%         s = importdata([path{z} tempfname(1:end-4) '_ik.mot']);
%         data = s.data;
%         clear s
%         rflexion = data(startindex:stopindex,11);
%         lflexion = data(startindex:stopindex,19);
%         
%         for zz = 1:length(Rindex)-1
%             rflex{zz} = interp1(linspace(0,1,length(rflexion(Rindex(zz):Rindex(zz+1)))),rflexion(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
%         end
%         for zz = 1:length(Lindex)-1
%             lflex{zz} = interp1(linspace(0,1,length(lflexion(Lindex(zz):Lindex(zz+1)))),lflexion(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
%         end
%         
%         %get key indicators
%         for zz = 1:length(Rindex)-1
%            temprflex = rflex{zz};
%            RK1(zz) = temprflex(1);
%            RK2(zz) = max(temprflex(1:35));
%            RK3(zz) = min(temprflex(21:60));
%         end
%         for zz = 1:length(Lindex)-1
%            templflex = lflex{zz};
%            LK1(zz) = templflex(1);
%            LK2(zz) = max(templflex(1:35));
%            LK3(zz) = min(templflex(21:61));
%         end
%         
%         %compute means of indicators and store them
%         RY1mean{z} = nanmean(RY1);
%         RY2mean{z} = nanmean(RY2);
%         RFlex1mean{z} = nanmean(RFlex1);
%         RFlex2mean{z} = nanmean(RFlex2);
%         RAbd1mean{z} = nanmean(RAbd1);
%         RAbd2mean{z} = nanmean(RAbd2);
%         RK1mean{z} = nanmean(RK1);
%         RK2mean{z} = nanmean(RK2);
%         RK3mean{z} = nanmean(RK3);
%         
%         LY1mean{z} = nanmean(LY1);
%         LY2mean{z} = nanmean(LY2);
%         LFlex1mean{z} = nanmean(LFlex1);
%         LFlex2mean{z} = nanmean(LFlex2);
%         LAbd1mean{z} = nanmean(LAbd1);
%         LAbd2mean{z} = nanmean(LAbd2);
%         LK1mean{z} = nanmean(LK1);
%         LK2mean{z} = nanmean(LK2);
%         LK3mean{z} = nanmean(LK3);
        
        
        clear RFX RFY RFZ RMX RMY RMZ LFX LFY LFZ LMX LMY LMZ
        clear RY1 RY2 RFlex1 RFlex2 RAbd1 RAbd2 RK1 RK2 RK3 LY1 LY2 LFlex1 LFlex2 LAbd1 LAbd2 LK1 LK2 LK3
    end
    
        
%         %write to designated files
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Fx.xlsm',RFXmean,LFXmean);
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Fy.xlsm',RFYmean,LFYmean);
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Fz.xlsm',RFZmean,LFZmean);
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Abd.xlsm',Rabdmean,Labdmean);
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Rot.xlsm',Rrotmean,Lrotmean);
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Flex.xlsm',Rflexmean,Lflexmean);
        
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Fx_Day2.xlsm',RFXmean,LFXmean);
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Fy_Day2.xlsm',RFYmean,LFYmean);
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Fz_Day2.xlsm',RFZmean,LFZmean);
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Abd_Day2.xlsm',Rabdmean,Labdmean);
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Rot_Day2.xlsm',Rrotmean,Lrotmean);
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_Flex_Day2.xlsm',Rflexmean,Lflexmean);
        
        %write indicators Day 1
%         OpenSim_kneekinematics_D1(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_kinematic_indicators_day1.xlsm',RK1mean,RK2mean,RK3mean,LK1mean,LK2mean,LK3mean);
%         OpenSim_JRA_indicators_D1(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_JRA_indicators_day1.xlsm',RY1mean,RY2mean,RFlex1mean,RFlex2mean,RAbd1mean,RAbd2mean,LY1mean,LY2mean,LFlex1mean,LFlex2mean,LAbd1mean,LAbd2mean);
        
        %write indicators Day 2
%         OpenSim_kneekinematics_D2(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_kinematic_indicators_day2.xlsm',RK1mean,RK2mean,RK3mean,LK1mean,LK2mean,LK3mean);
%         OpenSim_JRA_indicators_D2(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_JRA_indicators_day2.xlsm',RY1mean,RY2mean,RFlex1mean,RFlex2mean,RAbd1mean,RAbd2mean,LY1mean,LY2mean,LFlex1mean,LFlex2mean,LAbd1mean,LAbd2mean);
        
        
        
        %write to xls
%         xlswrite(RFXmean,'right force X');
%         xlswrite(RFYmean,'right force Y');
%         xlswrite(RFZmean,'right force Z');
%         xlswrite(Rabdmean,'R abd');
%         xlswrite(Rrotmean,'R rot');
%         xlswrite(Rflexmean,'R flex');
%         xlswrite(LFXmean,'left force X');
%         xlswrite(LFYmean,'left force Y');
%         xlswrite(LFZmean,'left force Z');
%         xlswrite(Labdmean,'L abd');
%         xlswrite(Lrotmean,'L rot');
%         xlswrite(Lflexmean,'L flex');
    
else
    clc
    mass = 85.45;
    height = 194.5;
    BW = mass*9.8;
    %load knee joint loads
    s = importdata([path filename(1:end-4) '_JointReaction_ReactionLoads.sto']);
    data = s.data;
    clear s
    %knee loads
    Rfx = data(:,29)./BW;
    Rfy = data(:,30)./BW;
    Rfz = data(:,31)./BW;
    Rmx = data(:,32)./BW;
    Rmy = data(:,33)./BW;
    Rmz = data(:,34)./BW;
    
    Lfx = data(:,110)./BW;
    Lfy = data(:,111)./BW;
    Lfz = data(:,112)./BW;
    Lmx = data(:,113)./BW;
    Lmy = data(:,114)./BW;
    Lmz = data(:,115)./BW;
    keyboard
    start = data(1,1);
    stop = data(end,1);
    clear data
    
    %open GRF data to determine when each gait cycle starts
    s = importdata([path filename(1:end-4) '.mot']);
    data = s.data;
    
    [~,~,startindex] = intersect(start,data(:,1));
    [~,~,stopindex] = intersect(stop,data(:,1));
    
    Rgz = data(startindex:stopindex,3);
    Lgz = data(startindex:stopindex,9);
    
    for z=1:length(Rgz)-1
        if Rgz(z)== 0 && Rgz(z+1) > 0
            RHS(z) = 1;
        else
            RHS(z) = 0;
        end
    end
%     figure(1)
%     plot(1:length(Rgz),Rgz,1:length(RHS),RHS);
    for z=1:length(Lgz)-1
        if Lgz(z)== 0 && Lgz(z+1) > 0
            LHS(z) = 1;
        else
            LHS(z) = 0;
        end
    end
    
    Rindex = find(RHS);
    Lindex = find(LHS);
    
    for z = 1:length(Rindex)-1
        
        RFX{z} = interp1(linspace(0,1,length(Rfx(Rindex(z):Rindex(z+1)))),Rfx(Rindex(z):Rindex(z+1)),linspace(0,1,101))';
        RFY{z} = interp1(linspace(0,1,length(Rfy(Rindex(z):Rindex(z+1)))),Rfy(Rindex(z):Rindex(z+1)),linspace(0,1,101))';
        RFZ{z} = interp1(linspace(0,1,length(Rfz(Rindex(z):Rindex(z+1)))),Rfz(Rindex(z):Rindex(z+1)),linspace(0,1,101))';
        RMX{z} = interp1(linspace(0,1,length(Rmx(Rindex(z):Rindex(z+1)))),Rmx(Rindex(z):Rindex(z+1)),linspace(0,1,101))';
        RMY{z} = interp1(linspace(0,1,length(Rmy(Rindex(z):Rindex(z+1)))),Rmy(Rindex(z):Rindex(z+1)),linspace(0,1,101))';
        RMZ{z} = interp1(linspace(0,1,length(Rmz(Rindex(z):Rindex(z+1)))),Rmz(Rindex(z):Rindex(z+1)),linspace(0,1,101))';
    
    end

    RFX = cell2mat(RFX);
    RFY = cell2mat(RFY);
    RFZ = cell2mat(RFZ);
    RMX = cell2mat(RMX);
    RMY = cell2mat(RMY);
    RMZ = cell2mat(RMZ);
    
    for z = 1:length(Lindex)-1
        
        LFX{z} = interp1(linspace(0,1,length(Lfx(Lindex(z):Lindex(z+1)))),Lfx(Lindex(z):Lindex(z+1)),linspace(0,1,101))';
        LFY{z} = interp1(linspace(0,1,length(Lfy(Lindex(z):Lindex(z+1)))),Lfy(Lindex(z):Lindex(z+1)),linspace(0,1,101))';
        LFZ{z} = interp1(linspace(0,1,length(Lfz(Lindex(z):Lindex(z+1)))),Lfz(Lindex(z):Lindex(z+1)),linspace(0,1,101))';
        LMX{z} = interp1(linspace(0,1,length(Lmx(Lindex(z):Lindex(z+1)))),Lmx(Lindex(z):Lindex(z+1)),linspace(0,1,101))';
        LMY{z} = interp1(linspace(0,1,length(Lmy(Lindex(z):Lindex(z+1)))),Lmy(Lindex(z):Lindex(z+1)),linspace(0,1,101))';
        LMZ{z} = interp1(linspace(0,1,length(Lmz(Lindex(z):Lindex(z+1)))),Lmz(Lindex(z):Lindex(z+1)),linspace(0,1,101))';
    
    end

    LFX = cell2mat(LFX);
    LFY = cell2mat(LFY);
    LFZ = cell2mat(LFZ);
    LMX = cell2mat(LMX);
    LMY = cell2mat(LMY);
    LMZ = cell2mat(LMZ);
    
    %take averages
    RFXmean = nanmean(RFX,2);
    RFYmean = nanmean(RFY,2);
    RFZmean = nanmean(RFZ,2);
    Rabdmean = nanmean(RMX,2);%abd axis moment
    Rrotmean = nanmean(RMY,2);%axial rot moment
    Rflexmean = nanmean(RMZ,2);%flex moment
    LFXmean = nanmean(LFX,2);
    LFYmean = nanmean(LFY,2);
    LFZmean = nanmean(LFZ,2);
    Labdmean = nanmean(LMX,2);
    Lrotmean = nanmean(LMY,2);
    Lflexmean = nanmean(LMZ,2);
    
    %now calculate key indicators
%     Rkm1 = 
    
    
    
end
%}
%% SO Residuals Analysis
%{
%this section collects residual forces used in static optimization (an idea
%of how good or bad the muscles are able to drive the model without help)
clc
clear
[filename,path] = uigetfiles('*.*','Select file to Reduce:');
path = path{1};
temp = filename;
filename{2} = temp{4};
filename{3} = temp{2};
filename{4} = temp{5};
filename{5} = temp{3};
clear temp;
% load OAfilenames_excel_day1.mat
% load OApathnames_day1.mat

if iscell(filename)
    
    for z=1:length(filename)
        
        load('C:\Users\Engineer\Documents\MATLAB\massheight.mat');
        

%         addpath(path);
        tempfname = filename{z};
%         tempfname = tempfname{1};
%         keyboard
        %figure out mass to normalize by
        [C,IA,IB] = intersect(tempfname(1:4),massheight(:,1));%figure out what the mass/height should be
        mass = cell2mat(massheight(IB,2));
        BW = mass*9.8;
        
        %load knee joint loads
        s = importdata([path tempfname(1:end-4) '_SO_StaticOptimization_force.sto']);
        data = s.data;
        clear s

        FX = data(:,98)./BW;
        FY = data(:,99)./BW;
        FZ = data(:,100)./BW;
        MX = data(:,101)./BW;
        MY = data(:,102)./BW;
        MZ = data(:,103)./BW;
        
        start = data(1,1);
        stop = data(end,1);
        clear data
        
        %open GRF data to determine when each gait cycle starts
        s = importdata([path tempfname(1:end-4) '.mot']);
        data = s.data;
        %
        [~,~,startindex] = intersect(start,data(:,1));
        [~,~,stopindex] = intersect(stop,data(:,1));
        
        Rgz = data(startindex:stopindex,3);
        Lgz = data(startindex:stopindex,9);
%         keyboard
        for u=1:length(Rgz)-1
            if Rgz(u)== 0 && Rgz(u+1) > 0
                RHS(u) = 1;
            else
                RHS(u) = 0;
            end
        end
%         figure(1)
%         plot(1:length(Rgz),Rgz,1:length(RHS),RHS);
        for u=1:length(Lgz)-1
            if Lgz(u)== 0 && Lgz(u+1) > 0
                LHS(u) = 1;
            else
                LHS(u) = 0;
            end
        end
        
        Rindex = find(RHS);
%         Lindex = find(LHS);
%         keyboard
        for zz = 1:length(Rindex)-1
            
            tempx{zz} = interp1(linspace(0,1,length(FX(Rindex(zz):Rindex(zz+1)))),FX(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            tempy{zz} = interp1(linspace(0,1,length(FY(Rindex(zz):Rindex(zz+1)))),FY(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            tempz{zz} = interp1(linspace(0,1,length(FZ(Rindex(zz):Rindex(zz+1)))),FZ(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            tempmx{zz} = interp1(linspace(0,1,length(MX(Rindex(zz):Rindex(zz+1)))),MX(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            tempmy{zz} = interp1(linspace(0,1,length(MY(Rindex(zz):Rindex(zz+1)))),MY(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            tempmz{zz} = interp1(linspace(0,1,length(MZ(Rindex(zz):Rindex(zz+1)))),MZ(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            
        end
%         clear FX FY FZ MX MY MZ Rindex
        
%         keyboard
        ffx = cell2mat(tempx);
        ffy = cell2mat(tempy);
        ffz = cell2mat(tempz);
        mmx = cell2mat(tempmx);
        mmy = cell2mat(tempmy);
        mmz = cell2mat(tempmz);
        
%         clear tempx tempy tempz tempmx tempmy tempmz
%         keyboard
        FXmean{z} = nanmean(ffx,2);
        FYmean{z} = nanmean(ffy,2);
        FZmean{z} = nanmean(ffz,2);
        FMXmean{z} = nanmean(mmx,2);
        FMYmean{z} = nanmean(mmy,2);
        FMZmean{z} = nanmean(mmz,2);
        
%         clear ffx ffy ffz mmx mmy mmz
    end
            %         %write to designated files
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FX.xlsm',FXmean,FXmean);
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FY.xlsm',FYmean,FXmean);
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FZ.xlsm',FZmean,FXmean);
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMX.xlsm',FMXmean,FXmean);
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMY.xlsm',FMYmean,FXmean);
%         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMZ.xlsm',FMZmean,FXmean);
        
        curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FX_D2.xlsm',FXmean,FXmean);
        curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FY_D2.xlsm',FYmean,FXmean);
        curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FZ_D2.xlsm',FZmean,FXmean);
        curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMX_D2.xlsm',FMXmean,FXmean);
        curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMY_D2.xlsm',FMYmean,FXmean);
        curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMZ_D2.xlsm',FMZmean,FXmean);
        
    
    
else
    
    
    
end
%}
%% SO Activations Reduction 
%{
%this section collects muscle activations used in static optimization to
%compare with emg validation
clc
clear
[filename,path] = uigetfiles('*.*','Select file to Reduce:');
path = path{1};
% temp = filename;
% filename{2} = temp{4};
% filename{3} = temp{2};
% filename{4} = temp{5};
% filename{5} = temp{3};
% clear temp;
% load OAfilenames_excel_day1.mat
% load OApathnames_day1.mat

if iscell(filename)
    
    for z=1:length(filename)
        
        load('C:\Users\Engineer\Documents\MATLAB\massheight.mat');
        

%         addpath(path);
        tempfname = filename{z};
%         tempfname = tempfname{1};
%         keyboard
        %figure out mass to normalize by
        [C,IA,IB] = intersect(tempfname(1:4),massheight(:,1));%figure out what the mass/height should be
        mass = cell2mat(massheight(IB,2));
        BW = mass*9.8;
        
        %load knee joint loads
        s = importdata([path tempfname(1:end-4) '_SO_StaticOptimization_activation.sto']);
        data = s.data;
        clear s

        mgast = data(:,15);%med gast
        lgast = data(:,14);%lat gast
        mham = data(:,39);%semitendinosus
        lham = data(:,8);%long head biceps femoris
        mquad = data(:,46);%med vast
        lquad = data(:,45);%lat vast
%         
        start = data(1,1);
        stop = data(end,1);
        clear data
%         
        %open GRF data to determine when each gait cycle starts
        s = importdata([path tempfname(1:end-4) '.mot']);
        data = s.data;
        %
        [~,~,startindex] = intersect(start,data(:,1));
        [~,~,stopindex] = intersect(stop,data(:,1));
        
        Rgz = data(startindex:stopindex,3);
        Lgz = data(startindex:stopindex,9);
%         keyboard
        for u=1:length(Rgz)-1
            if Rgz(u)== 0 && Rgz(u+1) > 0
                RHS(u) = 1;
            else
                RHS(u) = 0;
            end
        end
%         figure(1)
%         plot(1:length(Rgz),Rgz,1:length(RHS),RHS);
        for u=1:length(Lgz)-1
            if Lgz(u)== 0 && Lgz(u+1) > 0
                LHS(u) = 1;
            else
                LHS(u) = 0;
            end
        end
%         
        Rindex = find(RHS);
%         Lindex = find(LHS);
%         keyboard
        for zz = 1:length(Rindex)-1
%             
            tempx{zz} = interp1(linspace(0,1,length(mgast(Rindex(zz):Rindex(zz+1)))),mgast(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            tempy{zz} = interp1(linspace(0,1,length(lgast(Rindex(zz):Rindex(zz+1)))),lgast(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            tempz{zz} = interp1(linspace(0,1,length(mham(Rindex(zz):Rindex(zz+1)))),mham(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            tempmx{zz} = interp1(linspace(0,1,length(lham(Rindex(zz):Rindex(zz+1)))),lham(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            tempmy{zz} = interp1(linspace(0,1,length(mquad(Rindex(zz):Rindex(zz+1)))),mquad(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            tempmz{zz} = interp1(linspace(0,1,length(lquad(Rindex(zz):Rindex(zz+1)))),lquad(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
%             
        end
% %         clear FX FY FZ MX MY MZ Rindex
%         
% %         keyboard
        mgastr = cell2mat(tempx);
        lgastr = cell2mat(tempy);
        mhamr = cell2mat(tempz);
        lhamr = cell2mat(tempmx);
        mquadr = cell2mat(tempmy);
        lquadr = cell2mat(tempmz);
%         
        clear tempx tempy tempz tempmx tempmy tempmz
% %         keyboard
        mgastmean = nanmean(mgastr,2);
        lgastmean = nanmean(lgastr,2);
        mhammean = nanmean(mhamr,2);
        lhammean = nanmean(lhamr,2);
        mquadmean = nanmean(mquadr,2);
        lquadmean = nanmean(lquadr,2);
%         
% %         clear ffx ffy ffz mmx mmy mmz
    end
%             %         %write to designated files
% %         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FX.xlsm',FXmean,FXmean);
% %         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FY.xlsm',FYmean,FXmean);
% %         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FZ.xlsm',FZmean,FXmean);
% %         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMX.xlsm',FMXmean,FXmean);
% %         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMY.xlsm',FMYmean,FXmean);
% %         curves2excelD1_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMZ.xlsm',FMZmean,FXmean);
%         
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FX_D2.xlsm',FXmean,FXmean);
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FY_D2.xlsm',FYmean,FXmean);
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FZ_D2.xlsm',FZmean,FXmean);
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMX_D2.xlsm',FMXmean,FXmean);
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMY_D2.xlsm',FMYmean,FXmean);
%         curves2excelD2_Fx(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\SO Residuals\FMZ_D2.xlsm',FMZmean,FXmean);
        
    
    
else
    
    
    
end
%}
%% Inverse Dynamics
%we never got around to doing ID...

%computes external loads on each joint
load OAfilenames.mat
load OApathnames.mat

if iscell(filename)
    clc
    try
        parfor z =1:1%length(filename)
            path = paths{z};
            addpath(path);
            tempfname = filename{z};
            tempfname = tempfname(2:end-5)
            disp(['iteration is: ' num2str(z)]);
            disp(tempfname);
            disp(path);
            
            
        end
    catch 
        
    end
    
end
%}
%% Reduce Muscle Contribution
%seeks to sum the major muscles' force crossing the knee joint during
%stance phase.
%{
[filename,path] = uigetfiles('*.*','Select file to Reduce:');
temp = filename;
filename{2} = temp{4};
filename{3} = temp{2};
filename{4} = temp{5};
filename{5} = temp{3};
clear temp;
% keyboard
% load OAfilenames.mat
% load OApathnames.mat

if iscell(filename)
    
    for z = 1:length(filename)
        
        load('C:\Users\Engineer\Documents\MATLAB\massheight.mat');
        
        tempfname = filename(z);
        tempfname = tempfname{1};
        
        %figure out mass to normalize by
        [C,IA,IB] = intersect(tempfname(1:4),massheight(:,1));%figure out what the mass/height should be
        mass = cell2mat(massheight(IB,2));
        BW = mass*9.8
        
        %load knee joint loads
        s = importdata([path{z} tempfname(1:end-4) '_SO_StaticOptimization_force.sto']);
%         s = importdata([path{z} tempfname(1:end-4) '.sto']);
        data = s.data;
        clear s
        
        bflh_r = data(:,8)./BW;
        bfsh_r = data(:,9)./BW;
        semit_r = data(:,39)./BW;
        semim_r = data(:,38)./BW;
        grac_r = data(:,26)./BW;
        tfl_r = data(:,41)./BW;
        
        gaslat_r = data(:,14)./BW;
        gasmed_r = data(:,15)./BW;
        
        recfem_r = data(:,36)./BW;
        vasint_r = data(:,44)./BW;
        vasmed_r = data(:,46)./BW;
        vaslat_r = data(:,45)./BW;
        
        bflh_l = data(:,53)./BW;
        bfsh_l = data(:,54)./BW;
        semit_l = data(:,84)./BW;
        semim_l = data(:,83)./BW;
        grac_l = data(:,71)./BW;
        tfl_l = data(:,86)./BW;
        
        gaslat_l = data(:,59)./BW;
        gasmed_l = data(:,60)./BW;
        
        recfem_l = data(:,81)./BW;
        vasint_l = data(:,89)./BW;
        vasmed_l = data(:,91)./BW;
        vaslat_l = data(:,90)./BW;
        
        start = data(1,1);
        stop = data(end,1);
        clear data
        
        %open GRF data to determine when each gait cycle starts
        s = importdata([path{z} tempfname(1:end-4) '.mot']);
        data = s.data;
        
        [~,~,startindex] = intersect(start,data(:,1));%make sure to use data from the same time points
        [~,~,stopindex] = intersect(stop,data(:,1));
        
        Rgz = data(startindex:stopindex,3);%forceplate z directions
        Lgz = data(startindex:stopindex,9);
        for zz=1:length(Rgz)-1
            if Rgz(zz)== 0 && Rgz(zz+1) > 0
                RHS(zz) = 1;
            elseif Rgz(zz) > 0 && Rgz(zz+1) == 0
                RTO(zz) = 1;
            else
                RHS(zz) = 0;
                RTO(zz) = 0;
            end
        end
%             figure(1)
%             plot(1:length(Rgz),Rgz,1:length(RHS),RHS);
        for zz=1:length(Lgz)-1
            if Lgz(zz)== 0 && Lgz(zz+1) > 0
                LHS(zz) = 1;
            elseif Lgz(zz) > 0 && Lgz(zz+1) == 0
                LTO(zz) = 1;
            else
                LHS(zz) = 0;
                LTO(zz) = 0;
            end
        end
        
%         figure(2)
%         plot(1:length(Rgz),Rgz,1:length(RTO),RTO*10);
%         keyboard
        Rindex = find(RHS);
        Rtindex = find(RTO);
        Lindex = find(LHS);
        Ltindex = find(LTO);
        
        if Rtindex(1) < Rindex(1)
            Rtindex(1) = [];
        end
        if Ltindex(1) < Lindex(1)
            Ltindex(1) = [];
        end
        [~,~,check1] = intersect(Rindex,Rtindex);
        Rtindex(check1) = [];
        Rindex(check1) = [];
        [~,~,check2] = intersect(Lindex,Ltindex);
        Ltindex(check2) = [];
        Lindex(check2) = [];
        
        for zz = 1:length(Rindex)-1
            
            BLH_r{zz} = interp1(linspace(0,1,length(bflh_r(Rindex(zz):Rindex(zz+1)))),bflh_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            BSH_r{zz} = interp1(linspace(0,1,length(bfsh_r(Rindex(zz):Rindex(zz+1)))),bfsh_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            ST_r{zz} = interp1(linspace(0,1,length(semit_r(Rindex(zz):Rindex(zz+1)))),semit_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            SM_r{zz} = interp1(linspace(0,1,length(semim_r(Rindex(zz):Rindex(zz+1)))),semim_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            GC_r{zz} = interp1(linspace(0,1,length(grac_r(Rindex(zz):Rindex(zz+1)))),grac_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            TFL_r{zz} = interp1(linspace(0,1,length(tfl_r(Rindex(zz):Rindex(zz+1)))),tfl_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            MG_r{zz} = interp1(linspace(0,1,length(gasmed_r(Rindex(zz):Rindex(zz+1)))),gasmed_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            LG_r{zz} = interp1(linspace(0,1,length(gaslat_r(Rindex(zz):Rindex(zz+1)))),gaslat_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            RF_r{zz} = interp1(linspace(0,1,length(recfem_r(Rindex(zz):Rindex(zz+1)))),recfem_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            VI_r{zz} = interp1(linspace(0,1,length(vasint_r(Rindex(zz):Rindex(zz+1)))),vasint_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            VM_r{zz} = interp1(linspace(0,1,length(vasmed_r(Rindex(zz):Rindex(zz+1)))),vasmed_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            VL_r{zz} = interp1(linspace(0,1,length(vaslat_r(Rindex(zz):Rindex(zz+1)))),vaslat_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            
        end
        
        for zz = 1:length(Lindex)-1
            
            BLH_l{zz} = interp1(linspace(0,1,length(bflh_l(Lindex(zz):Lindex(zz+1)))),bflh_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            BSH_l{zz} = interp1(linspace(0,1,length(bfsh_l(Lindex(zz):Lindex(zz+1)))),bfsh_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            ST_l{zz} = interp1(linspace(0,1,length(semit_l(Lindex(zz):Lindex(zz+1)))),semit_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            SM_l{zz} = interp1(linspace(0,1,length(semim_l(Lindex(zz):Lindex(zz+1)))),semim_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            GC_l{zz} = interp1(linspace(0,1,length(grac_l(Lindex(zz):Lindex(zz+1)))),grac_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            TFL_l{zz} = interp1(linspace(0,1,length(tfl_l(Lindex(zz):Lindex(zz+1)))),tfl_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            MG_l{zz} = interp1(linspace(0,1,length(gasmed_l(Lindex(zz):Lindex(zz+1)))),gasmed_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            LG_l{zz} = interp1(linspace(0,1,length(gaslat_l(Lindex(zz):Lindex(zz+1)))),gaslat_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            RF_l{zz} = interp1(linspace(0,1,length(recfem_l(Lindex(zz):Lindex(zz+1)))),recfem_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            VI_l{zz} = interp1(linspace(0,1,length(vasint_l(Lindex(zz):Lindex(zz+1)))),vasint_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            VM_l{zz} = interp1(linspace(0,1,length(vasmed_l(Lindex(zz):Lindex(zz+1)))),vasmed_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            VL_l{zz} = interp1(linspace(0,1,length(vaslat_l(Lindex(zz):Lindex(zz+1)))),vaslat_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            
        end
        
        BLH_r = cell2mat(BLH_r);
        BSH_r = cell2mat(BSH_r);
        ST_r = cell2mat(ST_r);
        SM_r = cell2mat(SM_r);
        GC_r = cell2mat(GC_r);
        TFL_r = cell2mat(TFL_r);
        MG_r = cell2mat(MG_r);
        LG_r = cell2mat(LG_r);
        RF_r = cell2mat(RF_r);
        VI_r = cell2mat(VI_r);
        VM_r = cell2mat(VM_r);
        VL_r = cell2mat(VL_r);
        
        BLH_l = cell2mat(BLH_l);
        BSH_l = cell2mat(BSH_l);
        ST_l = cell2mat(ST_l);
        SM_l = cell2mat(SM_l);
        GC_l = cell2mat(GC_l);
        TFL_l = cell2mat(TFL_l);
        MG_l = cell2mat(MG_l);
        LG_l = cell2mat(LG_l);
        RF_l = cell2mat(RF_l);
        VI_l = cell2mat(VI_l);
        VM_l = cell2mat(VM_l);
        VL_l = cell2mat(VL_l);
        
        BLHRmean(:,z) = mean(BLH_r,2);
        BSHRmean(:,z) = mean(BSH_r,2);
        STRmean(:,z) = mean(ST_r,2);
        SMRmean(:,z) = mean(SM_r,2);
        GCRmean(:,z) = mean(GC_r,2);
        TFLRmean(:,z) = mean(TFL_r,2);
        MGRmean(:,z) = mean(MG_r,2);
        LGRmean(:,z) = mean(LG_r,2);
        RFRmean(:,z) = mean(RF_r,2);
        VIRmean(:,z) = mean(VI_r,2);
        VMRmean(:,z) = mean(VM_r,2);
        VLRmean(:,z) = mean(VL_r,2);
        
        
        BLHLmean(:,z) = mean(BLH_l,2);
        BSHLmean(:,z) = mean(BSH_l,2);
        STLmean(:,z) = mean(ST_l,2);
        SMLmean(:,z) = mean(SM_l,2);
        GCLmean(:,z) = mean(GC_l,2);
        TFLLmean(:,z) = mean(TFL_l,2);
        MGLmean(:,z) = mean(MG_l,2);
        LGLmean(:,z) = mean(LG_l,2);
        RFLmean(:,z) = mean(RF_l,2);
        VILmean(:,z) = mean(VI_l,2);
        VMLmean(:,z) = mean(VM_l,2);
        VLLmean(:,z) = mean(VL_l,2);
        
        TotalR(:,z) = BLHRmean(:,z)+BSHRmean(:,z)+STRmean(:,z)+SMRmean(:,z)+GCRmean(:,z)+TFLRmean(:,z)+MGRmean(:,z)+LGRmean(:,z)+RFRmean(:,z)+VIRmean(:,z)+VMRmean(:,z)+VLRmean(:,z);
        TotalL(:,z) = BLHLmean(:,z)+BSHLmean(:,z)+STLmean(:,z)+SMLmean(:,z)+GCLmean(:,z)+TFLLmean(:,z)+MGLmean(:,z)+LGLmean(:,z)+RFLmean(:,z)+VILmean(:,z)+VMLmean(:,z)+VLLmean(:,z);
        
        clear BLH_r BSH_r ST_r SM_r GC_r TFL_r MG_r LG_r RF_r VI_r VM_r VL_r BLH_l BSH_l ST_l SM_l GC_l TFL_l MG_l LG_l RF_l VI_l VM_l VL_l
        
        
        
    end
    
%     curves2excelD1_M(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_MuscleContribs_D1.xlsm',[BLHRmean BSHRmean STRmean SMRmean GCRmean TFLRmean MGRmean LGRmean RFRmean VIRmean VMRmean VLRmean TotalR],[BLHLmean BSHLmean STLmean SMLmean GCLmean TFLLmean MGLmean LGLmean RFLmean VILmean VMLmean VLLmean TotalL]);
    curves2excelD1_M(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\Knee_MuscleContribs_D2.xlsm',[BLHRmean BSHRmean STRmean SMRmean GCRmean TFLRmean MGRmean LGRmean RFRmean VIRmean VMRmean VLRmean TotalR],[BLHLmean BSHLmean STLmean SMLmean GCLmean TFLLmean MGLmean LGLmean RFLmean VILmean VMLmean VLLmean TotalL]);
else
    
end
%}
%% Reduce 3 peaks, JCF, Muscle, and GRF
% clear
%{
[filename,path] = uigetfiles('*.*','Select file to Reduce:');

% temp = filename;
% filename{2} = temp{4};
% filename{3} = temp{2};
% filename{4} = temp{5};
% filename{5} = temp{3};
% clear temp;
% keyboard
% load OAfilenames.mat
% load OApathnames.mat

if iscell(filename)
    
    clc
    for z = 1:length(filename)
        
        load('C:\Users\Engineer\Documents\MATLAB\massheight.mat');
        
        tempfname = filename(z);
        tempfname = tempfname{1};
        
        %figure out mass to normalize by
        [C,IA,IB] = intersect(tempfname(1:4),massheight(:,1));%figure out what the mass/height should be
        mass = cell2mat(massheight(IB,2));
        BW = mass*9.8
        
        %load knee joint loads
        s = importdata([path{z} tempfname(1:end-4) '_JointReaction_ReactionLoads.sto']);
%         s = importdata([path{z} tempfname(1:end-4) '.sto']);
        data = s.data;
        clear s
        %knee loads

        Rfy = data(:,30)./BW;
        Lfy = data(:,111)./BW;
%         Lfy(Lfy < 10) = 0;

%         keyboard
        start = data(1,1);
        stop = data(end,1);
        clear data
        
        %load knee joint loads
        s = importdata([path{z} tempfname(1:end-4) '_SO_StaticOptimization_force.sto']);
        data = s.data;
        clear s
        
        bflh_r = data(:,8)./BW;
        bfsh_r = data(:,9)./BW;
        semit_r = data(:,39)./BW;
        semim_r = data(:,38)./BW;
        grac_r = data(:,26)./BW;
        tfl_r = data(:,41)./BW;
        
        gaslat_r = data(:,14)./BW;
        gasmed_r = data(:,15)./BW;
        
        recfem_r = data(:,36)./BW;
        vasint_r = data(:,44)./BW;
        vasmed_r = data(:,46)./BW;
        vaslat_r = data(:,45)./BW;
        
        bflh_l = data(:,53)./BW;
        bfsh_l = data(:,54)./BW;
        semit_l = data(:,84)./BW;
        semim_l = data(:,83)./BW;
        grac_l = data(:,71)./BW;
        tfl_l = data(:,86)./BW;
        
        gaslat_l = data(:,59)./BW;
        gasmed_l = data(:,60)./BW;
        
        recfem_l = data(:,81)./BW;
        vasint_l = data(:,89)./BW;
        vasmed_l = data(:,91)./BW;
        vaslat_l = data(:,90)./BW;
        
        clear data
        
        %open GRF data to determine when each gait cycle starts
        s = importdata([path{z} tempfname(1:end-4) '.mot']);
        data = s.data;
        
        [~,~,startindex] = intersect(start,data(:,1));%make sure to use data from the same time points
        [~,~,stopindex] = intersect(stop,data(:,1));
        
        Rgz = data(startindex:stopindex,3)./BW;%forceplate z directions
        Lgz = data(startindex:stopindex,9)./BW;
%         Lgz(Lgz < 10) = 0;
%         plot(Lgz)
        for zz=1:length(Rgz)-1
            if Rgz(zz)== 0 && Rgz(zz+1) > 0
                RHS(zz) = 1;
            elseif Rgz(zz) > 0 && Rgz(zz+1) == 0
                RTO(zz) = 1;
            else
                RHS(zz) = 0;
                RTO(zz) = 0;
            end
        end
%             figure(1)
%             plot(1:length(Rgz),Rgz,1:length(RHS),RHS);
        for zz=1:length(Lgz)-1
            if Lgz(zz)== 0 && Lgz(zz+1) > 0
                LHS(zz) = 1;
            elseif Lgz(zz) > 0 && Lgz(zz+1) == 0
                LTO(zz) = 1;
            else
                LHS(zz) = 0;
                LTO(zz) = 0;
            end
        end
        
%         figure(2)
%         plot(1:length(Rgz),Rgz,1:length(RTO),RTO*10);
%         keyboard
        Rindex = find(RHS);
        Rtindex = find(RTO);
        Lindex = find(LHS);
        Ltindex = find(LTO);
%         keyboard
        if Rtindex(1) < Rindex(1)
            Rtindex(1) = [];
        end
        if Ltindex(1) < Lindex(1)
            Ltindex(1) = [];
        end
        [~,~,check1] = intersect(Rindex,Rtindex);
        Rtindex(check1) = [];
        Rindex(check1) = [];
        [~,~,check2] = intersect(Lindex,Ltindex);
        Ltindex(check2) = [];
        Lindex(check2) = [];

%         keyboard
        for zz = 1:length(Rindex)-1
            RFY{zz} = interp1(linspace(0,1,length(Rfy(Rindex(zz):Rindex(zz+1)))),Rfy(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            RGZ{zz} = interp1(linspace(0,1,length(Rgz(Rindex(zz):Rindex(zz+1)))),Rgz(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            
            BLH_r{zz} = interp1(linspace(0,1,length(bflh_r(Rindex(zz):Rindex(zz+1)))),bflh_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            BSH_r{zz} = interp1(linspace(0,1,length(bfsh_r(Rindex(zz):Rindex(zz+1)))),bfsh_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            ST_r{zz} = interp1(linspace(0,1,length(semit_r(Rindex(zz):Rindex(zz+1)))),semit_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            SM_r{zz} = interp1(linspace(0,1,length(semim_r(Rindex(zz):Rindex(zz+1)))),semim_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            GC_r{zz} = interp1(linspace(0,1,length(grac_r(Rindex(zz):Rindex(zz+1)))),grac_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            TFL_r{zz} = interp1(linspace(0,1,length(tfl_r(Rindex(zz):Rindex(zz+1)))),tfl_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            MG_r{zz} = interp1(linspace(0,1,length(gasmed_r(Rindex(zz):Rindex(zz+1)))),gasmed_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            LG_r{zz} = interp1(linspace(0,1,length(gaslat_r(Rindex(zz):Rindex(zz+1)))),gaslat_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            RF_r{zz} = interp1(linspace(0,1,length(recfem_r(Rindex(zz):Rindex(zz+1)))),recfem_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            VI_r{zz} = interp1(linspace(0,1,length(vasint_r(Rindex(zz):Rindex(zz+1)))),vasint_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            VM_r{zz} = interp1(linspace(0,1,length(vasmed_r(Rindex(zz):Rindex(zz+1)))),vasmed_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';
            VL_r{zz} = interp1(linspace(0,1,length(vaslat_r(Rindex(zz):Rindex(zz+1)))),vaslat_r(Rindex(zz):Rindex(zz+1)),linspace(0,1,101))';

            
        end

        for zz = 1:length(Lindex)-1
            LFY{zz} = interp1(linspace(0,1,length(Lfy(Lindex(zz):Lindex(zz+1)))),Lfy(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            LGZ{zz} = interp1(linspace(0,1,length(Lgz(Lindex(zz):Lindex(zz+1)))),Lgz(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            
            BLH_l{zz} = interp1(linspace(0,1,length(bflh_l(Lindex(zz):Lindex(zz+1)))),bflh_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            BSH_l{zz} = interp1(linspace(0,1,length(bfsh_l(Lindex(zz):Lindex(zz+1)))),bfsh_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            ST_l{zz} = interp1(linspace(0,1,length(semit_l(Lindex(zz):Lindex(zz+1)))),semit_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            SM_l{zz} = interp1(linspace(0,1,length(semim_l(Lindex(zz):Lindex(zz+1)))),semim_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            GC_l{zz} = interp1(linspace(0,1,length(grac_l(Lindex(zz):Lindex(zz+1)))),grac_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            TFL_l{zz} = interp1(linspace(0,1,length(tfl_l(Lindex(zz):Lindex(zz+1)))),tfl_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            MG_l{zz} = interp1(linspace(0,1,length(gasmed_l(Lindex(zz):Lindex(zz+1)))),gasmed_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            LG_l{zz} = interp1(linspace(0,1,length(gaslat_l(Lindex(zz):Lindex(zz+1)))),gaslat_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            RF_l{zz} = interp1(linspace(0,1,length(recfem_l(Lindex(zz):Lindex(zz+1)))),recfem_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            VI_l{zz} = interp1(linspace(0,1,length(vasint_l(Lindex(zz):Lindex(zz+1)))),vasint_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            VM_l{zz} = interp1(linspace(0,1,length(vasmed_l(Lindex(zz):Lindex(zz+1)))),vasmed_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            VL_l{zz} = interp1(linspace(0,1,length(vaslat_l(Lindex(zz):Lindex(zz+1)))),vaslat_l(Lindex(zz):Lindex(zz+1)),linspace(0,1,101))';
            
        end
        
        RFY = cell2mat(RFY);
        RGZ = cell2mat(RGZ);
        LFY = cell2mat(LFY);
        LGZ = cell2mat(LGZ);
        BLH_r = cell2mat(BLH_r);
        BSH_r = cell2mat(BSH_r);
        ST_r = cell2mat(ST_r);
        SM_r = cell2mat(SM_r);
        GC_r = cell2mat(GC_r);
        TFL_r = cell2mat(TFL_r);
        MG_r = cell2mat(MG_r);
        LG_r = cell2mat(LG_r);
        RF_r = cell2mat(RF_r);
        VI_r = cell2mat(VI_r);
        VM_r = cell2mat(VM_r);
        VL_r = cell2mat(VL_r);
        
        BLH_l = cell2mat(BLH_l);
        BSH_l = cell2mat(BSH_l);
        ST_l = cell2mat(ST_l);
        SM_l = cell2mat(SM_l);
        GC_l = cell2mat(GC_l);
        TFL_l = cell2mat(TFL_l);
        MG_l = cell2mat(MG_l);
        LG_l = cell2mat(LG_l);
        RF_l = cell2mat(RF_l);
        VI_l = cell2mat(VI_l);
        VM_l = cell2mat(VM_l);
        VL_l = cell2mat(VL_l);
        
        TotalR = BLH_r+BSH_r+ST_r+SM_r+GC_r+TFL_r+MG_r+LG_r+RF_r+VI_r+VM_r+VL_r;
        TotalL = BLH_l+BSH_l+ST_l+SM_l+GC_l+TFL_l+MG_l+LG_l+RF_l+VI_l+VM_l+VL_l;
        keyboard
        % Find key indicators for vertical knee contact load, GRF, and
        % muscles
        for zz = 1:length(Rindex)-1
            tempy = RFY(:,zz);
            tempgrf = RGZ(:,zz);
            tempm = TotalR(:,zz);
            [RY1(zz),loc1] = min(tempy(1:20));%first peak
            [RY2(zz),loc2] = min(tempy(30:60));%second peak
            RGF1(zz) = tempgrf(loc1);
            RGF2(zz) = tempgrf(loc2);
            RM1(zz) = tempm(loc1);
            RM2(zz) = tempm(loc2);
            
        end
        for zz = 1:length(Lindex)-1
            tempy = LFY(:,zz);
            tempgrf = LGZ(:,zz);
            tempm = TotalL(:,zz);
            [LY1(zz),loc3] = min(tempy(1:20));
            [LY2(zz),loc4] = min(tempy(30:60));
            LGF1(zz) = tempgrf(loc3);
            LGF2(zz) = tempgrf(loc4);
            LM1(zz) = tempm(loc3);
            LM2(zz) = tempm(loc4);
        end

        clear RFY LFY RGZ LGZ
        RY1mean(z) = nanmean(RY1);
        RY2mean(z) = nanmean(RY2);
        RGF1mean(z) = nanmean(RGF1);
        RGF2mean(z) = nanmean(RGF2);
        RM1mean(z) = nanmean(RM1);
        RM2mean(z) = nanmean(RM2);
        
        LY1mean(z) = nanmean(LY1);
        LY2mean(z) = nanmean(LY2);
        LGF1mean(z) = nanmean(LGF1);
        LGF2mean(z) = nanmean(LGF2);
        LM1mean(z) = nanmean(LM1);
        LM2mean(z) = nanmean(LM2);
        
        clear BLH_r BSH_r ST_r SM_r GC_r TFL_r MG_r LG_r RF_r VI_r VM_r VL_r BLH_l BSH_l ST_l SM_l GC_l TFL_l MG_l LG_l RF_l VI_l VM_l VL_l
        
        
        
    end
    
    %write to file
    OpenSim_grfmjcf_D1(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\ThreeIndicators_D1.xlsm',RY1mean*-1,RY2mean*-1,RGF1mean,RGF2mean,RM1mean,RM2mean,LY1mean*-1,LY2mean*-1,LGF1mean,LGF2mean,LM1mean,LM2mean);
%     OpenSim_grfmjcf_D2(tempfname(1:4),'C:\Users\Engineer\Desktop\Knee_OA_OpenSim\Results\ThreeIndicators_D2.xlsm',RY1mean*-1,RY2mean*-1,RGF1mean,RGF2mean,RM1mean,RM2mean,LY1mean*-1,LY2mean*-1,LGF1mean,LGF2mean,LM1mean,LM2mean);
        
    
    
else
end
%}