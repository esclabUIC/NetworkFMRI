function dur = DisplayITI(Window,var,letter)

    startT = GetSecs();

    Screen('TextSize',Window,var.textsize);
    Screen('FillRect',Window,var.bkg_color);
    DrawFormattedText(Window,letter,'center','center',var.textcolor);
    Screen('Flip',Window);
    %Screen('TextSize',Window,var.textsize);

    timer = GetSecs()-var.abs_start;
    while timer < var.ref_end
        timer = GetSecs()-var.abs_start;
    end
    
    dur = GetSecs()-startT;

end