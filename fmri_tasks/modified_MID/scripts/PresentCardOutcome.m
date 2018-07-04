% This function displays the cues:

function data = PresentCardOutcome(Window,var,data,ind)
    
    % Get function start time:
    startT = GetSecs();
    data.outcome_onset(ind) = startT-var.abs_start;
    
    Screen('TextSize',Window,var.cuetextsize);
    
    
    % center the cue-box on screen:
    [cuebox,dh,dv] = CenterRect(var.cue_box,var.winrect);
    
    
    % Center the card-box on screen:
    [cardbox,dh,dv] = CenterRect(var.card_box,var.winrect);
    cardbox(2) = cardbox(2)+var.card_distance_from_cue;
    cardbox(4) = cardbox(4)+var.card_distance_from_cue;
    
    % get the trial setup info from the block_type_index master design
    % cellarray:
    person = var.block_type_index{ind}(1);
    trialtype = var.block_type_index{ind}(2);
    outcome = var.block_type_index{ind}(3);
    
    
    % did the computer choose on this trial?:
    % hard coded this in
    computer_selection_trial = 0;
    

    % choice 1 is higher, choice 0 is lower
    chose_higher = data.chose_higher(ind);
    computer_chose_higher = data.computer_chose_higher(ind);
    

    if chose_higher == -1
        did_not_respond = 1;
    else
        did_not_respond = 0;
    end
    
    % assign outcome string to wins vector, contingent on preformance and
    % whether the trial was computer or human:
    
    if computer_selection_trial
        
        if outcome
            data.wins{ind} = 'correct';
        else
            data.wins{ind} = 'incorrect';
        end
        
        if did_not_respond
            data.human_response{ind} = 'miss';
            data.human_response_num(ind) = 0;
        else
            data.human_response{ind} = 'hit';
            data.human_response_num(ind) = 1;
        end
        
        if ~(chose_higher == computer_chose_higher)
            data.human_response{ind} = 'miss';
            data.human_response_num(ind) = 0;
        end
        
    else
        
        if did_not_respond
            data.wins{ind} = 'miss';
            data.human_response{ind} = 'miss';
            data.human_response_num(ind) = 0;
        else
            if outcome
                data.wins{ind} = 'correct';
            else
                data.wins{ind} = 'incorrect';
            end
            data.human_response{ind} = 'hit';
            data.human_response_num(ind) = 1;
        end
        
    end

    
    % determine the string for the outcome slide, depending on whether the
    % subject hit or not.
    if did_not_respond
        
        str_value = var.miss_string;
        value = var.miss_penalty;
        var.outcome_color = [255 0 0];
        
    else
        
        value = 0;
        
        switch trialtype
            case 1
                if outcome
                    str_value = '+$5';
                    value = 5;
                    var.outcome_color = [0 255 0]; 
                else
                    str_value = '$0';
                    var.outcome_color = var.textcolor;
                end
            case 2
                if outcome
                    str_value = '+$0';
                    var.outcome_color = [0 255 0]; 
                else
                    str_value = '$0';
                    var.outcome_color = var.textcolor;
                end
        end
                
        str_value = [str_value var.value_extension];
        
        if computer_selection_trial
            value = 0;
            if ~(chose_higher == computer_chose_higher)
                value = var.miss_penalty;
                str_value = var.miss_string;
                var.outcome_color = [255 0 0];
            end
        end

    end
    
    
    
    % keep track of the money the subject has won, but also what string was
    % presented (different depending on whether it is a human or computer
    % trial.
    data.outcome_amounts(ind) = value;
    data.outcome_strings{ind} = str_value;
    
    
    % determine the card number. first figure out whether the card number
    % has to be higher, lower, or "miss", then determine the outcome card
    % number randomly.
    if computer_selection_trial
        if computer_chose_higher
            if outcome
                card_higher = 1;
            else
                card_higher = 0;
            end
        else
            if outcome
                card_higher = 0;
            else
                card_higher = 1;
            end
        end
    else
        if chose_higher == 1
            if outcome
                card_higher = 1;
            else
                card_higher = 0;
            end
        elseif chose_higher == 0
            if outcome
                card_higher = 0;
            else
                card_higher = 1;
            end
        elseif chose_higher == -1
            if rand() > 0.5
                card_higher = 1;
            else
                card_higher = 0;
            end
        end
    end
    
    if card_higher
        data.outcome_card_number(ind) = var.above(randi(length(var.above)));
    else
        data.outcome_card_number(ind) = var.below(randi(length(var.below)));
    end
                
    
    
    
    % change the number of the card to a string to display
    if did_not_respond
        card_number_str = ' ';
    elseif computer_selection_trial && ~(chose_higher == computer_chose_higher)
        card_number_str = ' ';
    else
        card_number_str = int2str(data.outcome_card_number(ind));
    end
    
    data.outcome_card_string{ind} = card_number_str;
    
    
    % make the card string box and center that inside the card box that we
    % centered earlier. Double center!!
    
    [numberbox,dh,dv] = CenterRect(Screen('TextBounds',Window,card_number_str),cardbox);
    
    [valuebox,dh,dv] = CenterRect(Screen('TextBounds',Window,str_value),cuebox);
    %valuebox(2) = valuebox(2)+var.amount_distance_from_cue;

    
    [facebox,dh,dv] = CenterRect(var.facerect,cuebox);
    facebox(2) = facebox(2)-var.face_distance_from_cue;
    facebox(4) = facebox(4)-var.face_distance_from_cue;
    
    
    % make sure the screen has the correct background color
    Screen('FillRect',Window,var.bkg_color);
    
    
    % draw the frame of the card
    if ~did_not_respond
        if ~(computer_selection_trial && ~(chose_higher == computer_chose_higher))
            Screen('FrameRect',Window,var.textcolor,cardbox,var.cue_pen);
        end
    end
    
    
    % draw the face
    if var.picture_on_outcome
        if ~did_not_respond
        Screen('DrawTexture',Window,var.faces{person},[],facebox);
        end
    end
    
    
    % draw the number, the player name, and the value cue using the
    % drawformattingtext function with the different pre-aligned text
    % boxes:
    DrawFormattedText(Window,card_number_str,numberbox(1),numberbox(2),var.textcolor);
    
    DrawFormattedText(Window,str_value,valuebox(1),valuebox(2),var.outcome_color);
    
    Screen('Flip',Window);
    Screen('TextSize',Window,var.textsize);
    
    % Determine how much time has passed and wait to ref_end:
    timer = GetSecs()-var.abs_start;
    while timer < var.ref_end
        timer = GetSecs()-var.abs_start;
    end
    
    % store elapsed relative time for slide:
    data.outcome_dur(ind) = GetSecs()-startT;
    

end



