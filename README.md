## Neural detection of socially valued community members
This repository hosts the online supplement for the paper "Neural detection of socially valued community members" (Morelli et. al, in prep).  
For a preprint of the paper, please contact Sylvia Morelli at smorelli@uic.edu.  

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
- [MultivariatePrediction_zSpace.m](zSpace_scripts/MultivariatePrediction.m): Same analysis with the mean ROI signal removed

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
