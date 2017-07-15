%% Multivariate Prediction
% YC Leong 7/15/2017 
% This scripts takes in beta maps associated which each hub category of all 50 participants, and 
% trains a Lasso-PCA algorithm to predict hub category following a leave-one-participant-out 
% cross-validation procedure.
% 
% Parameters:
%   run_regression: 1 = run the regression analyses, 0 skip the regression analyses and go to
%   summary figures
%   
%   explained_threshold = cumulative % of variance explained of retained components 
% 
% Dependencies:
%   CANlabCore Toolbox available at https://github.com/canlab/CanlabCore
%   NifTI toolbox available at 
%        https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image

clear all
run_regression = 1;
explained_threshold = 35;
font_size = 24;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                             Setup                                               % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Toolboxes
addpath(genpath('CanlabCore')) 
addpath(genpath('NIfTI')) 

% Set Directories 
dirs.data = '../data';
dirs.masks = '../masks';
dirs.results = '../results';
dirs.input = fullfile(dirs.data,'FacesIndegreeFactorCntrlBin_Cntrl4ClosePersNom');
dirs.output = fullfile(dirs.results,'ConfoundControlled');

% Make output directory if it doesn't exist
if ~exist(dirs.output)
    mkdir(dirs.output);
end

% ROI Information 
mask_files = {'mentalizing.nii','MPFCswath.nii','PrecunPCC.nii',...
    'RTPJ.nii','LTPJ.nii','RTempPoles.nii','LTempPoles.nii','V1.nii','BilatVS_Plus5Win5_Lose0.nii','brainmask.nii'};
nmask = length(mask_files);

% Subject Information 
Subjects = load(fullfile(dirs.data,'subject_numbers.txt'));
nSub = length(Subjects);

