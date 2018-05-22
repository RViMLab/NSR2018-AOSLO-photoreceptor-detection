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
            r.chosen_image_source_folder.get(),
            r.chosen_lut_file.get(),
            r.chosen_existing_model.get(),
            r.fully_or_semi_automatic.get(),
            r.bright_or_dark.get()
            )
    elif r.mode == r.DATA:
        cone_detector.data(
            r.chosen_image_source_folder.get(),
            r.bright_or_dark.get(),
            r.chosen_new_data_name.get(),
            r.chosen_existing_model.get())
    elif r.mode == r.TRAIN:
        cone_detector.train_new(
            r.chosen_train_data.get(),
            r.chosen_val_data.get(),
            r.chosen_new_model_name.get(),
            r.bright_or_dark.get())


if __name__ == '__main__':
    main()
