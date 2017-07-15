%% Social Network Regression scripts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                   Log                                                    % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% YC Leong 3/6/17
%    - Mean Activity
%
%
%

clear all
run_regression = 1;
reg_type = 'Pearson';
explained_threshold = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                   Aesthetics                                             % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
font_size = 18;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                             Script Parameters                                            % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Tor's toolbox
addpath(genpath('CanlabCore')) 
addpath(genpath('NIfTI')) 
dirs.root = '/Users/ssnl/Documents/Social_Network_Study_Active';

run_this = 'CntrlBoth';
dirs.results = fullfile('/Users/ssnl/Documents/YC_Social_Network_Study/results/ConfoundControlled_ROI',sprintf('%s_PC_%i',run_this,explained_threshold));

switch run_this
    case 'CntrlPersonalNom'
        toRuns = 'FacesIndegreeFactorCntrlBin_Cntrl4PersNoms';
    case 'CntrlCloseness'
        toRuns = 'FacesIndegreeFactorCntrlBin_Cntrl4Closeness';
    case 'CntrlBoth'
        toRuns = 'FacesIndegreeFactorCntrlBin_Cntrl4ClosePersNom';
end
mkdir(dirs.results);

% masks
dirs.mask = fullfile('/Users/ssnl/Documents/YC_Social_Network_Study/masks/3x3_analysis');
mask_files = {'mentalizing.nii','MPFCswath.nii','BilatVS_Plus5Win5_Lose0.nii','PrecunPCC.nii',...
    'RTPJ.nii','LTPJ.nii','RTempPoles.nii','LTempPoles.nii','V1.nii','brainmask.nii'};

nmask = length(mask_files);

% subj
Subjects = load('../subject_numbers.txt');
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
        
        [temp temp2] = sort(pred_by_bin(s,:));
        
        for b = 1:3
            rank_by_bin(s,b) = find(temp2 == b);
        end

       
        within_sub_corr(s) = corr(this_y,this_yfit,'type',reg_type);
        
    end
    
    save(sprintf('%s_%s.mat',fullfile(dirs.results,mask_files{1,mm}(1:end-4)),reg_type),...
        'rank_by_bin','pred_by_bin','within_sub_corr','stats');

    % % Plot pred_by_bin
    fig = figure();
    hold on
    set(gcf,'Position',[100 100 500 400]);
    
    % Plot Bar Graph instead
    x = [1:3];
    y = mean(pred_by_bin);
    err_bar = std(pred_by_bin)/sqrt(length(pred_by_bin));
    
    bar_col = [137,202,250;
        61,134,250;
        255,180,51];
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
     
end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                                       Plot Bar Graph                                                     % 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% % 
roi_names = {'Mentalizing','MPFC','PMC','RTPJ','LTPJ','RTP','LTP','VS','V1','Whole Brain'};
roi_files = {'mentalizing.nii','MPFCswath.nii','PrecunPCC.nii','RTPJ.nii','LTPJ.nii','RTempPoles.nii','LTempPoles.nii','BilatVS_Plus5Win5_Lose0.nii','V1.nii','brainmask.nii'};

all_corr = NaN(nSub,length(roi_names));
all_npc = NaN(1,length(roi_names));

for rr = 1:length(roi_names)
    fprintf('%s\n',roi_names{rr});
    load(sprintf('%s_%s.mat',fullfile(dirs.results,roi_files{1,rr}(1:end-4)),reg_type));
    
    all_corr(:,rr) = within_sub_corr;
end

% Plot within_corr
fig = figure();
hold on
set(gcf,'Position',[100 100 1000 400]);

y = mean(all_corr);
err = std(all_corr)/sqrt(nSub);

x = [1:nmask];
    
for i = 1:nmask
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


