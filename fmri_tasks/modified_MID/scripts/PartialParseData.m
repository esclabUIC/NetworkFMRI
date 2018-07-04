% PartialParseData takes in the data at each trial and writes it to the
% file using another function PartialDataWriter

function PartialParseData(var,data,head,ind)

    % The name of the datafile is the subject's name 
    filename = [num2str(var.subjectID) '.csv'];
    
    % prepare the cellarray of data for csv writing:
    cellout = {};
    
    % If there is a header flag, write the header information to the csv
    % cellarray first:
    if head
        header = {'block','trial',...
            'role','person_name', 'person_num','trialtype_name', 'trialtype_num',...
            'outcome_name','outcome_num','human_response_name','human_response_num'...
            'cue_value','uparrow_rightside','chose_higher','rt',...
            'target_number', 'outcome_amount', 'outcome_string','total_outcome_amount',...
            'blockcue_onset', 'blockcue_duration', ...
            'cue_onset','cue_duration', 'target_onset','target_duration', ...
            'outcome_onset','outcome_duration'};
    
        for i = 1:length(header)
            cellout{1,i} = header{i};
        end
    end
    
    
    % Take all the data at the specified index from the data object, and
    % convert everything to string variables:
    block = var.block_count;
    trial = ind;
    
    %key variables
    role = var.players{var.block_type_index{ind}(1)};
    person_name = var.people{var.block_type_index{ind}(1)};
    person_num = data.person(ind); 
    trialtype_name = var.types{var.block_type_index{ind}(2)};
    trialtype_num = data.trial_type(ind);
    outcome_name = data.wins{ind};
    outcome_num = data.outcome(ind);
    human_response_name = data.human_response{ind};
    human_response_num = data.human_response_num(ind);
    
    
    % less critical
    cue_value = data.cue_value{ind};
    uparrow_rightside = var.block_type_index{ind}(4);
    chose_higher = data.chose_higher(ind);
    rt = data.target_rt(ind);
    target_number = data.outcome_card_number(ind);
    outcome_amount = data.outcome_amounts(ind);
    outcome_string = data.outcome_strings{ind};
    total_outcome_amount = sum(data.outcome_amounts);
    
    
    %timing variables
  
 
    blockcue_onset = 0;
    blockcue_duration = 0;

    cue_onset = data.trialcue_onset(ind);
    cue_duration = data.trialcue_dur(ind);
    
    target_onset = data.target_onset(ind);
    target_duration = data.target_dur(ind);
    
    outcome_onset = data.outcome_onset(ind);
    outcome_duration = data.outcome_dur(ind); 
    

    % Prepare one row of data with these string variables (with a
    % placeholder 'tr' for now:
    row =   {block, trial,...
            role,person_name, person_num,trialtype_name,trialtype_num,...
            outcome_name,outcome_num,human_response_name,human_response_num,...
            cue_value,uparrow_rightside,chose_higher,rt,...
            target_number, outcome_amount, outcome_string,total_outcome_amount,...
            blockcue_onset, blockcue_duration,...
            cue_onset,cue_duration, target_onset,target_duration, ...
            outcome_onset,outcome_duration};

    for i = 1:length(row)
        cellout{head+1,i} = row{i};
    end

    % Use PartialDataWriter to write the file to a new or already existing
    % file:
    PartialDataWriter(filename,cellout,var.filepath.data,',');
    

end

