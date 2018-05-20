import tensorflow as tf
import numpy as np
from .input_pipeline import pipeline
from .model import trainable_model
from . import constants
import csv
import os

def tpfpfn_array(labels, prob, batch_size):
    prob = np.reshape(prob, [batch_size, constants.SIZE, constants.SIZE])

    cones = prob > 0.5
    actual_cones = labels[:, :, :, 1] == 1
    background = prob <= 0.5
    actual_background = labels[:, :, :, 1] == 0

    tps = np.logical_and(cones, actual_cones).sum()
    fps = np.logical_and(cones, actual_background).sum()
    fns = np.logical_and(background, actual_cones).sum()

    return np.array([tps, fps, fns])

def calc_dice(array):
    tp = array[0]
    fp = array[1]
    fn = array[2]
    return 2.*tp / (2.*tp + fp + fn)

def num_iterations_in_epoch(batch_size, num_images):
    return num_images // batch_size

def get_num_images(data_folder):
    with open(os.path.join(data_folder, 'info.csv'), 'r') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            return int(row[1])

def train_model(model_name, train_data_name, brightDark, val_data_name, batch_size=4):

    config = tf.ConfigProto()
    config.gpu_options.allow_growth = True
    train_data = os.path.join(constants.DATA_DIREC, train_data_name)
    num_train_images = get_num_images(train_data)

    train_data_record = os.path.join(train_data, 'data.tfrecord')
    have_val_data = val_data_name != constants.NO_DATA
    if have_val_data:
        val_data = os.path.join(constants.DATA_DIREC, val_data_name)
        num_val_images = get_num_images(val_data)
        val_data_record = os.path.join(val_data, 'data.tfrecord')
    model_name = os.path.join(constants.MODEL_DIREC, model_name)
    os.mkdir(model_name)
    with tf.Graph().as_default():
        with tf.Session(config=config) as sess:
            with tf.variable_scope('') as scope:

                # Build input_pipeline for training and validation data
                image_batch, label_batch = pipeline([train_data_record], batch_size=batch_size, num_epochs=100)
                if have_val_data:
                    v_image_batch, v_label_batch = pipeline([val_data_record], batch_size=batch_size, num_epochs=100)

                # Build two models on the default graph
                _, _, _, optimizer = trainable_model(image_batch, label_batch, brightDark=brightDark)
                scope.reuse_variables()
                if have_val_data:
                    _, v_labels, v_probs = trainable_model(v_image_batch, v_label_batch, brightDark=brightDark, optimize=False)

                # initialisation stuff
                init_op = tf.group(
                    tf.global_variables_initializer(),
                    tf.local_variables_initializer())
                sess.run(init_op)
                coord = tf.train.Coordinator()
                threads = tf.train.start_queue_runners(coord=coord)

                saver = tf.train.Saver(var_list=tf.trainable_variables())
                # used to make sure not adding to the graph
                # (previously had an overflow)
                sess.graph.finalize()

                # keep training until we run out
                # of input
                try:
                    i = 0
                    best_dice = 0.
                    stalled = 0
                    max_stalled = 20
                    iterations_in_train_epoch = num_iterations_in_epoch(batch_size, num_train_images)
                    iterations_in_val_epoch = num_iterations_in_epoch(batch_size, num_val_images)
                    while not coord.should_stop():
                        # Run training steps or whatever
                        sess.run(optimizer)
                        if i%iterations_in_train_epoch == 0 and have_val_data:
                            j = 0
                            tpfpfn = np.zeros([3])
                            for j in range(iterations_in_val_epoch):
                                labs, probs = sess.run([v_labels, v_probs])
                                tpfpfn += tpfpfn_array(labs, probs, batch_size)
                            dice = calc_dice(tpfpfn)
                            if dice > best_dice:
                                best_dice = dice
                                stalled = 0
                                saver.save(sess, os.path.join(model_name, 'model'))
                            else:
                                stalled += 1
                                if stalled == max_stalled:
                                    break
                        i += 1
                except tf.errors.OutOfRangeError:
                    print('Done training -- epoch limit reached')
                finally:
                    # When done, ask the threads to stop.
                    coord.request_stop()

                # Wait for threads to finish.
                coord.join(threads)