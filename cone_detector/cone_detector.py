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

try:
    import tensorflow
except ImportError:
    print('You must install tensorflow:\n https://www.tensorflow.org/install/')

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'


def main(data_folder, lut_csv, manual, brightDark):
    """
        - applies network to all tifs in data_folder
        - runs an interactive gui on these results for cleanup
            this saves its output as a pickle file
        - load pickle file and run metrics on it
    """
    # if single string then use current directory
    if '/' or '\\' not in data_folder:
        data_folder = os.path.join(os.getcwd(), data_folder)

    # apply network and generate estimated
    print('Applying method to data')
    outputs = run(data_folder, brightDark)

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

