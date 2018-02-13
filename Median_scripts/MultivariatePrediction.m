%% Multivariate Prediction
% YC Leong 7/15/2017 
% This scripts takes in beta maps associated which each hub category of all 50 participants, and 
% trains a Lasso-PCA algorithm to predict hub category following a leave-one-participant-out 
% cross-validation procedure.
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
explained_threshold = 35;
font_size = 24;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                             Setup                                               % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Toolboxes
addpath(genpath('../../CanlabCore')) 
addpath(genpath('../../NIfTI')) 
addpath(genpath('/Users/yuanchangleong/Documents/spm12'))


% Set Directories 
dirs.data = '../data';
dirs.mask = '../masks';
dirs.results = '../results';
dirs.input = fullfile(dirs.data,'FacesIndegreeFactorCntrlBin_Cntrl4Three');
dirs.output = fullfile(dirs.results,'MVPAMedian_Cntrl4Three');

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
nbins = 2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                          Regression                                              % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if run_regression

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
                        Y(i) = 2;
                    case 2
                        Y(i) = 1;
                end
                SubID(i) = s;
                i = i + 1;
            end
        end
        
        % Get data
        AllTrain=fmri_data(AllTrainPaths,this_mask);
        AllTrain.Y = Y';
        
        % zscore within subj
        for s = 1:nSub
            AllTrain.dat(:,2*(s-1)+1:2*(s-1)+2) = nanzscore(AllTrain.dat(:,2*(s-1)+1:2*(s-1)+2),0,2);
        end
        
        % Run regression
        if explained_threshold == 100
            % Retain all components
            [cverr, stats, optout] = predict(AllTrain, 'algorithm_name', 'cv_lassopcr', 'nfolds', SubID);
            explained = NaN;
            cumsum_explained = NaN;
            nPC = NaN;
        else
            % Retain components that retain X% of the variance 
            [coeff,score,latent,tsquared,explained,mu] = pca(AllTrain.dat);
            cumsum_explained = cumsum(explained);
            nPC = find(cumsum_explained > explained_threshold,1);
            [cverr, stats, optout] = predict(AllTrain, 'algorithm_name', 'cv_lassopcr', 'nfolds', SubID, 'numcomponents',nPC);
        end
        
        % Print out regression weight for each voxel
        stats.weight_obj.dat = stats.weight_obj.dat/std(stats.weight_obj.dat);
        unthresholded = stats.weight_obj;
        unthresholded.fullpath = fullfile(dirs.output,sprintf('%s.nii',mask_files{1,mm}(1:end-4)));
        write(unthresholded);
        
        % Within Subject Stats                                             
        within_sub_corr = NaN(nSub,1);
        pred_by_bin = NaN(nSub,2);
        
        for s = 1:nSub
            this_yfit = stats.yfit(SubID == s);
            this_y = stats.Y(SubID == s);
            
            for b = 1:2
                pred_by_bin(s,b) = this_yfit(this_y == b);
            end
                       
            within_sub_corr(s) = corr(this_y,this_yfit);
            
        end
        
        save(sprintf('%s.mat',fullfile(dirs.output,mask_files{1,mm}(1:end-4))),...
            'pred_by_bin','within_sub_corr','stats','explained','cumsum_explained','nPC');  
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
    
    % Calcuate SE of forced choice accuracy
    FC_err(rr,1) = std(pred_by_bin(:,2) > pred_by_bin(:,1))/sqrt(nSub-1);
       
end

% Intialize Figure
fig = figure();
hold on
set(gcf,'Position',[100 100 1000 400]);

% Setup plot
y = FC;
x = [1:9];

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
for i = 1:7
    b = bar(x(i),y(i),0.7);
    this_col = 1;
    set(b,'facecolor',bar_col(this_col,:))
end

% Plot VS
for i = 8
    b = bar(x(i),y(i),0.7);
    this_col = 1;
    set(b,'facecolor',bar_col2(this_col,:))
end

% Plot V1
for i = 9
    b = bar(x(i),y(i),0.7);
    this_col = 1;
    set(b,'facecolor',bar_col3(this_col,:))
end

% Plot error bars
h = errorbar(x,y,reshape(FC_err',1,9));
set(h,'Color',[0,0,0],'linestyle','none');

% Chance line
plot([0,10],[0.5,0.5],'Color','k','LineStyle','--','LineWidth',2);

% Adjust axis
ylabel('Forced Choice Accuracy');
set(gca,'xtick',1:9,'xticklabel',mask_names)
set(gca,'ytick',[0:0.25:1]);

% Run and plot Binomial Test Results
for rr = 1:length(mask_names)
    p_value(rr) = myBinomTest(y(rr)*nSub,nSub,0.5);
end
sig = x(p_value < 0.05);
scatter(sig,repmat(0.95,1,length(sig)),9,'k','*');
axis([0 10 0 1]);
set(gca,'FontSize',20)
 
% Save Figure
fig_dest = fullfile(dirs.output,'ForcedChoiceAcc');
set(gcf,'paperpositionmode','auto');
print(fig,fig_dest,'-depsc');

% Output table:
row_names = {'Low vs. Mid','Mid vs. High','Low vs. High'};
T = table(FC, FC_err, 'RowNames',mask_names)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                Compute Within-Subject Correlation                                % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all_corr = NaN(nSub,length(mask_names));
fprintf('Mean Within-Subject Correlation \n')
for rr = 1:length(mask_names)
    load(sprintf('%s.mat',fullfile(dirs.output,mask_files{1,rr}(1:end-4))));
    fprintf('%s: %0.3f (%0.3f) \n',mask_names{rr},mean(within_sub_corr),std(within_sub_corr)/sqrt(length(within_sub_corr)-1));
end