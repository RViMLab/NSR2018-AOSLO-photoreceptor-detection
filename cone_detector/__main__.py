# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import argparse

from . import cone_detector, launch_gui


def main():
    """command line entry to detect"""
    r = launch_gui.ConeDetectorGUI()
    r.start()
    cone_detector.main(r.im_folder, r.lut_file, r.manually_annotate, r.bright_dark)

if __name__ == '__main__':
    main()
