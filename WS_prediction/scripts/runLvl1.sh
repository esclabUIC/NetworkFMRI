#!/bin/bash
export FSLPARALLEL=slurm

# Set Parameters
#subjNo=("201" "203" "204" "207" "210" "213" "214" "215" "216" "217" "219" "220" "221" "224" "226" "227" "229")
#subjNo=("233" "234" "235" "236" "237" "241" "242" "245" "246" "301" "305" "306" "307" "308" "311" "312" "314")
#subjNo=("318" "321" "326" "331" "333" "335" "336" "341" "343" "344" "346" "348" "349" "350" "351" "315")
subjNo=("201")
design="faces60"

mkdir '../fsfs/'$design

for subjID in "${subjNo[@]}"
	do

        thisFile=/Users/ssnl/Documents/Social_Network_Study_Active/SN_$subjID/raw/BOLD_sn1_Faces/sw*.nii
        
        \cp ../templates/${design}.fsf ../fsfs/$design/subj${subjID}.fsf
		
		sed -i -e 's#ChangeMyFile#'${thisFile}'#' ../fsfs/$design/subj${subjID}.fsf
        sed -i -e 's#ChangeMySubj#'$subjID'#' ../fsfs/$design/subj${subjID}.fsf  #Swap "ChangeMyRun" with run number
        sed -i -e 's#ChangeMyDesign#'$design'#' ../fsfs/$design/subj${subjID}.fsf  #Swap "ChangeMyRun" with run number

        rm '../fsfs/'$design/*-e #Remove excess schmutz

        echo Running Subj $subjID
        feat ../fsfs/$design/subj${subjID}.fsf
done
