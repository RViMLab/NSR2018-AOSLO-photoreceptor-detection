# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import tensorflow as tf
from tensorflow import TensorArray
import numpy as np
import os
import random

def output(image, labels, optimize, loss, out, reshaped_labels):
    """
        Handles output of a model
        input
            image
            labels
            optimize bool
                construct graph with optimizer or not
            loss
                objective of model
            out
                logits
            reshaped_labels
                labels as a (x,2) tensor
        output
            if optimize:
                image
                labels
                optmizer
                    used to train
            else:
                image
                labels
                prob_of_cell shape=shape=(b,s,s,1)
                    probability of pixel being a cone
                correct_prediction
                    number of correct pixel classifications

    """
    if optimize:
        optimizer = tf.train.RMSPropOptimizer(1e-3)
        gradients, variables = zip(*optimizer.compute_gradients(loss))

        # occasionally gradients would explode
        # tells us if there are NaN values in any tensors
        grad_checks = [tf.check_numerics(grad, 'Gradients exploding') for grad in gradients if grad is not None]
        with tf.control_dependencies(grad_checks):
            optimize = optimizer.apply_gradients(zip(gradients, variables))
            return image, labels, optimize
    else:
        # convert scores to probabilities
        probs = tf.nn.softmax(out)

        # gives classification
        prediction = tf.argmax(probs, 1)

        # count how many classifications are correct
        correct_prediction = tf.equal(tf.argmax(reshaped_labels, 1), prediction)

        # if you give images of shape (b,s,s,1) then
        # probs is (b,s,s,1) and each value of probs
        # is the probability that the corresponding
        # pixel belongs to a cone
        prob_of_cell = probs[:,1]
        return image, labels, prob_of_cell, correct_prediction

def get_dice_loss(out, labels, weight=True):
    """
        use a balanced loss with

        (1-ratio)*lossTerm(pixel_belongin_to_cell) + (ratio)*lossTerm(pixel_background)

        this will penalise incorrect cells more than incorrect background (if ratio < 0.5)
        and as such we get some class balancing. If we use the original ratio withou
        thresholding the network is too keen to predict cells at any cost as this ratio
        can be 0.

    """
    _, height, width, inp_size = labels.get_shape().as_list()
    batch_size = tf.shape(labels)[0]
    # reshape labels so we have 2D also  batch x height * width x 2
    reshaped_labels = tf.reshape(labels, [-1, height*width, inp_size])

    preds = tf.nn.softmax(logits=out)
    reshaped_preds = tf.reshape(preds, [-1, height*width, inp_size])

    multed = tf.reduce_sum(reshaped_labels*reshaped_preds, axis=1)
    summed = tf.reduce_sum(reshaped_labels + reshaped_preds, axis=1)

    r0 = tf.reduce_sum(reshaped_labels[:,:,0], axis=1)
    r1 = np.float32(height*width) - r0
    w0 = 1./(r0*r0 + 1.) if weight else 1.
    w1 = 1./(r1*r1 + 1.) if weight else 1.

    numerators = w0*multed[:,0] + w1*multed[:,1]
    denom = w0*summed[:,0] + w1*summed[:,1]

    dices = 1. - 2.*numerators/denom
    loss = tf.reduce_mean(dices)
    return loss, tf.reshape(reshaped_labels, [-1, 2])

def input_labels(height, width):
    """Returns two placeholders for image, and label"""
    images = tf.placeholder(dtype = tf.float32, shape = [None, height, width, 1])
    labels = tf.placeholder(dtype = tf.float32, shape = [None, height, width, 2])

    return images, labels


def conv_layer(inp):
    """
        convolutional layer as in paper, 3x3 filter, tanh, SAME padding
        with a single output channel
        Input
            inp
                must be (b,h,w,c)
            output_channels int
                number of output channels

        Output
            (b,h,w,output_channels)

    """
    batch, height, width, channels = inp.get_shape().as_list()
    # filters
    filter_size = 3
    initial_range = 0.1
    output_channels = 1
    padding = 'SAME'
    weights = tf.get_variable(
        'conv_weights', 
        initializer = tf.random_uniform(
            [filter_size, filter_size, channels, output_channels], 
            -initial_range, 
            initial_range))
    bias = tf.get_variable('conv_bias', initializer = tf.zeros([output_channels]))

    # convolve input with padding so image dimensions are same
    convolved = tf.nn.conv2d(inp, weights, [1,1,1,1], padding) + bias
    return tf.tanh(convolved)

