#!/bin/sh

# Break up parcellation into separate ROIs
# Resample to 3mm

# Which mask to use? Start with the mask with 50 parcellations
this_mask=80

# mask_dir
mask_dir=../../masks/Craddock_tcorr05_2level_${this_mask}

orig_file=$mask_dir/Craddock_tcorr05_2level_${this_mask}.nii.gz
in_file=$mask_dir/Craddock_tcorr05_2level_${this_mask}_hack.nii.gz

# Bash can't do floating point arithmetic - so hacking it by multiplying it by 10...
fslmaths $orig_file -mul 10 $in_file

# Loop over parcels
all_parc=($(seq 10 10 800))

for parc in "${all_parc[@]}"
	do
	echo Running parcel $((parc/10))

	#echo Running parcel $((parc-parc/10))

    interm_file=${mask_dir}/Craddock_tcorr05_2level_${this_mask}_$((parc/10)).nii.gz

    # Isolate this parcel
    fslmaths $in_file -thr $((parc-1)) -uthr $((parc+1)) $interm_file

		fslmaths $interm_file -bin $interm_file

		gunzip $interm_file

done
