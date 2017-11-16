Cone Detection
--------------

To use install and then call

$ cone_detector -f path/to/image_folder

This will locate cones in all images in image_folder and create the following file structure in the current working directory:
::
	datetime.now
		images
			cropped_images
		figures
			cropped images showing estimated cone loactions
		markers
			locations as csv files
	