def fully_connected_layer(inp):

    """
        uses 1x1 convolution to slide a fully connected
        layer with 64 hidden units and relu activations
        over a tensor of (batch, height, width, channels)

        Input
            must be (b,h,w,c)
        Output
            (b,h,w,2)

    """

    # for weight initialisation
    batch, height, width, channels = inp.get_shape().as_list()
    hidden_neurons = 64
    n_in = float(channels)
    n_out = float(hidden_neurons)
    val = np.sqrt(6. / (n_in + n_out))

    # input to hidden
    W = tf.get_variable(
        'classifier_weights', 
        initializer=tf.random_uniform(
            [1, 1, channels, hidden_neurons], 
            -val, 
            val))   
    b = tf.get_variable('classifier_bias', initializer=tf.zeros([hidden_neurons]))
    after_conv = tf.nn.relu(tf.nn.conv2d(inp, W, strides = [1, 1, 1, 1], padding = 'VALID') + b)

    # reshape after conv to 2D so we have batch * height * width x hidden
    # first flip so have 
    #   hidden x batch x height x width
    # then unravel
    #   hidden x batch*height*width
    # flip
    #   batch*height*width x hidden
    reshaped_out = tf.transpose(
        tf.reshape(
            tf.transpose(after_conv, (3, 0, 1, 2)), 
            [hidden_neurons, -1]),
        (1, 0))

    # weight initialisation
    n_in = float(hidden_neurons)
    n_out = float(2)
    val = np.sqrt(6. / (n_in + n_out))

    # hidden to output logits
    WW = tf.get_variable('classifier_weights2', initializer=tf.random_uniform([hidden_neurons, 2], -val, val))  
    bb = tf.get_variable('classifier_bias_2', initializer=tf.zeros([2]))
    out = tf.matmul(reshaped_out, WW) + bb

    return out

def diagonal_lstm(units, inp_size):
    """
        This constructs the parallel implementation of an MDLSTM cell.
        
    """
    # directions is four as we go top left, top right, bottom left, bottom right
    directions = 4

    # initialisation range, ensures network actually learns
    # if lower it tends to fail, spectral radius probably too small
    # or too large otherwise
    v = 0.25

    # gonna use for depthwise convolution
    # these are the filters and have meaning
    # [filter_height, filter_width, in_channels, channel_multiplier]
    # we want to have W_lh_l + 
    number_diagonal_values_to_convolve = 2
    hidden_weights = tf.get_variable(
        'hidden_weights', 
        initializer=tf.random_normal(
            [number_diagonal_values_to_convolve, units, directions, 5*units], 
            0, 
            v))
    number_diagonal_values_to_convolve = 1
    input_weights = tf.get_variable(
        'input_weights', 
        initializer=tf.random_normal(
            [number_diagonal_values_to_convolve, inp_size, directions, 5*units],
            0,
            v))

    def _bias_weights(name):
        w = tf.get_variable(name, initializer=tf.zeros([units, directions]))
        return w

    ib = _bias_weights('i_bias')
    fb1 = _bias_weights('f1_bias')
    fb2 = _bias_weights('f2_bias')
    cb = _bias_weights('c_bias')
    ob = _bias_weights('o_bias')

    def cell(diagonal_input, diagonal_acti, diagonal_cell):

        """ 
            INPUT


            diagonal_input
                b x d_{0} x in_size x 4

            diagonal_acti:
                b x d_{-1} + 1 x units x 4

            diagonal_cell:
                b x d_{-1} + 1 x units x 4

            ##########################################
            RETURN
            ##########################################
            tensor of activation
                b x d x units x 4
        """

        _, diagonal_size, _, _ = diagonal_input.get_shape().as_list()

        # batch x diagonal_size+1 x units x 4 * WEIGHT = batch x diagonal_size x 1 x dirs*(5units)
        # we kill the 1 dimension with the slice, cannot use squeeze as sometimes other dimensions
        # will be 1
        hidden_mats = tf.nn.depthwise_conv2d(diagonal_acti, hidden_weights, [1,1,1,1], 'VALID')
        # b x diagonal x dirs*(5units)
        hidden_mats = hidden_mats[:,:,0,:]
        # batch x diagonal_size x in_size x 4 * WEIGHT = batch x diagonal_size x 1 x dirs*(5units)
        input_mats = tf.nn.depthwise_conv2d(diagonal_input, input_weights, [1,1,1,1], 'VALID')
        # b x diagonal x dirs*(5units)
        input_mats = input_mats[:,:,0,:]

        # combined mats
        # b x diagonal x dirs(5units)
        # b x diagonal x 5units x dirs
        # b x diagonal x units x dirs x 5
        combined = input_mats + hidden_mats
        combined = tf.stack(tf.split(combined, axis=2, num_or_size_splits=directions), 3)
        combined = tf.stack(tf.split(combined, axis=2, num_or_size_splits=5), 4)

        # cell stuff
        # b x diagonal x units x dir
        # need to have some 2xunits convolution along diagonal_cell
        cell_up = diagonal_cell[:,0:-1,:,:]
        cell_left = diagonal_cell[:,1:,:,:]

        # GATES AND CELL
        # each combineds is
        # b x diagonal x dirs x units
        i = tf.sigmoid(combined[:,:,:,:,0] + ib)
        f1 = tf.sigmoid(combined[:,:,:,:,1] + fb1)
        f2 = tf.sigmoid(combined[:,:,:,:,2] + fb2)
        cell = combined[:,:,:,:,4] + cb
        cell_state = tf.tanh(cell)*i + ((cell_up*f1 + cell_left*f2)/(f1+f2))*(1-i)
        o = tf.sigmoid(combined[:,:,:,:,3] + ob)
        activation = o*tf.tanh(cell_state)

        # b x diagonal x unit x dir
        return activation, cell_state

    return cell

