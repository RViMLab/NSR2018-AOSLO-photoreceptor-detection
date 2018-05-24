# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

from .model_components import *

def forward_network_logits(inputs, bright_dark=True):
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
                (bss, 2
        """
    _, height, width, channels = inputs.get_shape().as_list()
    units = 32

    # flip so bright is on left if we have to
    if not bright_dark:
        inputs = tf.image.flip_left_right(inputs)

    # Conv layer
    with tf.variable_scope('conv_0'):
        conv = conv_layer(inputs)

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

    # out is (bss,2) and is the raw logits
    out = fully_connected_layer(MD)

    return out


def forward_network_softmax(inputs, bright_dark):
    _, height, width, channels = inputs.get_shape().as_list()
    logits = forward_network_logits(inputs, bright_dark)
    probs = tf.nn.softmax(logits)

    # flip so bright is on left if we have to
    if not bright_dark:
        probs = tf.reshape(probs, [-1, height, width, 2])
        probs = tf.image.flip_left_right(probs)
        probs = tf.reshape(probs, [-1, 2])

    return probs[:, 1]


def trainable_model(inputs, segmentation, bright_dark):
    logits = forward_network_logits(inputs, bright_dark)

    # weighted loss using ratio
    loss, reshaped_labels = get_dice_loss(logits, segmentation)

    optimizer = tf.train.RMSPropOptimizer(1e-3)
    gradients, variables = zip(*optimizer.compute_gradients(loss))

    # occasionally gradients would explode
    # tells us if there are NaN values in any tensors
    grad_checks = [tf.check_numerics(grad, 'Gradients exploding') for grad in gradients if grad is not None]
    with tf.control_dependencies(grad_checks):
        optimize = optimizer.apply_gradients(zip(gradients, variables))

    return optimize

