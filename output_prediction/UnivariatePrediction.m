%% Univariate Prediction
% YC Leong 7/17/2017 
% This scripts takes in beta maps associated which each hub category of all 50 participants, and 
% averages the beta maps to predict hub category following a leave-one-participant-out 
% cross-validation procedure.
% 
% Parameters:
%   run_regression: 1 = run the regression analyses, 0 skip the regression analyses and go to
%   summary figures
%   explained_threshold = cumulative % of variance explained of retained components 
% 
% Outputs: For each ROI, generates a .mat file containing the predicted Hub category over all cross-
% validation iterations.
%
% Dependencies:
%   CANlabCore Toolbox available at https://github.com/canlab/CanlabCore
%   NifTI toolbox available at 
%        https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
%   SPM available at http://www.fil.ion.ucl.ac.uk/spm/

clear all
run_regression = 0;
font_size = 24;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                             Setup                                                % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Toolboxes
addpath(genpath('../../CanlabCore')) 
addpath(genpath('../../NIfTI')) 
addpath(genpath('/Users/yuanchangleong/Documents/spm12'))

% Set Directories 
dirs.data = '../data';
dirs.mask = '../masks';
dirs.results = '../results';
dirs.input = fullfile(dirs.data,'FacesIndegreeFactorCntrlBin_Cntrl4ClosePersNom');
dirs.output = fullfile(dirs.results,'Univariate_output_prediction');

% Make output directory if it doesn't exist
if ~exist(dirs.output)
    mkdir(dirs.output);
end

% ROI Information 
mask_files = {'mentalizing.nii','MPFCswath.nii','PrecunPCC.nii',...
    'RTempPoles.nii','LTempPoles.nii','RTPJ.nii','LTPJ.nii','BilatVS_Plus5Win5_Lose0.nii','V1.nii'};
nmask = length(mask_files);
mask_names = {'Mentalizing','MPFC','PMC','RTP','LTP','RTPJ','LTPJ','Striatum','V1'};

% Subject Information 
Subjects = load(fullfile(dirs.data,'subject_numbers.txt'));
nSub = length(Subjects);

% number of bins
nbins = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                            Regression                                                    % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if run_regression
    
LogFile = fopen(fullfile(dirs.output,sprintf('Univariate_Prediction.txt')),'w+');
fprintf(LogFile,'ROI\t Sub\t Y\t Y_fit\n');

% Loop over ROIs
for mm = 1:nmask
    this_mask = fullfile(dirs.mask,mask_files{1,mm});
    fprintf('Running ROI: %s \n', this_mask);
    
    i = 1;
    
    % Get paths
    for s = 1:nSub
        train_data = fullfile(dirs.input,sprintf('SN_%s',num2str(Subjects(s))));
        
        % Get bin
        for f = 1:nbins
            train_paths = fullfile(train_data,sprintf('spmT_000%i.img',f));
            AllTrainPaths{i} = train_paths;
            switch f
                case 1
                    Y(i) = 3;
                case 2
                    Y(i) = 2;
                case 3
                    Y(i) = 1;
            end
            SubID(i) = s;
            i = i + 1;
        end
    end
    
    % Get data
    AllTrain=fmri_data(AllTrainPaths,this_mask);
    AllTrain.Y = Y';
    
    thisdat.mean = nanmean(AllTrain.dat);
    thisdat.Y = AllTrain.Y;
    thisdat.SubID = SubID;

    % zscore within subj
    for s = 1:nSub
        thisdat.mean(:,3*(s-1)+1:3*(s-1)+3) = nanzscore(thisdat.mean(:,3*(s-1)+1:3*(s-1)+3),0,2);
    end
    
    stats.yfit = [];
    stats.Y = thisdat.Y;
    
    % Run leave one-out cross validation
    for s = 1:nSub
        % Training set
        train_data = thisdat.mean(SubID ~= s)';
        train_y = thisdat.Y(SubID ~= s);
        
        % Format training dataset
        train_set = table(train_y, train_data,'VariableNames',{'Y','data'});
        
        % Train model
        trained_model = fitlm(train_set,'Y~data');
        
        % get coefficient
        reg_coef(s,1) = trained_model.Coefficients.Estimate(2);
        
        % Testing set
        test_data = thisdat.mean(SubID == s)';
        test_y = thisdat.Y(SubID == s);
        
        % Format Testing set
        test_set = table(test_y, test_data,'VariableNames',{'Y','data'});
        
        % Test data
        this_ypred = predict(trained_model, test_set);
        
        stats.yfit = [stats.yfit; this_ypred];
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                       Within Subject Stats                                               % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    within_sub_corr = NaN(nSub,1);
    pred_by_bin = NaN(nSub,3);
    
    for s = 1:nSub
        this_yfit = stats.yfit(SubID == s);
        this_y = stats.Y(SubID == s);
        
        for b = 1:3
            pred_by_bin(s,b) = this_yfit(this_y == b);
        end
        
        within_sub_corr(s) = corr(this_y,this_yfit);
        
    end
    
    save(sprintf('%s.mat',fullfile(dirs.output,mask_files{1,mm}(1:end-4))),...
        'pred_by_bin','within_sub_corr','stats','reg_coef');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                     Print prediction to CSV                                              % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

    for t = 1:150
        fprintf(LogFile,'%s\t %i\t %0.1f\t %0.4f\n', mask_names{mm}, SubID(t), stats.Y(t), stats.yfit(t));
    end
    
end

    fclose(LogFile);

end

for rr = 1:length(mask_names)
    load(sprintf('%s.mat',fullfile(dirs.output,mask_files{1,rr}(1:end-4))));

    pred3(:,rr) = pred_by_bin(:,3);
    pred2(:,rr) = pred_by_bin(:,2);
    pred1(:,rr) = pred_by_bin(:,1);
    
    gap1(:,rr) = pred_by_bin(:,2) - pred_by_bin(:,1);
    gap2(:,rr) = pred_by_bin(:,3) - pred_by_bin(:,2);
    
    [H, P, CI, STATS] = ttest(gap1(:,rr),gap2(:,rr),'tail','left');
    
    fprintf('%s: 2 > 1 = %0.2f (%0.2f); 3 > 2 = %0.2f (%0.2f); t=%0.2f, p=%0.3f \n',...
        mask_names{rr},mean(gap1(:,rr)),std(gap1(:,rr))/sqrt(49),mean(gap2(:,rr)),std(gap2(:,rr))/sqrt(49),STATS.tstat,P)

end