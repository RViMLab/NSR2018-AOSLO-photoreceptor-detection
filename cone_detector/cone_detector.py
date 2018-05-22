# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import os
import pickle
from .applyNetwork import locate_cones_with_model
from .annotation_gui import Annotator
from .output_writer import OutputWriter
from .dataset import DataSet
from .train import train_model


def apply(data_folder, lut_csv, mname, manual, brightDark):
    """
        - applies network to all tifs in data_folder
        - runs an interactive gui on these results for cleanup
            this saves its output as a pickle file
        - load pickle file and run metrics on it
    """

    # apply network and generate estimated
    print('Applying method to data')
    outputs = locate_cones_with_model(data_folder, brightDark, mname)

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
    writer = OutputWriter(outputs, data_folder, lut_csv)
    writer.write_output()

def data(data_folder, brightDark, data_name, mname):
    """Build training data set"""

    # get network output, if mname is none then returns empty
    # centers
    outputs = locate_cones_with_model(data_folder, brightDark, mname)

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
    dataset = DataSet(data_name)
    dataset.create_dataset(outputs)


def train_new(train_data_name, val_data_name, mname, brightDark):
    train_model(mname, train_data_name, brightDark, val_data_name)


