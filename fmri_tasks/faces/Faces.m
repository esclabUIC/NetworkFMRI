% faces task for scanner
close all; clear all; clc;

rand('twister',sum(100*clock)); % reset random number gen

%turns off white screen for psych toolbox
Screen('Preference','VisualDebugLevel',1);

%length of TR
TR = 2;

% make path struct
var.filepath = MakePathStruct();

% SUBJECT/RUN CONSOLE PROMPT:
var.subjectID = input('Please enter your subject ID number: ','s');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Load in faces from specified order
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

photo_directory=['..',filesep,'ParticipantPhotos'];
network_selection_directory=['..',filesep,'NetworkSelection'];

[photoIDs,~,~]=xlsread([network_selection_directory,filesep,num2str(var.subjectID),'.xls'],1,'A1:A30');

drr=dir([photo_directory,filesep,'*_matched.jpg']);  % find all photos with '*_matched.jpg' ending
all_photos={drr.name}';

oddball_file='oddball.jpg';

all_photos(strcmp(all_photos,oddball_file))=[];

all_photoIDs=char(all_photos);                         % the the participants ID from the numbers in the file name
all_photoIDs=str2num(all_photoIDs(:,1:end-12));

[~,id_photos_shown]=ismember(photoIDs,all_photoIDs);        % match the photos that were loaded from the .xls file with the photos in the photo directory

faces=all_photos(id_photos_shown); % get the photos to be shown

faces=cat(1,faces,oddball_file);

% randomize the face order
Nfaces=length(faces);

oddball_pct=0.16; % percent of the time oddball is shown

% figure out how many more times the oddball needs to be displayed in
% order to reach the desired percentage (oddball_pct)
N_more_oddballs=round(oddball_pct/(1/Nfaces));

% add in extra oddballs
faces_rand=cat(1,faces,repmat(faces(end),N_more_oddballs,1));

% repeat the scructure #Nrepeats number of times
Nrepeats=2;
faces_rand=repmat(faces_rand,Nrepeats,1);

% now randomize the order
N=length(faces_rand);
id=randperm(N)';
faces_rand=faces_rand(id);

%keep track of where oddballs are 
oddball_id=strncmp('oddball.jpg',faces_rand,10);

% setup a data structure (var) used by psychtoolbox to display the face
var.facefiles = strcat(photo_directory,filesep,faces_rand);

% name of output file
OUTPUT_FILE=['data',filesep,var.subjectID,'.mat'];

save(OUTPUT_FILE,'var');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% timing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wait time for displaying the face (typically 1 sec)
WaitTime=1.0;

