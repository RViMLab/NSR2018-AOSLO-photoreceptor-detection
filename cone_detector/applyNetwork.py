# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import os
import numpy as np
import tensorflow as tf
from .image_folder_reader import ImageFolder
from .model import DICE_CONV_MD_32U2L_tanh
from .process_network_out import PostProcessor
from . import constants
from .output import Output
from . import utilities
import matplotlib.pyplot as plt
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
def run_through_nothing(image_folder, outputs, size):

    for image_name in image_folder.images_by_size[size]:
        # get image, crop center, and build output
        raw_image = image_folder.grayscale_image(image_name)
        cropped = utilities.crop_center(raw_image, size)
        output = Output(image=cropped, name=image_name)
        output.set_estimated_centres([])
        outputs.append(output)

    return outputs


def run_through_graph(image_folder, mname, size, brightDark, outputs):

    # get modules location so we can load the tensorflow model
    # parameters
    model_location = os.path.join(constants.MODEL_DIREC, mname, 'model')
    model = DICE_CONV_MD_32U2L_tanh
    post_processor = PostProcessor(mname)

    # construct graph and apply to images
    with tf.Graph().as_default():
        with tf.Session() as sess:
            # build graph and restore, not we build it implicitly
            # using the size, due to the placeholder
            feed_dict = dict()
            image_place = tf.placeholder(dtype=tf.float32, shape=[1, size, size, 1])
            image, out, prob_of_cone = model(image_place, brightDark)
            saver = tf.train.Saver()
            saver.restore(sess, model_location)

            # process all images where maximum sized cropped is size
            for image_name in image_folder.images_by_size[size]:

                # get image, crop, center, make tensor
                raw_image = image_folder.grayscale_image(image_name)
                cropped = utilities.crop_center(raw_image, size)
                centred = cropped - np.mean(cropped)

                # put through graph
                feed_dict[image_place] = centred[None, :, :, None]
                im, prob_map = sess.run([image, prob_of_cone], feed_dict=feed_dict)
                prob_map = np.reshape(prob_map, [size, size])
                centers = post_processor.get_centers(prob_map)

                # save the name, largest central crop, and the centers as a list
                output = Output(image=cropped, name=image_name)
                output.set_estimated_centres(centers)
                outputs.append(output)

    return outputs


def locate_cones_with_model(data_folder, bright_dark, mname):

    image_folder = ImageFolder(data_folder)

    outputs = []
    for size in image_folder.images_by_size.keys():
        if mname == constants.NO_MODEL:
            outputs = run_through_nothing(image_folder, outputs, size)
        else:
            outputs = run_through_graph(image_folder, mname, size, bright_dark, outputs)

    return outputs
