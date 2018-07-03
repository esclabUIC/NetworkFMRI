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
run_regression = 0;
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
dirs.input = fullfile(dirs.data,'FacesIndegreeFactorCntrlBin_Cntrl4ClosePersNom');
dirs.output = fullfile(dirs.results,'MVPA_output_prediction');

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                          Regression                                              % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if run_regression
    LogFile = fopen(fullfile(dirs.output,sprintf('MVPA_Prediction.txt')),'w+');
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
        
        % zscore within subj
        for s = 1:nSub
            AllTrain.dat(:,3*(s-1)+1:3*(s-1)+3) = nanzscore(AllTrain.dat(:,3*(s-1)+1:3*(s-1)+3),0,2);
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
            'pred_by_bin','within_sub_corr','stats','explained','cumsum_explained','nPC'); 
        
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                     Print prediction to CSV                                              % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

    for t = 1:150
        fprintf(LogFile,'%s\t %i\t %0.1f\t %0.4f\n', mask_names{mm}, SubID(t), stats.Y(t), stats.yfit(t));
    end
    
    end
    
    fclose(LogFile);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                Compute Gap Difference                                     % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for rr = 1:length(mask_names)
    load(sprintf('%s.mat',fullfile(dirs.output,mask_files{1,rr}(1:end-4))));

    pred3(:,rr) = pred_by_bin(:,3);
    pred2(:,rr) = pred_by_bin(:,2);
    pred1(:,rr) = pred_by_bin(:,1);
    
    gap1(:,rr) = pred_by_bin(:,2) - pred_by_bin(:,1);
    gap2(:,rr) = pred_by_bin(:,3) - pred_by_bin(:,2);
    
    
    
    [H, P, CI, STATS] = ttest(gap1(:,rr),gap2(:,rr),'tail','left');
    
    fprintf('%s: 2 > 1 = %0.3f (%0.3f); 3 > 2 = %0.3f (%0.3f); t=%0.3f, p=%0.3f \n',...
        mask_names{rr},mean(gap1(:,rr)),std(gap1(:,rr))/sqrt(49),mean(gap2(:,rr)),std(gap2(:,rr))/sqrt(49),STATS.tstat,P)

end