def get_single_diagonal_indices(height, width, diagonal):
    """
        get linear indices of a given diagonal
        will be used to put values into tensorArray
        correctly
    """

    # offsets are how far we have to move linearly
    # to go a single position through and index
    # eg to move one row down, we need to go through
    # all rows
    width_offset = 1
    height_offset = width

    # get starting value
    start = tf.cond(
        diagonal<height, 
        lambda:diagonal*height_offset, 
        lambda:(height-1)*height_offset + (diagonal%height + 1)*width_offset)

    # end value
    end = tf.cond(
        diagonal<height, 
        lambda:(diagonal)*width_offset - 1, 
        lambda: height_offset - width_offset + (diagonal%height + 1)*height_offset -1 )

    # delta moves us one up and one along
    delta = -(height_offset) + width_offset

    # actual values
    return tf.range(start, end, delta)

def get_diagonal_indices(diagonal, tensor):
    """
        Get row and column indices of diagonal
        in tensor

        need to get multi index now to use ndgather
        which is more efficient

    """
    _, height, width, inp_size, directions = tensor.get_shape().as_list()
    batch = tf.shape(tensor)[0]
    diagonal_size = tf.cond(
        diagonal<height, 
        lambda:diagonal + 1, 
        lambda:height - (diagonal%height + 1))
    start_row = tf.cond(
        diagonal<height, 
        lambda:diagonal, 
        lambda:height - 1)
    start_col = tf.cond(
        diagonal<height, 
        lambda:0, 
        lambda:diagonal%height + 1)
    rows = tf.range(
        start_row, 
        start_row-diagonal_size, 
        -1)
    cols = tf.range(
        start_col, 
        start_col+diagonal_size)
    return tf.stack([rows, cols], axis=1)

def get_diagonal_values(diagonal, tensor):
    """
        uses multi index values [row, col]
        to get the actual values in the diagonal 
        of tensor

        gather_nd works using first indices you give it
        so we assume tensor is of shape
            height x width x batch x inp_size x direction
    """
    row_col = get_diagonal_indices(diagonal, tensor)
    values = tf.gather_nd(tensor, row_col)
    # reshapes to batch x diagonalx inp_szie x direction
    return tf.transpose(values, (1,0,2,3))

