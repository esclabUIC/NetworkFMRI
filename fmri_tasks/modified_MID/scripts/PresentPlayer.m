% This function displays the cues:

function data = PresentPlayer(Window,var,data,ind)
    
    % Get function start time:
    startT = GetSecs();
    data.blockcue_onset(var.block_count) = startT-var.abs_start;
    
    Screen('TextSize',Window,var.cuetextsize);
    
    % get the trial setup info (only person necessary for this subfunction)
    % from the block_type_index master design cellarray:
    person = var.block_type_index{ind}(1);
    
    % Center the card-box on screen:
    [cuebox,dh,dv] = CenterRect(var.cue_box,var.winrect);

    % make the card string box and center that inside the card box that we
    % centered earlier. Double center!!
    
    [facebox,dh,dv] = CenterRect(var.facerect,cuebox);
    facebox(2) = facebox(2)-var.face_distance_from_cue;
    facebox(4) = facebox(4)-var.face_distance_from_cue;

    
    [playerbox,dh,dv] = CenterRect(Screen('TextBounds',Window,var.players{person}),cuebox);

    
    % make sure the screen has the correct background color
    Screen('FillRect',Window,var.bkg_color);
    
    
    % draw the face
    Screen('DrawTexture',Window,var.faces{person},[],facebox);
    
    % draw the number, the player name, and the value cue using the
    % drawformattingtext function with the different pre-aligned text
    % boxes:
    if var.display_player_name
        DrawFormattedText(Window,var.players{person},playerbox(1),playerbox(2),var.textcolor);
    end
    
    
    Screen('Flip',Window);
    Screen('TextSize',Window,var.textsize);
    
    % Determine how much time has passed and wait to ref_end:
    
    timer = GetSecs()-var.abs_start;
    while timer < var.ref_end
        timer = GetSecs()-var.abs_start;
    end
    
    % store elapsed relative time for slide:
    data.blockcue_dur(var.block_count) = GetSecs()-startT;

end



