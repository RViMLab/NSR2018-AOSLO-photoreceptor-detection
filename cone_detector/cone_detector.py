# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import os
import pickle
import sys

from .applyNetwork import run
from .annotation_gui import Annotator
from .output_builder import build_output
from .build_tfrecord import write_dataset
from .train import train_model
try:
    import tensorflow
except ImportError:
    print('You must install tensorflow:\n https://www.tensorflow.org/install/')

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'


def apply(data_folder, lut_csv, mname, manual, brightDark):
    """
        - applies network to all tifs in data_folder
        - runs an interactive gui on these results for cleanup
            this saves its output as a pickle file
        - load pickle file and run metrics on it
    """

    # apply network and generate estimated
    print('Applying method to data')
    outputs = run(data_folder, brightDark, mname)

    # will manually correct in gui
    if manual==True:
        # manually correct
        Annotator(outputs)

        # use corrected
        if os.name == 'nt':
            temp_dir = 'C:\\Windows\\Temp'
        else:
            temp_dir = '/tmp'

        filename = os.path.join(temp_dir, 'annotationState.pickle')
        with open(filename, 'rb') as handle:
            outputs = pickle.load(handle)['outputsAfterAnnotation']



    # create output
    print('Building Output')
    corrected = manual
    build_output(outputs, data_folder, lut_csv, corrected)

def data(data_folder, brightDark, data_name, mname):
    """Build training data set"""

    # get network output, if mname is none then returns empty
    # centers
    outputs = run(data_folder, brightDark, mname)

    # manually correct
    Annotator(outputs)

    # use corrected
    if os.name == 'nt':
        temp_dir = 'C:\\Windows\\Temp'
    else:
        temp_dir = '/tmp'

    filename = os.path.join(temp_dir, 'annotationState.pickle')
    with open(filename, 'rb') as handle:
        outputs = pickle.load(handle)['outputsAfterAnnotation']

    # build tfrecord
    write_dataset(data_name, outputs)


def train_new(data_name, mname):
    train_model(mname, data_name)


