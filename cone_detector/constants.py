import os

# data locations
PACKAGE_DIREC = os.path.dirname(os.path.realpath(__file__))
MODEL_DIREC = os.path.join(PACKAGE_DIREC, 'models')
DATA_DIREC = os.path.join(PACKAGE_DIREC, 'datasets')
LOG_DIREC = os.path.join(PACKAGE_DIREC, 'training_logs')

# model names
NO_MODEL = 'None'
PAPER_MODEL = 'paperModel'
NO_DATA = 'No data'

# file extension
TIF = 'tif'

# network patch size
SIZE = 128
BORDER_THRESH = 7
