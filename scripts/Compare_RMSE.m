%% Compare_RMSE
% YC Leong 7/17/2017 
% This script tests if RMSE is significantly different between MVPA and Univariate Prediction
% Assumes that the scripts UnivariatePrediction.m and MultivariatePrediction.m have already been run

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                             Setup                                                % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all

% Set Directories 
dirs.Univariate = fullfile('../results/Univariate');
dirs.MVPA = fullfile('../results/MVPA');

roi_names = {'Mentalizing','MPFC','PMC','LTP','RTP','LTPJ','RTPJ','Striatum','V1'};
roi_files = {'mentalizing.nii','MPFCswath.nii','PrecunPCC.nii',...
    'RTPJ.nii','LTPJ.nii','RTempPoles.nii','LTempPoles.nii','BilatVS_Plus5Win5_Lose0.nii','V1.nii'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                         Load Files                                              % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for rr = 1:length(roi_names)
    Y = repmat([1,2,3],50,1);
    
    % Load Univariate Results
    load(sprintf('%s.mat',fullfile(dirs.Univariate,roi_files{1,rr}(1:end-4))));
    allRMSE{rr,1}(:,1) = sqrt(mean((pred_by_bin - Y).^2,2));
    
    % Load Multivariate Results
    load(sprintf('%s.mat',fullfile(dirs.MVPA,roi_files{1,rr}(1:end-4))));
    allRMSE{rr,1}(:,2) = sqrt(mean((pred_by_bin - Y).^2,2));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       Compute RMSE Difference                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for rr = 1:length(roi_names)
    [H, P, CI, stats] = ttest(allRMSE{rr,1}(:,1),allRMSE{rr,1}(:,2));
    
    fprintf('%s: RMSE_MVPA = %0.3f, RMSE_ROI = %0.3f, t(%i)=%0.3f, p=%0.3f\n',...
        roi_names{rr},mean(allRMSE{rr,1}(:,1)),mean(allRMSE{rr,1}(:,2)),stats.df,stats.tstat,P)
end

% Null Model
Y = repmat([1,2,3],30,1);
Y_Null = repmat([2,2,2],30,1);
RMSE = mean(sqrt(mean((Y_Null - Y).^2,2)));

fprintf('Null Model RMSE = %0.3f,\n',RMSE)