% wait time for displaying the ITI (

ITI = [1.21 1.21 1.22 1.22 1.22 1.22 1.22 1.23 1.23 1.23 1.23 1.25 1.26 1.26 1.27 1.28 1.28 1.28 1.29 1.29 1.30 1.31 1.32 1.32 1.33 1.34 1.35 1.41... 
       1.42 1.43 1.46 1.47 1.49 1.53 1.65 1.69 1.70 2.14 2.15 2.17 2.19 2.33 2.40 2.51 2.66 2.78 2.84 2.89 3.03 3.27 3.34 3.51 3.80 4.40 4.44 4.47... 
       4.64 4.70 5.30 5.90 6.41 6.44 6.60 6.76 6.97 7.02 7.17 7.54 7.57 7.59 7.61 7.64];
var.ITITime=ITI(randperm(length(ITI)));

LeadInTime=12;
LeadOutTime=8;

run_time=length(var.facefiles)*WaitTime+sum(var.ITITime)+LeadInTime+LeadOutTime;

disp(['run time: ' num2str(run_time) 's, ' num2str(run_time/60) 'm']);
disp(['run TRs: ' num2str(run_time/TR)])


        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% use scanner?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%var.usescanner = str2num(input('Use scanner? (1 or 0) ','s'));
var.usescanner = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup screen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SCREEN SETUP:
if max(Screen('Screens'))>0 %dual screen
    dual=get(0,'MonitorPositions');
    resolution = [0,0,dual(2,3),dual(2,4)];
elseif max(Screen('Screens'))==0 % one screen
    resolution = get(0,'ScreenSize') ;
end
var.scrX = resolution(3);
var.scrY = resolution(4);

% basic set up of screen
var.bkg_color = 0;

%var.facerect = [0 0 267 200];
var.facerect = [0 0 400 400];

% text size and color of ITI
var.textsize=100;
var.textcolor=255;

% text font:
var.font = 'Helvetica';

% screenNumber = 1; % sean's computer
screenNumber = max(Screen('Screens'));

% setup the screen
[Window,var.winrect] = Screen('OpenWindow',screenNumber,0);

% setup the screen
[facebox,dh,dv] = CenterRect(var.facerect,var.winrect);
draw.facebox = facebox;

%read in all face images
for i = 1:length(var.facefiles)
    cimg = imread(var.facefiles{i});
    var.faces{i} = Screen('MakeTexture',Window,cimg);
end

draw.face = var.faces;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% INITIALIZE SCREEN:
Screen('FillRect',Window,var.bkg_color);
Screen('Flip',Window);
Screen('TextSize',Window,var.textsize);
Screen('TextFont',Window,var.font);
HideCursor;

% %% RUN THE INSTRUCTIONS:
% if var.runinstructions
%     Instructions(Window)
% end

%% WAIT TO TRIGGER SCAN:
% Put up a "Get Ready" screen until the experimenter presses a button.
Screen('TextSize',Window,50);
DrawFormattedText(Window,'Please look at each face as it appears. \n\n Press any button as soon as you see a red dot. \n\n Please keep your head still during and after the scan.','center','center',225);
Screen('Flip',Window);
%WaitSecs(0.4);

triggerscanner = 0;
while ~triggerscanner
    [down secs key d] = KbCheck(-1);
    if (down == 1)
        if strcmp('space',KbName(key))
            triggerscanner = 1;
        end
    end
    % WaitSecs(.01);
end

if var.usescanner
    %scan trigger
    s = serial('/dev/tty.usbmodem12341', 'BaudRate', 57600);
    fopen(s);
    fprintf(s, '[t]');
    fclose(s);
    var.abs_start = GetSecs();
else
    var.abs_start = GetSecs();
end

% make sure the screen has the correct background color
Screen('FillRect',Window,var.bkg_color);

var.FaceStart=NaN*zeros(length(photoIDs)*Nrepeats,1);
var.FaceEnd=NaN*zeros(length(photoIDs)*Nrepeats,1);
var.FaceDuration=NaN*zeros(length(photoIDs)*Nrepeats,1);

var.OddballStart=NaN*zeros(Nrepeats+Nrepeats*N_more_oddballs,1);
var.OddballEnd=NaN*zeros(Nrepeats+Nrepeats*N_more_oddballs,1);
var.OddballDuration=NaN*zeros(Nrepeats+Nrepeats*N_more_oddballs,1);

var.ITIStart=NaN*zeros(length(draw.face),1);
var.ITIEnd=NaN*zeros(length(draw.face),1);
var.ITIDuration=NaN*zeros(length(draw.face),1);

for i=1:length(var.OddballStart);
    var.key{i,1}=NaN;
end

var.rt=NaN*zeros(length(var.OddballStart),1);

% DISPLAY LEAD-IN ITI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% display ITI
DisplayITI(Window,var,'+');

%show for [LeadInTime] second
WaitSecs(LeadInTime);

%set for start of count for face & oddball trials
a=1;
b=1;

% draw the faces
for i=1:length(draw.face);

    % DISPLAY FACE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Get oddball start time, end time, key press, & rt
    
    if oddball_id(i) == 1
        var.OddballStart(a) = GetSecs() - var.abs_start;
        
        Screen('DrawTexture',Window,draw.face{i},[],draw.facebox);
        Screen('Flip',Window);
        
        % attempt to get key press
        [key,rt] = GetKey({'1!','2@','3#','4$'},WaitTime,[],-1);
        var.key{a}=key;
        var.rt(a)=rt;
        
        % show for [WaitTime] second
        if ~isnan(rt); % if reaction time is not NaN
            WaitSecs(WaitTime-rt); % wait for the amount of time less the reaction time
        end
        
        % Get oddball end time
        var.OddballEnd(a) = GetSecs() - var.abs_start;
        
        % record the duration of the face
        var.OddballDuration(a)=var.OddballEnd(a) - var.OddballStart(a);
        
        a = a+1;
    else
        
    %Get face start time & end time   
        
        var.FaceStart(b) = GetSecs() - var.abs_start;
        
        % show the face
        Screen('DrawTexture',Window,draw.face{i},[],draw.facebox);
        Screen('Flip',Window);
        
        %Wait time
        WaitSecs(WaitTime);
        
        % Get face end time
        var.FaceEnd(b) = GetSecs() - var.abs_start;
        
        % record the duration of the face
        var.FaceDuration(b)=var.FaceEnd(b) - var.FaceStart(b);
        
        b = b+1;
    end
    
    % DISPLAY ITI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Get ITI start time
    var.ITIStart(i) = GetSecs() - var.abs_start;
    
    % display ITI
    DisplayITI(Window,var,'+');
    
    %show for 1 second
    WaitSecs(var.ITITime(i));
    
    % Get ITI end time
    var.ITIEnd(i) = GetSecs() - var.abs_start;

    % record the duration of the ITI
    var.ITIDuration(i)=var.ITIEnd(i) - var.ITIStart(i);
    
    var.MissedOddball = sum(isnan(var.OddballStart));
    
    % save the data after each iteration
    save(OUTPUT_FILE,'var');
    
end

%% LEADOUT ITI:
DisplayITI(Window,var,'+');
WaitSecs(LeadOutTime);

Screen('CloseAll');

