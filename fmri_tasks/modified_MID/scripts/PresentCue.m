% This function displays the cues:

function data = PresentCue(Window,var,data,ind)
    
    % Get function start time:
    startT = GetSecs();
    data.trialcue_onset(ind) = startT -var.abs_start;
    
    Screen('TextSize',Window,var.cuetextsize);
    
    
    %at start of trial, output information into data file
    data.person(ind) = var.block_type_index{ind}(1); 
    data.trial_type(ind) = var.block_type_index{ind}(2);
    data.outcome(ind) = var.block_type_index{ind}(3);
    data.uparrow_rightside(ind) = var.block_type_index{ind}(4);
    
    % Center the card-box on screen:
    [cuebox,dh,dv] = CenterRect(var.cue_box,var.winrect);
    
    radius = (cuebox(3)-cuebox(1))/2;
    deviation = sqrt((radius^2)/2);
    
    % get the trial setup info from the block_type_index master design
    % cellarray:
    person = var.block_type_index{ind}(1);
    trialtype = var.block_type_index{ind}(2);
    
    
    % Draw shape and value depending on trialtype:
    switch trialtype
        case 1
            shape = 'circle_highline';
            data.cue_value{ind} = '+$5';
        case 2
            shape = 'circle_lowline';
            data.cue_value{ind} = '+$0';
    end

    % value depending on trialtype:
    str_value = [var.type_strings{trialtype} var.value_extension];
    
    
    
    % make the card string box and center that inside the card box that we
    % centered earlier. Double center!!
        
    [valuebox,dh,dv] = CenterRect(Screen('TextBounds',Window,str_value),cuebox);
    valuebox(2) = valuebox(2)+var.amount_distance_from_cue;

    
    [facebox,dh,dv] = CenterRect(var.facerect,cuebox);
    facebox(2) = facebox(2)-var.face_distance_from_cue;
    facebox(4) = facebox(4)-var.face_distance_from_cue;

    
    [playerbox,dh,dv] = CenterRect(Screen('TextBounds',Window,var.players{person}),cuebox);
    playerbox(2) = playerbox(2)-var.player_distance_from_cue;
    
    % make sure the screen has the correct background color
    Screen('FillRect',Window,var.bkg_color);
    
    
    % draw the face
    Screen('DrawTexture',Window,var.faces{person},[],facebox);
    
    % draw the number, the player name, and the value cue using the
    % drawformattingtext function with the different pre-aligned text
    % boxes:
    
    if var.amount_below_card
        DrawFormattedText(Window,str_value,valuebox(1),valuebox(2),var.textcolor);
    end
   
    
    % Draw the full cue to screen:    
    if strcmp(shape,'circle_plain')
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        
    elseif strcmp(shape,'circle_lowline')
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        startX = cuebox(1)+radius-deviation;
        startY = cuebox(2)+radius+deviation;
        finX = cuebox(1)+radius+deviation;
        finY = cuebox(2)+radius+deviation;
        Screen('DrawLine',Window,var.textcolor,startX,startY,finX,finY,var.cue_pen);
        
    elseif strcmp(shape,'circle_midline')
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        startX = cuebox(1);
        startY = cuebox(2)+radius;
        finX = cuebox(3);
        finY = cuebox(2)+radius;
        Screen('DrawLine',Window,var.textcolor,startX,startY,finX,finY,var.cue_pen);
        
    elseif strcmp(shape,'circle_highline')
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        startX = cuebox(1)+radius-deviation;
        startY = cuebox(2)+radius-deviation;
        finX = cuebox(1)+radius+deviation;
        finY = cuebox(2)+radius-deviation;
        Screen('DrawLine',Window,var.textcolor,startX,startY,finX,finY,var.cue_pen);
        
    elseif strcmp(shape,'square_plain')
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen);
        
    elseif strcmp(shape,'square_lowline')
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen);
        setY = cuebox(2)+radius+deviation;
        Screen('DrawLine',Window,var.textcolor,cuebox(1),setY,cuebox(3),setY,var.cue_pen);
        
    elseif strcmp(shape,'square_midline')
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen);
        setY = cuebox(2)+radius;
        Screen('DrawLine',Window,var.textcolor,cuebox(1),setY,cuebox(3),setY,var.cue_pen);
      
    elseif strcmp(shape,'square_highline')
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen)
        setY = cuebox(2)+radius-deviation;
        Screen('DrawLine',Window,var.textcolor,cuebox(1),setY,cuebox(3),setY,var.cue_pen);
        
    end
    
    
    Screen('Flip',Window);
    Screen('TextSize',Window,var.textsize);
    
    % Determine how much time has passed and wait to ref_end:
    
    timer = GetSecs()-var.abs_start;
    while timer < var.ref_end
        timer = GetSecs()-var.abs_start;
    end
    
    % store elapsed relative time for slide:
    data.trialcue_dur(ind) = GetSecs()-startT;
    

end



