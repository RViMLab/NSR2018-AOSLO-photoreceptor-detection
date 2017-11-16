Cone Detection
--------------

1. install tensorflow https://www.tensorflow.org/install/

2. pip install cone-detector

3. run
	::
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
	