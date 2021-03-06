%% Multivariate Prediction
% YC Leong 1/3/2018
% Edited to do within-subject prediction

% YC Leong 7/15/2017 
% This scripts takes in beta maps associated which each hub category of all 50 participants, and 
% trains a Lasso-PCA algorithm to predict hub category following a leave-one-participant-out 
% cross-validation procedure.
%
% 
% Parameters:
%   run_regression: 1 = run the regression analyses, 0 skip the regression analyses and go to
%   summary figures
%   explained_threshold = cumulative % of variance explained of retained components 
% 
% Outputs: For each ROI, generates a .mat file containing the predicted Hub category over all cross-
% validation iterations; and a map of regression weights. 
%
% Dependencies:
%   CANlabCore Toolbox available at https://github.com/canlab/CanlabCore
%   NifTI toolbox available at 
%        https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
%   SPM available at http://www.fil.ion.ucl.ac.uk/spm/

clear all
run_regression = 1;
run_FC = 1;
explained_threshold = 100;
font_size = 24;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                             Setup                                               % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Toolboxes
addpath(genpath('../../../CanlabCore')) 
addpath(genpath('../../../NIfTI')) 
addpath(genpath('/Users/yuanchangleong/Documents/spm12'))

% Set Directories 
dirs.data = '../glm';
dirs.mask = '../../masks';
dirs.results = '../../results';
dirs.input = fullfile(dirs.data,'faces60_tmap');
dirs.output = fullfile(dirs.results,'MVPA_WS_SplitHalf');

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
Subjects = load('../../data/subject_numbers.txt');
nSub = length(Subjects);

% number of bins
nbins = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                          Regression                                              % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if run_regression

    TrialID = repmat([1,2],1,30);
    FoldID = [1 1 1 2 2 2];
    
    % Loop over ROIs
    for mm = 1:nmask
        this_mask = fullfile(dirs.mask,mask_files{1,mm});
        fprintf('Running ROI: %s \n', this_mask);
        
         pred_by_bin = [];
        
        for s = 1:nSub
            fprintf('Running subject %i \n', Subjects(s));
            
            train_data = [];
            test_data = [];
            
            % load data of this subject
            data_path = fullfile(dirs.input,sprintf('subj%s_tmap.nii.gz',num2str(Subjects(s))));
            all_data = fmri_data(data_path,this_mask);
            
            % construct Y matrix 
            load(fullfile('../regmat',sprintf('%i_FacesIndegreeFactorCntrlBin.mat',Subjects(s))));
            all_data.Y = [ones(length(indegreeT0_factor_cntrl_tertile1_onset),1) * 3;...
                ones(length(indegreeT0_factor_cntrl_tertile2_onset),1) * 2;...
                ones(length(indegreeT0_factor_cntrl_tertile3_onset),1)];
            
            train_raw = all_data.dat(:,TrialID == 1);
            train_y = all_data.Y(TrialID == 1,:);
            
            test_raw = all_data.dat(:,TrialID == 2);
            test_y = all_data.Y(TrialID == 2,:);

            for b = 1:3   
                train_data(:,b) = mean(train_raw(:,train_y == b),2);
                test_data(:,b) = mean(test_raw(:,test_y == b),2);
            end
            
            both_data = [train_data test_data];
            both_Y = [1 2 3 1 2 3]';
            
            all_data.Y = both_Y;
            all_data.dat = both_data;

           [cverr, stats, optout] = predict(all_data, 'algorithm_name', 'cv_lassopcr', 'nfolds',FoldID);

           for b = 1:3
               pred_by_bin(s,b) = mean(stats.yfit(stats.Y == b & [0 0 0 1 1 1]'));
           end
           
           within_sub_corr(s) = corr(stats.yfit,stats.Y);

        end
        
    save(sprintf('%s.mat',fullfile(dirs.output,mask_files{1,mm}(1:end-4))),...
        'pred_by_bin','within_sub_corr');
 
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                Compute Forced-Choice Accuracy                                    % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Loop over ROIs 
for rr = 1:length(mask_names)
    load(sprintf('%s.mat',fullfile(dirs.output,mask_files{1,rr}(1:end-4))));

    % Calculate mean forced choice accuracy
    FC(rr,1) = mean(pred_by_bin(:,2) > pred_by_bin(:,1)); 
    FC(rr,2) = mean(pred_by_bin(:,3) > pred_by_bin(:,2)); 
    FC(rr,3) = mean(pred_by_bin(:,3) > pred_by_bin(:,1)); 
    
    % Calcuate SE of forced choice accuracy
    FC_err(rr,1) = std(pred_by_bin(:,2) > pred_by_bin(:,1))/sqrt(nSub-1);
    FC_err(rr,2) = std(pred_by_bin(:,3) > pred_by_bin(:,2))/sqrt(nSub-1);
    FC_err(rr,3) = std(pred_by_bin(:,3) > pred_by_bin(:,1))/sqrt(nSub-1);
       
end

% Intialize Figure
fig = figure();
hold on
set(gcf,'Position',[100 100 1000 400]);

% Setup plot
y = reshape(FC',1,27);
x = [1,2,3,5,6,7,9,10,11,13,14,15,17,18,19,21,22,23,25,26,27,29,30,31,33,34,35];

% Color for mentalizing ROIs
bar_col = [203,24,29;   % 3rd
    252,174,145;        % 1st 
    251,106,74];        % 2nd

% Color for VS
bar_col2 = [33,113,181;
    189,215,231;
    107,174,214];

% Color for V1
bar_col3 = [0.5,0.5,0.5;
    0.9,0.9,0.9;
    0.7,0.7,0.7];

bar_col = bar_col/255;
bar_col2 = bar_col2/255;

% Plot mentalizing ROIs
for i = 1:21
    b = bar(x(i),y(i),0.7);
    this_col = mod(i,3)+1;
    set(b,'facecolor',bar_col(this_col,:))
end

% Plot VS
for i = 22:24
    b = bar(x(i),y(i),0.7);
    this_col = mod(i,3)+1;
    set(b,'facecolor',bar_col2(this_col,:))
end

% Plot V1
for i = 25:27
    b = bar(x(i),y(i),0.7);
    this_col = mod(i,3)+1;
    set(b,'facecolor',bar_col3(this_col,:))
end

% Plot error bars
h = errorbar(x,y,reshape(FC_err',1,27));
set(h,'Color',[0,0,0],'linestyle','none');

% Chance line
plot([0,36],[0.5,0.5],'Color','k','LineStyle','--','LineWidth',2);

% Adjust axis
ylabel('Forced Choice Accuracy');
set(gca,'xtick',[2,6,10,14,18,22,26,30,34],'xticklabel',mask_names)
set(gca,'ytick',[0:0.25:1]);

% Run and plot Binomial Test Results
for rr = 1:length(mask_names)*3
    p_value(rr) = myBinomTest(y(rr)*nSub,nSub,0.5);
end
sig = x(p_value < 0.05);
scatter(sig,repmat(0.95,1,length(sig)),30,'k','*');
axis([0 36 0 1]);
set(gca,'FontSize',20)
 
% Save Figure
fig_dest = fullfile(dirs.output,'ForcedChoiceAcc');
set(gcf,'paperpositionmode','auto');
print(fig,fig_dest,'-depsc');

% Output table:
row_names = {'Low vs. Mid','Mid vs. High','Low vs. High'};
T = table(FC, FC_err, 'RowNames',mask_names)
