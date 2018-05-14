# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

from .model_components import *


def DICE_CONV_MD_32U2L_tanh(image):
    """
        Builds the graph for the best model in the paper
        M-C-M

        Input:
            image shape=(b,s,s,1)
                AOSLO image crop
            labels shape=(b,s,s,2)
                pixel classifications
            optimize
                whether or not to return optmiser
            retrain_output
                if true prevents gradient updates
                to all layers except the fully connected

        Output:
            see output in model_components.py
    """
    _, height, width, channels = image.get_shape().as_list()
    units = 32

    # Conv layer
    with tf.variable_scope('conv_0'):
        conv = conv_layer(image)

    # MDLSTM layer
    with tf.variable_scope('MD_0'):
        MD = MD_parallel(conv, units)
        MD = tf.transpose(MD, [0, 1, 2, 4, 3])
        MD = tf.reshape(MD, [-1, height, width, 4 * units])

    # Conv layer
    with tf.variable_scope('conv_1'):
        conv = conv_layer(MD)

    # MDLSTM layer
    with tf.variable_scope('MD_1'):
        MD = MD_parallel(conv, units)
        MD = tf.transpose(MD, [0, 1, 2, 4, 3])
        MD = tf.reshape(MD, [-1, height, width, 4 * units])

    # out is (b,s,s,2) and is the raw logits
    out = fully_connected_layer(MD)

    # depending on optimize return different outputs
    # convert scores to probabilities
    probs = tf.nn.softmax(out)

    # gives classification
    prediction = tf.argmax(probs, 1)

    # if you give images of shape (b,s,s,1) then
    # probs is (b,s,s,1) and each value of probs
    # is the probability that the corresponding
    # pixel belongs to a cone
    prob_of_cell = probs[:, 1]
    return image, out, prob_of_cell
