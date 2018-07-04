function SelfMID()

rand('twister',sum(100*clock)); %reset random number gen

 %turns off white screen for psych toolbox
Screen('Preference','VisualDebugLevel',1);
    
    %% EXPERIMENT VARIABLES:
    
    % variables contained with in the var data object, for ease of variable
    % passing. Maintains experimental state.
    
    % data specific variables are stored within the data object, this
    % object is for those variables recorded from the subject or relevant
    % to the writing out of the data. This also allows someone to save a
    % .mat instead of csv of only the relevant data.
    

    
    var = UserVariables();


var.friend_index = {};
var.self_index = {};

% this will algorithmically create the variables according to how many
    % people and types there are using the eval command
    
    % iterate through the "people" defined in UserVariables.m
    for p = 1:length(var.people)
        
        % get the person's name
        person = var.people{p};
        
        % iterate through the number of trial types, also defined in
        % UserVariables.m
        for t = 1:length(var.types)
            
            % get the name of the type
            type = var.types{t};
            
            % create a string for the variable containing the wins/losses
            % for that particular type
            typestr = ['var.type' int2str(t) '_out'];
            
            % use the eval command to create a new variable per person per
            % type that randomizes the outcomes of that type:
            eval(['var.' person '_' type '_out  = ' typestr '(randperm(length(' typestr ')))']);
            
        end
        
    end



for person = 1
        for trial_type = 1:length(var.types)
            
            p = var.people{person};
            t = var.types{trial_type};
            
            len = eval(['length(var.' p '_' t '_out)']);
            
            for i = 1:len
                % determine the arrow orientation depending on whether the
                % index of the wins and losses are even or odd. This does
                % NOT correspond to a win or loss, since wins and losses
                % have already been randomized earlier.
                %
                % if arrow_orient is 1, the up arrow is on the right
                if mod(i,2)
                    arrow_orient = 1;
                else
                    arrow_orient = 0;
                end
                outcome = eval(['var.' p '_' t '_out(' int2str(i) ')']);
                var.friend_index{end+1} = [person trial_type outcome arrow_orient];
            end
            
        end
end
    
    
%randomize the order of trials within friend & within self trials

var.friend_index = var.friend_index(randperm(length(var.friend_index)));
var.self_index = var.self_index(randperm(length(var.self_index)));

block_num = 0;
friend_block_num = 0; 
self_block_num = 0; 


%calculate total number of trials
trial_total = length(var.people)*(length(var.type1_out)+length(var.type2_out));

% initial cell array that will story all trial information
for i = 1:trial_total
    var.type_index{i}=[0 0 0 0];
end

% set number ot trials per block
trials_per_block = 10;

% calcualate total number of blocks
var.block_total = trial_total/(trials_per_block);

% calculate number of blocks for each person: stranger, friend, and self
blocks_per_person = var.block_total/(length(var.people));

%creates a random block order for all blocks by randomizing the order of
%friend and self a certain number of times (# of blocks per
%person)

for i=1:blocks_per_person
    block_order(i,:) = randperm(length(var.people));
end


%this will take randomized trials from friend and self
%categories and fill them into randomized block order

for i=1:blocks_per_person
    for j=1:(length(var.people))
        if block_order(i,j) == 1
            var.type_index((1+trials_per_block*block_num):(trials_per_block*(block_num+1))) = var.friend_index((1+trials_per_block*friend_block_num):(trials_per_block*(friend_block_num +1)));
            block_num = block_num + 1;
            friend_block_num = friend_block_num + 1; 
        elseif block_order(i,j) == 2
            var.type_index((1+trials_per_block*block_num):(trials_per_block*(block_num+1))) = var.self_index((1+trials_per_block*self_block_num):(trials_per_block*(self_block_num+1)));
            block_num = block_num + 1;
            self_block_num = self_block_num + 1; 
        end
    end
