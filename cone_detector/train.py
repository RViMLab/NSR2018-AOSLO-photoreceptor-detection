import tensorflow as tf
import numpy as np
from .input_pipeline import pipeline, pre_process
from .model import trainable_model
from . import constants
from .regional_max import get_centroids
from sklearn.neighbors import KDTree
import csv
import os
import matplotlib.pyplot as plt

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

def get_center_dice(estimated_centers, actual_centroids):
    if estimated_centers:
        # convert to numpy arrays
        centroids = np.stack(estimated_centers)
        # calculate distances from all centroids to all other
        b = actual_centroids.reshape(actual_centroids.shape[0], 1, actual_centroids.shape[1])
        dists = np.sqrt(np.einsum('ijk, ijk->ij', actual_centroids-b, actual_centroids-b))
        dists = np.min(np.where(dists ==0, np.inf, dists), axis=1)

        # work out threshold for what we consider to be a match
        acceptable_radius = np.median(dists) * 0.75 if np.median(dists) < 20 else 20

        # look for nearest neighbours
        tree = KDTree(actual_centroids, leaf_size=100)
        inds, dist = tree.query_radius(centroids, r=acceptable_radius, return_distance=True, sort_results=True)
        pairs = []

        # start matching
        for k in range(len(centroids)):
            if inds[k].shape[0] != 0:
                previous_inds = map(lambda x: x[1], pairs,)
                for l in range(inds[k].shape[0]):
                    if not inds[k][l] in previous_inds:
                        pairs.append((k, inds[k][l]))
                        break

        true_positives = set(map(lambda x: x[0], pairs,))
        paired_actual_centroids = map(lambda x: x[1], pairs,)
        false_positives = set(range(centroids.shape[0])).difference(true_positives)
        false_negatives = set(range(actual_centroids.shape[0])).difference(set(paired_actual_centroids))
    else:
        true_positives = []
        false_positives = []
        false_negatives = actual_centroids
    tp = float(len(true_positives))
    fp = float(len(false_positives))
    fn = float(len(false_negatives))

    return 2.*tp / (2.*tp + fp + fn)

def get_num_images(data_folder):
    with open(os.path.join(data_folder, 'info.csv'), 'r') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            return int(row[1])

def crop_center(img, size):
    y, x = img.shape
    startx = x // 2 - (size // 2)
    starty = y // 2 - (size // 2)
    return img[starty:starty + size, startx:startx + size]

def get_thresh_sigma(data_name, model_name, brightDark):
    data_record = os.path.join(constants.DATA_DIREC, data_name, 'data.tfrecord')
    model_location = os.path.join(constants.MODEL_DIREC, model_name, 'model')
    label_prob_list = []
    with tf.Graph().as_default():
        with tf.Session() as sess:
            with tf.variable_scope('') as scope:
                image_place = tf.placeholder(dtype=tf.float32, shape=[1, constants.SIZE, constants.SIZE, 1])
                label_place = tf.placeholder(dtype=tf.float32, shape=[1, constants.SIZE, constants.SIZE, 1])
                _, label, prob = trainable_model(image_place, label_place, brightDark=brightDark, optimize=False)
                records = tf.python_io.tf_record_iterator(data_record)
                saver = tf.train.Saver()
                saver.restore(sess, model_location)
                features = {
                    'image': tf.FixedLenFeature([], tf.string),
                    'segmentation': tf.FixedLenFeature([], tf.string),
                    'height': tf.FixedLenFeature([], tf.string),
                    'width': tf.FixedLenFeature([], tf.string),
                    'locations': tf.FixedLenFeature([], tf.string)}
                for record in records:
                    single_example = tf.parse_single_example(record, features=features)
                    for feature in single_example:
                        single_example[feature] = tf.decode_raw(single_example[feature], tf.uint8).eval()

                    im_size = [single_example['height'][0], single_example['width'][0]]
                    locations = np.reshape(single_example['locations'], im_size)
                    im = np.reshape(single_example['image'], im_size)
                    im = im - im.mean()
                    im = crop_center(im,constants.SIZE)
                    locations = crop_center(locations,constants.SIZE)
                    feed_dict = {image_place:im[None,:,:,None]}
                    example_prob = sess.run(prob, feed_dict=feed_dict)
                    example_prob = np.reshape(example_prob, [constants.SIZE, constants.SIZE])
                    cone_locations = np.transpose(np.nonzero(locations>0))

                    label_prob_list.append((example_prob, cone_locations, im))

    def calc_best():

        best_dice = 0.
        for thresh in np.linspace(0., 0.9999, 30):
            for sigma in np.linspace(0., 4, 30):
                for prob, actual_centers, im in label_prob_list:
                    centers = get_centroids(prob, sigma, 0, thresh)
                    dice = get_center_dice(centers, actual_centers)
                    if dice > best_dice:
                        best_dice = dice
                        best_thresh = thresh
                        best_sigma = sigma
        return best_thresh, best_sigma

    thresh, sigma = calc_best()
    return thresh, sigma

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
    model_direc = os.path.join(constants.MODEL_DIREC, model_name)
    os.mkdir(model_direc)
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
                    if have_val_data:
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
                                saver.save(sess, os.path.join(model_direc, 'model'))
                            else:
                                stalled += 1
                                if stalled == max_stalled:
                                    break
                        i += 1
                except tf.errors.OutOfRangeError:
                    print('Done training -- epoch limit reached')
                    if not have_val_data:
                        saver.save(sess, os.path.join(model_direc, 'model'))
                finally:
                    # When done, ask the threads to stop.
                    coord.request_stop()

                # Wait for threads to finish.
                coord.join(threads)

    if have_val_data:
        thresh, sigma = get_thresh_sigma(val_data_name, model_name, brightDark)
    else:
        thresh, sigma = get_thresh_sigma(train_data_name,  model_name, brightDark)

    with open(os.path.join(model_direc, 'params.csv'), 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        row = [thresh, sigma]
        writer.writerow(row)

