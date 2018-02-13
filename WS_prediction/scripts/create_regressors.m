%% create regressors

% Subject Information 
Subjects = load('../../subject_numbers.txt');
nSub = length(Subjects);

design = 'faces60';

for s = 1:nSub
    Sub = Subjects(s);
    fprintf('Running Subject %i \n',Sub);
    % load trial data
    load(fullfile('../regmat',sprintf('%i_FacesIndegreeFactorCntrlBin.mat',Sub)));
    
    % Create Regressor Data
    regressor = 1;
    
    % Tercile 1
    thisTertile=indegreeT0_factor_cntrl_tertile1_onset;
    thisTertile(:,2)=1;
    thisTertile(:,3)=1;

    for t = 1:length(thisTertile)
        outfile = sprintf('../regressors/%s/subj%i_regr%i.txt',design,Sub,regressor);
        o = fopen(outfile,'w+');
        fprintf(o,'%.3f\t%.3f\t%.3f\n',thisTertile(t,:));
        regressor = regressor + 1;
        fclose(o);
    end    
    clear thisTertile
    
    % Tercile 2
    thisTertile=indegreeT0_factor_cntrl_tertile2_onset;
    thisTertile(:,2)=1;
    thisTertile(:,3)=1;

    for t = 1:length(thisTertile)
        outfile = sprintf('../regressors/%s/subj%i_regr%i.txt',design,Sub,regressor);
        o = fopen(outfile,'w+');
        fprintf(o,'%.3f\t%.3f\t%.3f\n',thisTertile(t,:));
        regressor = regressor + 1;
        fclose(o);
    end
    clear thisTertile
    
    % Tercile 3 
    thisTertile=indegreeT0_factor_cntrl_tertile3_onset;
    thisTertile(:,2)=1;
    thisTertile(:,3)=1;

    for t = 1:length(thisTertile)
        outfile = sprintf('../regressors/%s/subj%i_regr%i.txt',design,Sub,regressor);
        o = fopen(outfile,'w+');
        fprintf(o,'%.3f\t%.3f\t%.3f\n',thisTertile(t,:));
        regressor = regressor + 1;
        fclose(o);
    end
    clear thisTertile
    
    % OddBall
    thisTertile=oddball_onset;
    thisTertile(:,2)=1;
    thisTertile(:,3)=1;
    
    outfile = sprintf('../regressors/%s/subj%i_regr%i.txt',design,Sub,regressor);
    o = fopen(outfile,'w+');

    for t = 1:length(thisTertile)
        fprintf(o,'%.3f\t%.3f\t%.3f\n',thisTertile(t,:));
    end
    regressor = regressor + 1;
    fclose(o);
    clear thisTertile
    
    % photo_attr
    thisTertile=idio_attr_ManReg';
    
    outfile = sprintf('../regressors/%s/subj%i_regr%i.txt',design,Sub,regressor);
    o = fopen(outfile,'w+');

    for t = 1:length(thisTertile)
        fprintf(o,'%.3f\n',thisTertile(t,1));
    end
    
    regressor = regressor + 1;
    fclose(o);
    
    clear thisTertile
    
    % photo_close
    thisTertile=idio_close_ManReg';
    
    outfile = sprintf('../regressors/%s/subj%i_regr%i.txt',design,Sub,regressor);
    o = fopen(outfile,'w+');

    for t = 1:length(thisTertile)
        fprintf(o,'%.3f\n',thisTertile(t,1));
    end
    
    regressor = regressor + 1;
    fclose(o);
    
    clear thisTertile
    
    % photo_nom
    thisTertile=idio_nom_ManReg';
    
    outfile = sprintf('../regressors/%s/subj%i_regr%i.txt',design,Sub,regressor);
    o = fopen(outfile,'w+');

    for t = 1:length(thisTertile)
        fprintf(o,'%.3f\n',thisTertile(t,1));
    end
    
    regressor = regressor + 1;
    fclose(o);
    
    clear thisTertile
   
end