end

    
    if var.usedecimals == 1
        var.value_extension = '.00';
    else
        var.value_extension = '';
    end
    
    
    

    
    
    %% SCREEN SETUP:
    if max(Screen('Screens'))>0 %dual screen
        dual=get(0,'MonitorPositions');
        resolution = [0,0,dual(2,3),dual(2,4)];
    elseif max(Screen('Screens'))==0 % one screen
        resolution = get(0,'ScreenSize') ;
    end
    var.scrX = resolution(3);
    var.scrY = resolution(4);
    

    var.filepath = MakePathStruct();
    
    % testing should make the experiment run faster than normal
    testing = 0;
    
    
    %% SUBJECT/RUN CONSOLE PROMPT:
    if ~testing
        var.subjectID = input('Please enter your subject ID number: ','s');
        
        %find their photo
        photo_directory=['..',filesep,'ParticipantPhotos'];
        var.facefiles = strcat(photo_directory,filesep,num2str(var.subjectID),'_matched.jpg');
        
        % if the subject already has data, load in their data. This enables
        % you to use the same randomization scheme for multiple runs even
        % though matlab ended.
        %
        % NOTE: You cannot change the design of the experiment and then
        % expect the variable loading to work.
        generate_sub_design = 1;
        cd(var.filepath.data)
        try
            var = load([var.subjectID '_var.mat']);
            var = var.var;
            disp(['var from run 1 loaded'])
            generate_sub_design = 0;
        catch
            disp(['no var object found for this subject'])
        end
        cd(var.filepath.main)
        
        %var.usescanner = str2num(input('Use scanner? (1 or 0) ','s'));
        var.usescanner =1;
        
        
        % this is some insane shit that automatically splits up the trials
        % into any number of runs you prefer:
        if generate_sub_design
            

        %Hard coded in that it will be 1 run only
            % var.number_of_runs = str2num(input('How many runs? ', 's'));
              var.number_of_runs = 1;
        
            % number of trials per run. frontload remainders to run 1 (?)
            trialnum_mod = mod(length(var.type_index),var.number_of_runs);
            trialnum_perrun = (length(var.type_index)-trialnum_mod)/var.number_of_runs;

            var.run_start_inds = [];
            var.run_lengths = [];
            var.iti_times = [];
            var.block_pause_times = [];
            var.cue_times = [];
            
            
            for i = 1:var.number_of_runs

                if (i == 1)
                    var.run_lengths(i) = trialnum_perrun+trialnum_mod;
                    var.run_start_inds(i) = 1;
                else
                    var.run_lengths(i) = trialnum_perrun;
                    var.run_start_inds(i) = var.run_start_inds(i-1)+var.run_lengths(i-1);
                end

                iti_mod = mod(var.run_lengths(i),3);
                itis = repmat([2 4 6],1,(var.run_lengths(i)-iti_mod)/3);
                iti_remainder = repmat(4,1,iti_mod);
                
                run_itis = [itis iti_remainder];
                run_itis = run_itis(randperm(length(run_itis)));
                var.iti_times = [var.iti_times run_itis];
                
                % modified cue times to be either 2, 2.25, or 2.5
                cue_mod = mod(var.run_lengths(i),3);
                cues = repmat([2 2.25 2.5],1,(var.run_lengths(i)-cue_mod)/3);
                cue_remainder = repmat(4,1,cue_mod);

                run_cues = [cues cue_remainder];
                run_cues = run_cues(randperm(length(run_cues)));
                var.cue_times = [var.cue_times run_cues];

                btime = sum(run_itis)+sum(run_cues)+(var.run_lengths(i)*(var.target_time+var.outcome_time))...
                        +var.leadin+var.leadout;
                btrs = ceil(btime/2);
                disp(['run: ' num2str(i)])
                disp(['run time: ' num2str(btime) 's, ' num2str(btime/60) 'm'])
                disp(['run TRs: ' num2str(btrs)])

            end
            
        end  
        
