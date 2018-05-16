# Automatic Cone Photoreceptor Localisation with MDRNNs

This repo contains an implementation of the method described in:
```
PAPER REF
```
cite this paper if you use the code.

## Getting Started
All you need to install and use the code is Python 3.5.x or 3.6.x.
### Installing
1. Download the git repository to a folder of your choice, /path/to/code/ConeDetector

2. Install Python package using pip

Ubuntu
```
    pip install /path/to/code/ConeDetector
```
Windows
```
    python -m pip install /path/to/code/ConeDetector
```

###Using

* Place split detection crops into a folder. Filenames should be of the form 
```
INITIAL_XXXX_WHATEVER.tif
```
* Build .csv file containing the um to pixel information. If we have two subjects mm_0001 and mm_0002 wherein there are 0.76 um per pixel and 0.85 um per pixel respectively, then the csv file will be of the following form:
    ```buildoutcfg
    mm_0001, 0.76
    mm_0002, 0.85
    ```
* To run the method open a cmd prompt or terminal and enter:
```
cone_detector
```
* Configure how you want to run the method. If the bright sides of cones are to the left, mark the check box.
##Output
Once complete a folder will be saved containing
```
dateTime/
    Images/
    AlgorithmLocations/
    AlgorithmFigures/
    CorrectedLocations/
    CorrectedFigures/
    stats.csv
```

The images folder contains the images which were fed to the network. These are all square, as due to the current implementation we can only apply the network to square images. Igf a non-square image is contained in the input data the largest possible square image will be cropped from the center of the image, and fed to the network instead.

The figures folders contain images of the input tifs, with the cone locations overlayed on top of them. The locations folders contain csv file with the location of cones in each image.

The stats.csv file contains commonly used metrics on each image.



