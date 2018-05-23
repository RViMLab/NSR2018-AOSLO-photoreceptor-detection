# Automatic Cone Photoreceptor Localisation with MDRNNs

This repo contains an implementation of the method described in [this paper](https://www.nature.com/articles/s41598-018-26350-3). Please cite the paper if you use the code.
```
@Article{Davidson2018,
    author={Davidson, Benjamin
    and Kalitzeos, Angelos
    and Carroll, Joseph
    and Dubra, Alfredo
    and Ourselin, Sebastien
    and Michaelides, Michel
    and Bergeles, Christos},
    title={Automatic Cone Photoreceptor Localisation in Healthy and Stargardt Afflicted Retinas Using Deep Learning},
    journal={Scientific Reports},
    year={2018},
    volume={8},
    number={1},
    pages={7911},
    issn={2045-2322},
    doi={10.1038/s41598-018-26350-3},
    url={https://doi.org/10.1038/s41598-018-26350-3}
}


```

## Getting Started
To install and use requires:
* Python 3.5.x or 3.6.x
* pip

### Installing
1. Download the git repository to a folder of your choice, /path/to/code/ConeDetector

2. Install Python package using pip. Ubuntu: ```pip install /path/to/code/ConeDetector```; Windows```python -m pip install /path/to/code/ConeDetector```

3. 
    * If you do not have a gpu, pip install tensorflow: Ubuntu```pip install tensorflow```; Windows```python -m pip install tensorflow```
    * If you do have a gpu, follow these [instructions](https://www.tensorflow.org/install/) to install tensorflow-gpu
    
If you just want to apply the model from the paper, you only need tensorflow, not tensorflow-gpu. The gpu version is needed if you want to train new models in any reassonable amount of time.
### Using

* Any images should be of the form, where xxxx is a number with leading zeros, eg 1==0001

```
INITIAL_XXXX_WHATEVER.tif
```

* The required lut.csv for applying models should be of the following form, if we have two subjects, for example, with a um to pixel of 0.76 and 0.85 respectively.
```
    INITIAL_0001, 0.76
    INITIAL_0002, 0.85
```

* To run the code open a cmd prompt, or terminal and enter:

```
cone_detector
```


## Features
After running cone_detector from a terminal a gui will launch asking what you want to do.
### Apply existing models
* Required: folder of tifs, lut.csv for each subject in folder
* Applies model to tifs to estimate locations
* Can simply trust the algorithm, or manually correct each image
* Outputs locations and stats for each image
### Build training data sets for training new models
* Required: folder of tifs
* Create labeled data in format used by tensorflow to train new models
* Can select a model to aid the annotations, or do completely by hand
* Will save data set as tfrecord, to train new models
### Train new models
* Required: training data set built using cone_detector
* Optional: a validation data set created using cone_detector
* Will run same training regime described in the paper (if validation data given), otherwise will train for 100 epochs
* Saves new model, which can be applied in cone_detector