%         var.runnumber = str2num(input('Run number? ','s'));
        var.runnumber = 1;
        var.runinstructions = 0;
        
        
    else
        var.subjectID = 'testsub';
        var.usescanner = 0;
        var.runnumber = 1;
        var.runinstructions = 0;
        var.leadin = 1;
        var.leadout = 1;
    end
        
    
    % depending on the user-entered run number, determine the subjectID
    % and which cues/itis to use (these have to be defined prior to this).
    var.subjectID = [var.subjectID '_r' num2str(var.runnumber)];

    
    
    %% PREPARE EXPERIMENT STRUCTURE:
    
    screenNumber = max(Screen('Screens'));
    [Window,var.winrect] = Screen('OpenWindow',screenNumber,0);
    
    
    % make the textures for each face in facefiles:
    cimg = imread(var.facefiles);
    var.faces{1} = Screen('MakeTexture',Window,cimg);

    % make the textures for the arrows:
    uparrow = imread(var.uparrowfile);
    downarrow = imread(var.downarrowfile);
    
    var.uparrow = Screen('MakeTexture',Window,uparrow);
    var.downarrow = Screen('MakeTexture',Window,downarrow);
    
    
    
    
    %% ENTER SCRIPTS DIRECTORY:
    cd(var.filepath.scripts)
    


    %% INITIALIZE DATA OBJECT:
    % The data object stores all of the data as the experiment runs, but
    % should be pre-initialized.
    data.drifts = [];
    data.person = []; 
    data.trial_type = [];
    data.outcome = [];
    data.uparrow_rightside = [];
    data.blockcue_onset = [];
    data.blockcue_dur = [];
    data.trial_onset = [];
    data.trialcue_dur = [];
    data.target_onset = [];
    data.target_dur = [];
    data.outcome_onset = [];
    data.outcome_dur = [];
    data.chose_higher = [];
    data.wins = {};
    data.human_response = {};
    data.human_response_num = [];
    data.target_key = {};
    data.target_rt = [];
    data.target_misses = [];
    data.computer_chose_higher = [];
    data.cue_value = {};
    data.outcome_amounts = [];
    data.outcome_strings = {};
    data.outcome_card_number = [];
    data.outcome_card_string = {};


    
    
    %% INITIALIZE SCREEN:
    Screen('FillRect',Window,var.bkg_color); 
    Screen('Flip',Window);
    Screen('TextSize',Window,var.textsize);
    Screen('TextFont',Window,var.font);
    HideCursor;
    
    
    %% RUN THE INSTRUCTIONS:
    if var.runinstructions
        Instructions(Window)
    end
    
    
    %% WAIT TO TRIGGER SCAN:
    % Put up a "Get Ready" screen until the experimenter presses a button.
    Screen('TextSize',Window,50);
    DrawFormattedText(Window,'You will now play to win money for yourself. \n\n Please keep your head as still as possible \n and get ready to make guesses.','center','center',225);
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
  
    %% SET END REFERENCE TIME:
    % ref_end is continually updated as the end time for various functions.
    % This, along with abs_start, allows for absolute timing of functions
    % and thus drift adjust on the ITI is extremely accurate.
    var.ref_end = 0;
    
    
    
    % subindex which trials it will be for this run.
    %
    % subfunctions use var.block_type_index to determine the setup of each
    % trial! Generally this is up at or near the top of each subfunction.
    var.block_type_index = var.type_index(var.run_start_inds(var.runnumber):var.run_start_inds(var.runnumber)+var.run_lengths(var.runnumber)-1);
    
%Get correct picture and set it up for display on initial screen
[cuebox,dh,dv] = CenterRect(var.cue_box,var.winrect);
    
    %% LEADIN ITI:
    var.ref_end = var.ref_end+var.leadin;
    data.leadin_time = DisplayITI(Window,var,'+');
    
    
    trial_num = 0;
    var.block_count = 0;
    
    %% MAIN EXPERIMENT LOOP
    % Runs the experiment!
    for i = 1:length(var.block_type_index)
        
%         if mod(trial_num + trials_per_block, trials_per_block)==0
%             var.block_count = var.block_count + 1;
%             var.ref_end = var.ref_end + var.player_time;
%             data = PresentPlayer(Window,var,data,i);   
%             var.block_start = 1;  
%         end
        
        % This records the absolute onset time of trials:
        data.trial_onset(i) = GetSecs()-var.abs_start;
        
        var.ref_end = var.ref_end + var.cue_times(i);
        data = PresentCue(Window,var,data,i);
        
        var.ref_end = var.ref_end + var.target_time;
        data = PresentCardTarget(Window,var,data,i);
        
        var.ref_end = var.ref_end + var.outcome_time;
        data = PresentCardOutcome(Window,var,data,i);
        
        % Calculate the possible drift by subtracting the ideal time
        % from the accumulated time of the trial. (Note:
        % the drift time is for all slides prior to the ITI)
         
        data.drifts(i) = GetSecs() - data.trial_onset(i) - var.abs_start - var.cue_times(i)...
                          - var.target_time - var.outcome_time;
  
        % Write the partial data into the file. This way, if the experiment
        % breaks or ends for some reason, you will have data for every
        % completed trial at least:
        PartialParseData(var,data,(i==1),i);
        
        % Update the reference end time by adding the current ITI time:
        var.ref_end = var.ref_end + var.iti_times(i);

        % Display an ITI until the reference end time is reached (this is
        % how drift is corrected for):
        data.iti_dur(i) = DisplayITI(Window,var,'+'); 
        data.trial_dur(i) = GetSecs()-data.trial_onset(i)-var.abs_start;
        
        cd(var.filepath.data)
        save([var.subjectID '_var.mat'], 'var')
        save([var.subjectID '_data.mat'], 'data')
        cd(var.filepath.scripts)
        
        
        %update trial number
        trial_num = trial_num + 1;
        
    end
    
    
    %% LEADOUT ITI:
    var.ref_end = var.ref_end+var.leadout;
    data.leadout_time = DisplayITI(Window,var,'+');
    
    cd(var.filepath.main)
     
    Screen('CloseAll');
        

end