% number of bins
nbins = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                            Regression                                                    % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if run_regression

    % Loop over ROIs
    for mm = 1:nmask
        this_mask = fullfile(dirs.mask,mask_files{1,mm});
        fprintf('Running ROI: %s \n', this_mask);
        
        i = 1;
        
        % Get paths
        for s = 1:nSub
            train_data = fullfile(dirs.root,sprintf('SN_%s',num2str(Subjects(s))),'analysis',toRuns);
            
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
        
        
        if explained_threshold == 100
            
            
            [cverr, stats, optout] = predict(AllTrain, 'algorithm_name', 'cv_lassopcr', 'nfolds', SubID);
            explained = NaN;
            cumsum_explained = NaN;
            nPC = NaN;
        else
            
            
            
            [coeff,score,latent,tsquared,explained,mu] = pca(AllTrain.dat);
            cumsum_explained = cumsum(explained);
            nPC = find(cumsum_explained > explained_threshold,1);
            [cverr, stats, optout] = predict(AllTrain, 'algorithm_name', 'cv_lassopcr', 'nfolds', SubID, 'numcomponents',nPC);
        end
        
        stats.weight_obj.dat = stats.weight_obj.dat/std(stats.weight_obj.dat);
        unthresholded = stats.weight_obj;
        unthresholded.fullpath = fullfile(dirs.results,sprintf('%s.nii',mask_files{1,mm}(1:end-4)));
        write(unthresholded);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                                       Within Subject Stats                                               %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        within_sub_corr = NaN(nSub,1);
        pred_by_bin = NaN(nSub,3);
        rank_by_bin = NaN(nSub,3);
        
        for s = 1:nSub
            this_yfit = stats.yfit(SubID == s);
            this_y = stats.Y(SubID == s);
            
            for b = 1:3
                pred_by_bin(s,b) = this_yfit(this_y == b);
            end
            
            [temp temp2] = sort(pred_by_bin(s,:));
            
            for b = 1:3
                rank_by_bin(s,b) = find(temp2 == b);
            end
            
            within_sub_corr(s) = corr(this_y,this_yfit);
            
        end
        
        save(sprintf('%s_%s.mat',fullfile(dirs.results,mask_files{1,mm}(1:end-4)),reg_type),...
            'rank_by_bin','pred_by_bin','within_sub_corr','stats','explained','cumsum_explained','nPC');
        
        % % Plot pred_by_bin
        fig = figure();
        hold on
        set(gcf,'Position',[100 100 500 400]);
        
        % Plot Bar Graph instead
        x = [1:3];
        y = mean(pred_by_bin);
        err_bar = std(pred_by_bin)/sqrt(length(pred_by_bin));
        
        bar_col = [203,24,29;
            252,174,145;
            251,106,74];
        bar_col = bar_col/255;
        
        for i = 1:length(y)
            b = bar(x(i),y(i),0.6);
            set(b,'facecolor',bar_col(i,:))
        end
        
        h = errorbar(x,y,err_bar);
        set(h,'Color',[0,0,0],'linestyle','none');
        
        set(gca,'xtick',[1:3])
        set(gca,'ytick',[1:3]);
        
        ylabel('Average Predicted Level');
        xlabel('Social Supportiveness');
        
        axis([0 4 0 3]);
        set(gca,'FontSize',20)
        
        fig_dest = fullfile(dirs.results,sprintf('%s_pred_by_bin',mask_files{1,mm}(1:end-4)));
        set(gcf,'paperpositionmode','auto');
        print(fig,'-depsc',fig_dest);
        
        % Plot rank_by_bin
        fig = figure();
        set(gcf,'Position',[100 100 500 400]);
        hold on
        
        hf = plot([1:3],mean(rank_by_bin),'r');
        set(hf,'color','r','LineWidth',3)
        
        h = errorbar([1:3],mean(rank_by_bin),std(rank_by_bin)/sqrt(nSub));
        set(h,'Color','r','linestyle','none','LineWidth',3);
        
        xlabel(sprintf('indegree'));
        ylabel(sprintf('prediction'));
        title(mask_files{1,mm}(1:end-4))
        set(gca,'FontSize',font_size)
        set(gca,'xtick',[1:3]);
        set(gca,'ytick',[1:3]);
        axis([0.75 3.25 0.75 3.25]);
        
        fig_dest = fullfile(dirs.results,sprintf('%s_rank_by_bin',mask_files{1,mm}(1:end-4)));
        set(gcf,'paperpositionmode','auto');
        print(fig,'-depsc',fig_dest);
        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                       Plot Bar Graph                                                     % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

roi_names = {'Mentalizing','MPFC','PMC','RTPJ','LTPJ','RTP','LTP','VS','V1','WholeBrain'};
roi_files = {'mentalizing.nii','MPFCswath.nii','PrecunPCC.nii','RTPJ.nii','LTPJ.nii','RTempPoles.nii','LTempPoles.nii','BilatVS_Plus5Win5_Lose0.nii','V1.nii','brainmask.nii'};

all_corr = NaN(nSub,length(roi_names));

for rr = 1:length(roi_names)
    fprintf('%s\n',roi_names{rr});
    load(sprintf('%s_%s.mat',fullfile(dirs.results,roi_files{1,rr}(1:end-4)),reg_type));
    
    all_corr(:,rr) = within_sub_corr;
    all_npc(1,rr) = nPC;
end

% Plot within_corr
fig = figure();
hold on
set(gcf,'Position',[100 100 1000 400]);

y = mean(all_corr);
err = std(all_corr)/sqrt(nSub);

x = [1:length(roi_names)];
    
for i = 1:length(roi_names)
    b = bar(x(i),y(i),0.7);
    set(b,'facecolor',[0.2 0.2 0.2])
end

h = errorbar(x,y,err);
set(h,'Color',[0,0,0],'linestyle','none');

ylabel('Correlation');

set(gca,'xtick',[1:length(roi_names)],'xticklabel',roi_names)

axis([0 length(roi_names)+1 -0.2 0.6]);
set(gca,'FontSize',20)

fig_dest = fullfile(dirs.results,sprintf('all_corr_%s',reg_type));
set(gcf,'paperpositionmode','auto');
print(fig,'-depsc',fig_dest);


