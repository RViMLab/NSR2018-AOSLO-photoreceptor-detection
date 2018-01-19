from __future__ import print_function
from applyNetwork import run
from matplotlib_gui import Annotator
from output_builder import build_output

import os
import pickle

try:
    import tensorflow
except ImportError:
    print('You must install tensorflow:\n https://www.tensorflow.org/install/')

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'

def main(data_folder):

    # if single string then use current directory
    if '/' or '\\' not in data_folder:
        data_folder = os.path.join(os.getcwd(), data_folder)

    # apply network and generate estimated
    outputs = run(data_folder)

    # manually correct
    Annotator(outputs)

    # use corrected
    current_directory = os.path.dirname(os.path.realpath(__file__))
    filename = os.path.join(current_directory, 'annotationState.pickle')
    with open(filename, 'rb') as handle:
            corrected = pickle.load(handle)

    # create output
    build_output(corrected)