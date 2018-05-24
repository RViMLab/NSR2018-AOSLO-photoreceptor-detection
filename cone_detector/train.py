import tensorflow as tf
import numpy as np
from .input_pipeline import pipeline, pre_process
from .model import trainable_model, forward_network_softmax
from . import constants
from . import utilities
from .process_network_out import PostProcessor
from sklearn.neighbors import KDTree
import csv
import os


class Trainer:

    config = tf.ConfigProto()
    config.gpu_options.allow_growth = True
    features = {
        'image': tf.FixedLenFeature([], tf.string),
        'segmentation': tf.FixedLenFeature([], tf.string),
        'height': tf.FixedLenFeature([], tf.string),
        'width': tf.FixedLenFeature([], tf.string),
        'location': tf.FixedLenFeature([], tf.string)}

    def __init__(self, model_name, train_name, bright_dark, val_name):
        self.model_name = model_name
        self.model_direc = os.path.join(constants.MODEL_DIREC, model_name)

        self.train_name = train_name
        self.have_val_data = val_name != constants.NO_DATA
        self.val_name = val_name if self.have_val_data else None

        self.bright_dark = bright_dark

    def get_data_folder(self, data_name):
        return os.path.join(constants.DATA_DIREC, data_name)

    def get_data_record(self, data_name):
        folder = self.get_data_folder(data_name)
        return os.path.join(folder, 'data.tfrecord')

    def get_num_images(self, data_name):
        path = self.get_data_folder(data_name)
        path = os.path.join(path, 'info.csv')
        with open(path, 'r') as csvfile:
            reader = csv.reader(csvfile)
            for row in reader:
                return int(row[1])

    def build_pipeline(self, data_name, batch_size):
        image_batch, label_batch = pipeline(
            [self.get_data_record(data_name)],
            batch_size=batch_size,
            num_epochs=300)

        return image_batch, label_batch

    def calculate_best_hypers(self):
        thresh, sigma = self.get_thresh_sigma()
        return thresh, sigma

    def write_hyper(self, thresh, sigma):
        with open(os.path.join(self.model_direc, 'params.csv'), 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            row = [thresh, sigma]
            writer.writerow(row)

    @staticmethod
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

    @staticmethod
    def calc_dice(array):
        tp = array[0]
        fp = array[1]
        fn = array[2]
        return 2. * tp / (2. * tp + fp + fn)

    @staticmethod
    def num_iterations_in_epoch(batch_size, num_images):
        return num_images // batch_size

    @staticmethod
    def process_record(single_example, image_place, prob, sess):
        im_size = [single_example['height'][0], single_example['width'][0]]
        locations = np.reshape(single_example['location'], im_size)
        im = np.reshape(single_example['image'], im_size)
        im = im - im.mean()
        im = utilities.crop_center(im, constants.SIZE)
        locations = utilities.crop_center(locations, constants.SIZE)
        feed_dict = {image_place: im[None, :, :, None]}
        example_prob = sess.run(prob, feed_dict=feed_dict)
        example_prob = np.reshape(example_prob, [constants.SIZE, constants.SIZE])
        cone_locations = np.transpose(np.nonzero(locations > 0))

        return example_prob, cone_locations

    @staticmethod
    def get_center_dice(estimated_centers, actual_centroids):
        if estimated_centers:
            # convert to numpy arrays
            centroids = np.stack(estimated_centers)
            # calculate distances from all centroids to all other
            b = actual_centroids.reshape(actual_centroids.shape[0], 1, actual_centroids.shape[1])
            dists = np.sqrt(np.einsum('ijk, ijk->ij', actual_centroids - b, actual_centroids - b))
            dists = np.min(np.where(dists == 0, np.inf, dists), axis=1)

            # work out threshold for what we consider to be a match
            acceptable_radius = np.median(dists) * 0.75 if np.median(dists) < 20 else 20

            # look for nearest neighbours
            tree = KDTree(actual_centroids, leaf_size=100)
            inds, dist = tree.query_radius(centroids, r=acceptable_radius, return_distance=True, sort_results=True)
            pairs = []

            # start matching
            for k in range(len(centroids)):
                if inds[k].shape[0] != 0:
                    previous_inds = map(lambda x: x[1], pairs, )
                    for l in range(inds[k].shape[0]):
                        if not inds[k][l] in previous_inds:
                            pairs.append((k, inds[k][l]))
                            break

            true_positives = set(map(lambda x: x[0], pairs, ))
            paired_actual_centroids = map(lambda x: x[1], pairs, )
            false_positives = set(range(centroids.shape[0])).difference(true_positives)
            false_negatives = set(range(actual_centroids.shape[0])).difference(set(paired_actual_centroids))
        else:
            true_positives = []
            false_positives = []
            false_negatives = actual_centroids
        tp = float(len(true_positives))
        fp = float(len(false_positives))
        fn = float(len(false_negatives))

        return 2. * tp / (2. * tp + fp + fn)

    @staticmethod
    def calculate_best_from_list(label_prob_list):
        best_dice = 0.
        for thresh in np.linspace(0., 0.9999, 30):
            for sigma in np.linspace(0., 4, 30):
                for prob, actual_centers in label_prob_list:
                    centers = PostProcessor.get_centers_static(prob, sigma, thresh)
                    dice = Trainer.get_center_dice(centers, actual_centers)
                    if dice > best_dice:
                        best_dice = dice
                        best_thresh = thresh
                        best_sigma = sigma
            return best_thresh, best_sigma

    def get_thresh_sigma(self,):
        if self.have_val_data:
            data_record = self.get_data_record(self.val_name)
        else:
            data_record = self.get_data_record(self.train_name)

        model_location = os.path.join(self.model_direc, 'model')
        label_prob_list = []
        with tf.Graph().as_default():
            with tf.Session() as sess:
                image_place = tf.placeholder(dtype=tf.float32, shape=[1, constants.SIZE, constants.SIZE, 1])
                prob = forward_network_softmax(image_place, bright_dark=self.bright_dark)

                saver = tf.train.Saver()
                saver.restore(sess, model_location)

                records = tf.python_io.tf_record_iterator(data_record)
                for record in records:
                    single_example = tf.parse_single_example(record, features=Trainer.features)
                    for feature in single_example:
                        single_example[feature] = tf.decode_raw(single_example[feature], tf.uint8).eval()

                    example_prob, cone_locations = Trainer.process_record(single_example, image_place, prob, sess)
                    label_prob_list.append((example_prob, cone_locations))

        thresh, sigma = Trainer.calculate_best_from_list(label_prob_list)
        return thresh, sigma

    def train_model(self, batch_size=4):
        num_train_images = self.get_num_images(self.train_name)
        if self.have_val_data:
            num_val_images = self.get_num_images(self.val_name)

        os.mkdir(self.model_direc)
        with tf.Graph().as_default():
            with tf.Session(config=Trainer.config) as sess:
                with tf.variable_scope('') as scope:

                    # BUILD PIPELINE
                    image_batch, label_batch = self.build_pipeline(self.train_name, batch_size)
                    if self.have_val_data:
                        v_image_batch, v_label_batch = self.build_pipeline(self.val_name, batch_size)

                    optimizer = trainable_model(image_batch, label_batch, brightDark=self.bright_dark)
                    scope.reuse_variables()
                    if self.have_val_data:
                        v_probs = forward_network_softmax(v_image_batch, bright_dark=self.bright_dark)

                    # initialisation stuff
                    init_op = tf.group(
                        tf.global_variables_initializer(),
                        tf.local_variables_initializer())
                    sess.run(init_op)
                    coord = tf.train.Coordinator()
                    threads = tf.train.start_queue_runners(coord=coord)
                    saver = tf.train.Saver(var_list=tf.trainable_variables())
                    sess.graph.finalize()

                    # keep training until we run out
                    # of input
                    try:
                        i = 0
                        best_dice = 0.
                        stalled = 0
                        max_stalled = 20
                        iterations_in_train_epoch = Trainer.num_iterations_in_epoch(batch_size, num_train_images)
                        if self.have_val_data:
                            iterations_in_val_epoch = Trainer.num_iterations_in_epoch(batch_size, num_val_images)
                        while not coord.should_stop():
                            # Run training steps or whatever
                            sess.run(optimizer)
                            if i%iterations_in_train_epoch == 0 and self.have_val_data:
                                tpfpfn = np.zeros([3])
                                for j in range(iterations_in_val_epoch):
                                    labs, probs = sess.run([v_label_batch, v_probs])
                                    tpfpfn += Trainer.tpfpfn_array(labs, probs, batch_size)
                                dice = Trainer.calc_dice(tpfpfn)
                                if dice > best_dice:
                                    best_dice = dice
                                    stalled = 0
                                    saver.save(sess, os.path.join(self.model_direc, 'model'))
                                else:
                                    stalled += 1
                                    if stalled == max_stalled:
                                        break
                            i += 1
                    except tf.errors.OutOfRangeError:
                        print('Done training -- epoch limit reached')
                        if not self.have_val_data:
                            saver.save(sess, os.path.join(self.model_direc, 'model'))
                    finally:
                        # When done, ask the threads to stop.
                        coord.request_stop()

                    # Wait for threads to finish.
                    coord.join(threads)

        thresh, sigma = self.calculate_best_hypers()
        self.write_hyper(thresh, sigma)









