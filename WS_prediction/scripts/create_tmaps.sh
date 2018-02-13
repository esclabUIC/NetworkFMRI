#!/bin/bash
# export FSLPARALLEL=slurm

# Set Parameters
#subjNo=("201" "203" "204" "207" "210" "213" "214" "215" "216" "217" "219" "220" "221" "224" "226" "227" "229" "233" "234" "235" "236" "237" "241" "242" "245" "246" "301" "305" "306" "307" "308" "311" "312" "314" "318" "321" "326" "331" "333" "335" "336" "341" "343" "344" "346" "348" "349" "350" "351" "315")
#subjNo=("201" "314" "318" "321" "326" "331")
#subjNo=("333" "335" "336" "341" "343" "344")
subjNo=("346" "348" "349" "350" "351" "315")

# subjNo=("201")

design="faces60"

mkdir "../glm/${design}_tmap"

for subjID in "${subjNo[@]}"
	do
    echo Running Subj $subjID
    
    outfile="../glm/${design}_tmap/subj${subjID}_tmap.nii.gz"
    
    \cp ../glm/$design/subj$subjID.feat/stats/tstat1.nii.gz $outfile

	for reg in {2..60}
		do
		fslmerge -t $outfile $outfile ../glm/$design/subj$subjID.feat/stats/tstat${reg}.nii.gz
	done
done
