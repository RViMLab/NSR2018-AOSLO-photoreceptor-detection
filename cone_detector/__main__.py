# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

from . import cone_detector, launch_gui


def main():
    """command line entry to detect"""
    r = launch_gui.ConeDetectorGUI()
    r.start()

    if r.mode == r.APPLY:
        cone_detector.apply(
            r.im_folder_var.get(),
            r.lut_var.get(),
            r.model_name_var.get(),
            r.manually_annotate_var.get(),
            r.bright_dark_var.get()
            )
    elif r.mode == r.DATA:
        cone_detector.data(
            r.im_folder_var.get(),
            r.bright_dark_var.get(),
            r.new_data_name_var.get(),
            r.model_name_var.get())
    elif r.mode == r.TRAIN:
        cone_detector.train_new(
            r.train_data_loc_var.get(),
            r.val_data_loc_var.get(),
            r.new_model_name_var.get(),
            r.bright_dark_var.get())


if __name__ == '__main__':
    main()
