from __future__ import print_function
from applyNetwork import run

import os
try:
	import tensorflow
except ImportError:
	print_function('You must install tensorflow:\n https://www.tensorflow.org/install/')

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'

def main(data_folder):
	if '/' or '\\' not in data_folder:
		data_folder = os.path.join(os.getcwd(), data_folder)
	run(data_folder)

