## Neural detection of socially valued community members
This repository hosts the online supplement for the paper: 
"Neural detection of socially valued community members" (Morelli, Leong, Carlson, Kullar, & Zaki, in press)

For a preprint of the paper, please contact Sylvia Morelli at smorelli@uic.edu.  

### Social Network Nominations
#### Data
[Nomination Matrices](Nomination_matrices): Adjacency matrices of nominations for each of the 8 social network questions for the larger sample of 197 participants, as well as a matrix that represents the weighted average of these 8 questions

#### Analyses
[Factor Analysis](Factor_analysis): Factor analysis on indegree for each of the eight questions, using the full sample (i.e., 97 participants)

### Pre-Scan Ratings of Dorm Relationships
[Pre-Scan Ratings](Prescan_ratings): Anonymized data of scanner participants' ratings of each dorm member on various dimensions 

### Neuroimaging Tasks
#### Face Viewing
[Face Selection Algorithm](fmri_tasks/face_selection_algorithm/face_selection_algorithm.R): Script for selecting 30 target faces for each participant based on their pre-scan ratings

[Face Selection Files](fmri_tasks/NetworkSelection): 30 target faces selected for each participant produced by the face selection algorithm

[Face Viewing Task](fmri_tasks/faces/Faces.m): Main script to run the face-viewing task (but missing the folder of target photos to maintain anonymity)

[Face Viewing Task Output](fmri_tasks/faces/data): Recorded onsets & durations for stimuli, as well as button presses

[Preprocessing scripts](fmri_tasks/preprocessing): SPM preprocessing scripts for all tasks (including face viewing)

[First-level scripts for parametric analyses](fmri_tasks/faces_firstlevel_parametric): SPM subject-level scripts for parametric modulation

[First-level scripts for hub categories](fmri_tasks/faces_firstlevel_hubcategories): SPM subject-level scripts used to generate hub categories (median split, terciles, & quartiles) for univariate and multivariate prediction analyses

[Parametric_analyses](Parametric_analyses): T maps for the parametric analyses reported in the paper and supporting appendix which can also be viewed in our [NeuroVault Collection](https://neurovault.org/collections/2715/) 

#### Functional Reward Localizer 
[Modified Monetary Incentive Delay Task](fmri_tasks/modified_MID/SelfMID.m): Main script to run the modified MID (but missing the folder of photos to maintain anonymity)

[MID Output](fmri_tasks/modified_MID/data): Recorded onsets & durations for stimuli, as well as button presses

[Preprocessing scripts](fmri_tasks/preprocessing): SPM preprocessing scripts for all tasks (including MID)

[First-level scripts](fmri_tasks/modified_MID_firstlevel):SPM subject-level scripts

### Prediction Analyses
#### Data 
Data for the prediction analyses reported in the paper can be downloaded [here](https://drive.google.com/drive/folders/0B3bXlQXiUgwWemJtWWdTb0p2Tkk). Each participant's subfolder (SN_XXX) contains three pairs of .img/.hdr files. Each pair contains a t-map associated with a particular hub category:

* spmT_0001 - High hub category  
* spmT_0002 - Middle hub category    
* spmT_0003 - Low hub category  

ROI masks used for the analyses can be found [here](masks)

#### Scripts
[UnivariatePrediction.m](scripts/UnivariatePrediction.m): Follows a leave-one-participant-out cross-validation procedure to predict hub category from the average t-values of held-out data in a given ROI.  

[MultivariatePrediction.m](scripts/MultivariatePrediction.m): Follows a leave-one-participant-out cross-validation procedure to train a LASSO-PCR algorithm to predict hub category from neural patterns of held-out data in a given ROI.    
- [MultivariatePrediction_zSpace.m](zSpace_scripts/MultivariatePrediction_zSpace.m): Same analysis with the mean ROI signal removed

[Compare_RMSE.m](scripts/Compare_RMSE.m): Compares univariate and multivariate prediction accuracy using root mean squared error (RMSE). 

[ParcelSearchLightAnalysis.m](scripts/whole-brain/ParcelSearchLightAnalysis.m): Prediction analyses using whole-brain parcellation ROIs.  

The following folders contain scripts for additional control analyses.  

[Median_scripts](Median_scripts): Analyses when splitting data into two bins   

[Quartile_scripts](Quartile_scripts): Analyses when splitting data into four bins  

[NoControlScripts](NoControlScripts): Analyses when not controlling for personal nomination and closeness  

[WS_prediction](WS_prediction): Within-Subject Prediction Analyses  

[Comparing increase in response between terciles](output_prediction)

#### Pattern Weights
Multivariate pattern weights learned by LASSO-PCR algorithm for each ROI can be found [here](results/MVPA) ([roi_name.nii])  

#### Dependencies  
To run the prediction scripts, you will need to download the following toolboxes:  
* [CANlabCore Toolbox](https://github.com/canlab/CanlabCore)   
* [NifTI toolbox](https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image)  
* [SPM](http://www.fil.ion.ucl.ac.uk/spm/)  
