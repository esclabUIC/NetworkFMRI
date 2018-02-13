%% Parcel Searchlight
% YC Leong 12/13/2017 
% Runs multivariate analysis on neurosynth parcels 
% For each parcel, calculates RMSE and saves t as well as p statistic 

clear all

run_regression = 0;
explained_threshold = 35;
nParcel = 80;

parcellation = sprintf('Craddock_tcorr05_2level_%i',nParcel);

font_size = 24;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                             Setup                                               % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Toolboxes
addpath(genpath('../../../CanlabCore')) 
addpath(genpath('../../../NIfTI')) 
addpath(genpath('../')) 
addpath(genpath('/Users/yuanchangleong/Documents/spm12'))

% Set Directories 
dirs.data = '../../data';
dirs.mask = fullfile('../../masks', parcellation);
dirs.results = '../../results';
dirs.input = fullfile(dirs.data,'FacesIndegreeFactorCntrlBin_Cntrl4ClosePersNom');
dirs.output = fullfile(dirs.results,'WholeBrain');

% Make output directory if it doesn't exist
if ~exist(dirs.output)
    mkdir(dirs.output);
end

% Subject Information 
Subjects = load(fullfile(dirs.data,'subject_numbers.txt'));
nSub = length(Subjects);

% number of bins
nbins = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                          Regression                                              % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if run_regression

    % Loop over ROIs
    for mm = 1:nParcel
        
        this_mask = fullfile(dirs.mask,sprintf('%s_%i.nii',parcellation,mm));
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
            % [cverr, stats, optout] = predict(AllTrain, 'algorithm_name', 'cv_lassopcr', 'nfolds', SubID);
        end
        
        % Print out regression weight for each voxel
%         stats.weight_obj.dat = stats.weight_obj.dat/std(stats.weight_obj.dat);
%         unthresholded = stats.weight_obj;
%         unthresholded.fullpath = fullfile(dirs.output,sprintf('%s.nii',mask_files{1,mm}(1:end-4)));
%         write(unthresholded);
        
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
        
        predY = repmat([1,2,3],50,1);
        rmse =  sqrt(mean((pred_by_bin - predY).^2,2));
        
        save(sprintf('%s.mat',fullfile(dirs.output,sprintf('%s_%i',parcellation,mm))),...
            'pred_by_bin','within_sub_corr','stats','explained','cumsum_explained','nPC','rmse');  
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                        Calculate RMSE                                            % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t_value = zeros(nParcel,1);
p_value = ones(nParcel,1);


% Loop over ROIs
for mm = 1:nParcel
    this_mask = fullfile(dirs.mask,sprintf('%s_%i.nii',parcellation,mm));
    fprintf('Running ROI: %s \n', this_mask);
    
    if exist(sprintf('%s.mat',fullfile(dirs.output,sprintf('%s_%i',parcellation,mm))))
        load(sprintf('%s.mat',fullfile(dirs.output,sprintf('%s_%i',parcellation,mm))))
        
        [H P CI STATS] = ttest(rmse, 0.8165,'tail','left');
        t_value(mm,1) = STATS.tstat;
        p_value(mm,1) = P;
    end
    
    
    
end

% Load map for reference 
parcel_nifti = load_nii(fullfile(dirs.mask,sprintf('%s.nii',parcellation)));
data = int16(parcel_nifti.img);
datasize = size(data);
 
% Save p_map
inv_p = 1-p_value;
this_map = zeros(datasize);
for i = 1:nParcel
    this_map(data == i) = inv_p(i);  
end
parcel_nifti.img = double(this_map);
parcel_nifti.hdr.dime.datatype = 64;

save_nii(parcel_nifti,fullfile(dirs.output,'maps',sprintf('%s_1-pmap.nii',parcellation)));

% Save t_map
inv_p = t_value;
this_map = zeros(datasize);
for i = 1:nParcel
    this_map(data == i) = inv_p(i);  
end
parcel_nifti.img = double(this_map);
save_nii(parcel_nifti,fullfile(dirs.output,'maps',sprintf('%s_tmap.nii',parcellation)));

% Save 1-t_map
inv_p = t_value*-1;
this_map = zeros(datasize);
for i = 1:nParcel
    this_map(data == i) = inv_p(i);  
end
parcel_nifti.img = double(this_map);
save_nii(parcel_nifti,fullfile(dirs.output,'maps',sprintf('%s_tmap.nii',parcellation)));


% Save thresholded t_map
[h crit_p]=fdr_bky(p_value,0.05,'yes');
% inv_p = t_value*-1;
inv_p(~h) = 0;
inv_p(p_value > 0.01) = 0;
this_map = zeros(datasize);
for i = 1:nParcel
    this_map(data == i) = inv_p(i);  
end
parcel_nifti.img = double(this_map);
save_nii(parcel_nifti,fullfile(dirs.output,'maps',sprintf('%s_threshold_tmap.nii',parcellation)));

