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

* Place split detection crops into a folder (path/to/crops)
    - Filenames should be of the form INITIAL_XXXX_WHATEVER.tif
* Build .csv file containing the micro meter to pixel information. If we have two subjects mm_0001 and mm_0002 wherein there are 0.76 um per pixel and 0.85 um per pixel respectively, then the csv file will be of the following form:
    ```buildoutcfg
    mm_0001, 0.76
    mm_0002, 0.85
    ```
* Place the csv file into the same folder as crops
* To run the method, and manually correct its output enter:
```buildoutcfg
cone_detector -f path/to/crops -m y
```
to let it run and save uncorrected output:
```buildoutcfg
cone_detector -f path/to/crops -m n
```

##Output
Once complete a folder will be saved containing
```buildoutcfg
dateTime/
    Images/
    AlgorithmLocations/
    AlgorithmFigures/
    CorrectedLocations/
    CorrectedFigures/
    stats.csv
```
The figures folders contain images of the input tifs, with the cone locations overlayed on top of them. The locations folders contain csv file with the location of cones in each image.

The stats.csv file contains commonly used metrics on each image.