def fast_MD_dynamic(input_data, units):
    """
        carries out iteration over diagonals
        input
            input_data = (b,h,w,i,d)
                where d are the 4 direcitons
            units
                number of units in cell

        TODO calculate indices once and reuse
    """
    _, height, width, inp_size, directions = input_data.get_shape().as_list()
    batch_size = tf.shape(input_data)[0]

    # make input height, width, batch, inp, direction
    input_data_transposed = tf.transpose(input_data, (1,2,0,3,4))

    # needs to be square for current implemntation
    assert height==width

    # construct diagonal lstm cell
    # cell(inp, acti, cell) = acti, cell
    cell = diagonal_lstm(units, inp_size)

    # intial values
    num_diag = 2*(height-1) + 1
    zeros = tf.stack([batch_size, 2, units, directions])
    current_activations = tf.fill(zeros, 0.0)
    initial_state = tf.fill([batch_size, 1, units, directions], 0.0)
    current_states = tf.tile(initial_state, [1, 2, 1, 1])
    diagonal = tf.constant(0)

    # will ultimately store our activations
    # when stacked will be h,w,b,u,d
    activations_ta = TensorArray(dtype=tf.float32, size=height*width, element_shape=tf.TensorShape([None, units, 4]))

    def pad_with_initial(tensor):
        """pads for edge activations/cells"""
        added_bot = tf.concat([tensor, initial_state], axis=1)
        added_all = tf.concat([initial_state, added_bot], axis=1)
        return added_all

    def body(activations_ta, current_activations, current_states, diagonal):
        """
            process diagonal 0, 1, 2, ...
        """

        # Get the diagonal values of the input
        # b x d x inp_size x direction
        input_diagonal = get_diagonal_values(diagonal, input_data_transposed)

        # need to pad aci/cell except in first iteration
        not_first_acti = tf.cond(
            diagonal < height, 
            lambda:tf.pad(current_activations, [[0,0], [1,1], [0,0], [0,0]]), 
            lambda:current_activations)

        current_activations = tf.cond(
            tf.equal(diagonal, 0),
            lambda:current_activations,
            lambda:not_first_acti)

        not_first_cell = tf.cond(
            diagonal < height, 
            lambda:pad_with_initial(current_states),
            lambda:current_states)

        current_states = tf.cond(
            tf.equal(diagonal, 0), 
            lambda:current_states,
            lambda:not_first_cell)

        # work out new activations
        current_activations, current_states = cell(input_diagonal, current_activations, current_states)

        # batch x diagonal x unit x direction
        current_states.set_shape([None, None, units, directions])
        current_activations.set_shape([None, None, units, directions])
        
        # get indices to place into activations
        indices = get_single_diagonal_indices(height, width, diagonal)

        # we transpose so that correct values from current activations go in the correct place
        # scatter works by using the first index
        # thus activations contains
        # batch x units x direction
        activations_ta = activations_ta.scatter(indices, tf.transpose(current_activations, (1,0,2,3)))

        diagonal += 1
        return activations_ta, current_activations, current_states, diagonal

    def cond(activations_ta, current_activations, current_states, diagonal):
        return diagonal < num_diag

    acti_shape = tf.TensorShape([None, None, units, directions])
    cell_shape = tf.TensorShape([None, None, units, directions])
    diag_shape = tf.TensorShape([])
    ta_shape = tf.TensorShape(None)
    returned = tf.while_loop(
                cond = cond,
                body = body,
                loop_vars= [activations_ta, current_activations, current_states, diagonal],
                name = 'looooop',
                shape_invariants=[ta_shape, acti_shape, cell_shape, diag_shape],
                swap_memory=True)

    activations = returned[0].stack()
    activations.set_shape([height*width, None, units, directions])
    activations = tf.transpose(activations, (1, 0, 2, 3))
    activations = tf.split(activations, num_or_size_splits=height, axis=1)
    activations = tf.stack(activations, 1)

    return activations

def MD_parallel(image, units):
    """
        aranges input into the 4 directions and stacks into 
        a single tensor to be processed by fast_MD
    """
    _, height, width, inp_size = image.get_shape().as_list()

    # four orientations
    tl = image
    tr = tf.map_fn(tf.image.flip_left_right, image)
    bl = tf.map_fn(tf.image.flip_up_down, image)
    br = tf.map_fn(tf.image.flip_left_right, tf.map_fn(tf.image.flip_up_down, image))
    all_together = tf.stack([tl,tr,bl,br], 4)

    # all_activations is b x height x width x units x dir
    # seperate to reorient activations
    all_activations = fast_MD_dynamic(all_together, units)
    tl, tr, bl, br = tf.split(all_activations, num_or_size_splits=4, axis=4)

    # flip etc to align activations correctly
    tl = tl[:,:,:,:,0]
    tr = tf.map_fn(tf.image.flip_left_right, tr[:,:,:,:,0])
    bl = tf.map_fn(tf.image.flip_up_down, bl[:,:,:,:,0])
    br = tf.map_fn(tf.image.flip_up_down, tf.map_fn(tf.image.flip_left_right, br[:,:,:,:,0]))

    # stack into tensor
    all_together = tf.stack([tl,tr,bl,br], 4)
    all_together.set_shape([None, height, width, units, 4])

    return all_together