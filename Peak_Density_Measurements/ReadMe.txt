!MAKE SURE THE CROPPED IMAGED TO BE ANALYSED IS GRAYSCALE!

Peak Cone Density Analysis

Step 1:  Open scaleLUT.csv and set up as follows:
	-1st column is subject ID
	-2nd column is axial length for eye of interest
	-3rd column is the pixels/degree for the image scale used

Step 2:  Open local_meas_mel_vers.m in Matlab and set up as follows:
	-Line 16 is the path of the scaleLUT.csv file
	-Line 17 is the path of the image's cone coordinates text file
	-Line 150, change the second number to correspond to the row number of the subject in the scaleLUT.csv file

Step 3:  Open multipleWindows.m in Matlab
	-Be sure box sizes are set to desired values
	-Run the program to loop through local_meas_mel_vers.m
	-Outputs will include nearest neighbor, inter-cone spacing, and cone density information for all box sizes as well as locations of peak cone density and corresponding density matrices for each box size and other summary csv files.

Step 4:  Open avePeaks.m in Matlab
	-Run the program to find the location of peak density in the average density matrix
	-Location of top 5 peaks will be output to csv files and the corresponding densities will as well

Step 5:  Return to the 37um box size density matrix to lookup the coordinates of the first peak output from step 4.
	-If there are multiple locations with the highest peak density in the average, take the average of these coordinates to find peak density.
	-The density value in the 37um matrix at the peak coordinates is the peak cone density value to report.

***The location of peak density in the image corresponding to the coordinate file is the sum of coordinates in the Max_1_locations plus the offset (in Offset file).***