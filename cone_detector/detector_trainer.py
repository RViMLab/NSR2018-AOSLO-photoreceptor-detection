import csv
import os

import numpy as np
import tensorflow as tf
from sklearn.neighbors import KDTree

from . import constants
from . import model
from .process_network_out import PostProcessor


class DetectorTrainer:

    def __init__(self, model_name, train_data_name, val_data_name, bright_dark, batch_size=4):
        self.model_name = model_name
        self.model_direc = os.path.join(constants.MODEL_DIREC, model_name)
        self.model_path = os.path.join(self.model_direc, 'model')
        self.train_data_path = os.path.join(constants.DATA_DIREC, train_data_name, 'data.tfrecord')
        if val_data_name == constants.NO_DATA:
            raise ValueError('You need to specify validation data')

        self.val_data_path = os.path.join(constants.DATA_DIREC, val_data_name, 'data.tfrecord')

        self.bright_dark = bright_dark
        self.batch_size = batch_size
        self.burn_in = 5
        self.kill_after_stall = 20

        self.graph = tf.Graph()
        self.sess = tf.Session(graph=self.graph)

    @staticmethod
    def feature_dict():
        feature_info = dict(
            height=tf.uint8,
            width=tf.uint8,
            image=tf.uint8,
            segmentation=tf.uint8,
            location=tf.uint8)
        features = dict()
        for key in feature_info.keys():
            features[key] = tf.FixedLenFeature([], tf.string)
        return features, feature_info

    @staticmethod
    def to_tensors(serialized_example):
        # change from proto to values
        features, feature_info = DetectorTrainer.feature_dict()
        features = tf.parse_single_example(serialized_example, features=features)
        for feature in features.keys():
            features[feature] = tf.decode_raw(features[feature], feature_info[feature])

        # reshape so images
        height, width = features['height'][0], features['width'][0]
        im_shape = tf.cast(tf.stack([height, width]), tf.int32)
        image = tf.reshape(features['image'], im_shape)
        segmentation = tf.reshape(features['segmentation'], im_shape)
        location = tf.reshape(features['location'], im_shape)

        return image, segmentation, location, height, width

    @staticmethod
    def pad(image, segmentation, height, width):
        def padding(dim_size):
            dim_size = tf.cast(dim_size, tf.int32)
            p = tf.cond(dim_size - constants.SIZE < 0, lambda: constants.SIZE - dim_size, lambda: 0)
            return tf.stack([p // 2, p - p // 2])

        # ensure minimum size
        pad_h = padding(height)
        pad_w = padding(width)
        image = tf.pad(image, tf.stack([pad_h, pad_w]))
        segmentation = tf.pad(segmentation, tf.stack([pad_h, pad_w]))
        return image, segmentation

    @staticmethod
    def random_crop(image, segmentation):
        # crop out [128,128] shape
        crop_shape = [constants.SIZE, constants.SIZE, 2]
        cropped = tf.random_crop(
            tf.stack([image, segmentation], axis=2),
            crop_shape)
        image, segmentation = tf.split(cropped, 2, axis=2)
        return image, segmentation

    @staticmethod
    def flip(image, segmentation):
        random_var = tf.random_uniform(maxval=2, dtype=tf.int32, shape=[])

        image = tf.cond(
            tf.equal(random_var, 0),
            lambda: tf.image.flip_up_down(image),
            lambda: image)

        segmentation = tf.cond(
            tf.equal(random_var, 0),
            lambda: tf.image.flip_up_down(segmentation),
            lambda: segmentation)

        return image, segmentation

    @staticmethod
    def pre_processing(serialized_example):

        image, segmentation, location, height, width = DetectorTrainer.to_tensors(serialized_example)
        image, segmentation = DetectorTrainer.pad(image, segmentation, height, width)
        image, segmentation = DetectorTrainer.random_crop(image, segmentation)
        image = tf.cast(image, dtype=tf.float32)

        pro_image = image - tf.reduce_mean(image)
        one_hot_seg = tf.one_hot(
            tf.squeeze(segmentation),
            depth=2,
            on_value=1.,
            dtype=tf.float32)

        pro_image, one_hot_seg = DetectorTrainer.flip(pro_image, one_hot_seg)
        pro_image = tf.expand_dims(pro_image, axis=0)

        return pro_image[0, :, :, :], one_hot_seg

    def build_inputs(self, data_path):
        with self.graph.as_default():
            dataset = tf.data.TFRecordDataset(data_path)
            dataset = dataset.map(DetectorTrainer.pre_processing)
            dataset = dataset.shuffle(buffer_size=32)
            dataset = dataset.batch(self.batch_size)
            iterator = dataset.make_initializable_iterator()
            image, segmentation = iterator.get_next()

        return iterator, image, segmentation

    def build_optimizer(self):
        with self.graph.as_default():
            iterator, train_image, train_segmentation = self.build_inputs(self.train_data_path)
            optimizer = model.trainable_model(train_image, train_segmentation, self.bright_dark)
            init_op = tf.global_variables_initializer()
            saver = tf.train.Saver()
        return iterator, init_op, saver, optimizer

    @staticmethod
    def dice_info(probs, segmentation):
        # batch size may be different than self.batch_size due to dataset use
        batch_size = segmentation.shape[0]
        prob = np.reshape(probs, [batch_size, constants.SIZE, constants.SIZE])

        cones = prob > 0.5
        actual_cones = segmentation[:, :, :, 1] == 1
        background = prob <= 0.5
        actual_background = segmentation[:, :, :, 1] == 0

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

    def build_validator(self):
        with self.graph.as_default():
            iterator, val_image, val_segmentation = self.build_inputs(self.val_data_path)
            tf.get_variable_scope().reuse_variables()
            probs = model.forward_network_softmax(val_image, self.bright_dark)
        return iterator, probs, val_segmentation

    def run_validation_epoch(self, probs, val_segmentation, val_iterator, best_dice, saver):
        self.sess.run(val_iterator.initializer)
        tpfpfn = np.zeros([3])
        while True:
            try:
                cone_map, actual = self.sess.run([probs, val_segmentation])
                tpfpfn += DetectorTrainer.dice_info(cone_map, actual)
            except tf.errors.OutOfRangeError:
                break
        dice = DetectorTrainer.calc_dice(tpfpfn)
        if dice > best_dice:
            saver.save(self.sess, os.path.join(self.model_direc, 'model'))
            best_dice = dice
        return best_dice

    def run_training_epoch(self, train_iterator, optimizer):
        self.sess.run(train_iterator.initializer)
        while True:
            try:
                self.sess.run(optimizer)
            except tf.errors.OutOfRangeError:
                break

    def train_network(self):
        train_iterator, init_op, saver, optimizer = self.build_optimizer()
        val_iterator, probs, val_segmentation = self.build_validator()
        self.sess.run(init_op)
        best_dice = 0.
        stalled = 0

        while True:
            self.run_training_epoch(train_iterator, optimizer)
            new_best_dice = self.run_validation_epoch(probs, val_segmentation, val_iterator, best_dice, saver)
            if new_best_dice == best_dice:
                stalled += 1
            else:
                best_dice = new_best_dice
                stalled = 0
            if stalled == self.kill_after_stall:
                break

        tf.reset_default_graph()
        self.graph = tf.Graph()
        self.close_session()

    def close_session(self):
        self.sess.close()
        self.sess = tf.Session(graph=self.graph)

    @staticmethod
    def hyper_pre_process(serialized_example):
        image, _, location, height, width = DetectorTrainer.to_tensors(serialized_example)
        image = tf.cast(image, dtype=tf.float32)
        pro_image = image - tf.reduce_mean(image)
        size = constants.SIZE

        startx = height // 2 - (size // 2)
        starty = width // 2 - (size // 2)

        pro_image = pro_image[starty:starty + size, startx:startx + size]
        location = location[starty:starty + size, startx:startx + size]
        pro_image = tf.expand_dims(pro_image, axis=0)

        return pro_image, location

    def build_hyper_param_inputs(self):
        with self.graph.as_default():
            dataset = tf.data.TFRecordDataset(self.val_data_path)
            dataset = dataset.map(DetectorTrainer.hyper_pre_process)
            dataset = dataset.shuffle(buffer_size=32)
            dataset = dataset.batch(self.batch_size)
            iterator = dataset.make_initializable_iterator()
            image, location = iterator.get_next()
        return image, location, iterator

    def build_hyper_graph(self):
        with self.graph.as_default():
            image, location, iterator = self.build_hyper_param_inputs()
            probs = model.forward_network_softmax(image, self.bright_dark)
            probs = tf.reshape(probs, [constants.SIZE, constants.SIZE])
            init_op = tf.global_variables_initializer()
            saver = tf.train.Saver()
            self.sess.run(init_op)
            saver.restore(self.sess, os.path.join(constants.MODEL_DIREC, self.model_name, 'model'))
        return probs, location, iterator

    def collect_centers_and_prob_maps(self):
        probs, location, iterator = self.build_hyper_graph()
        self.sess.run(iterator.initializer)
        centers_and_maps = []
        while True:
            try:
                cone_map, location_array = self.sess.run([probs, location])
                location_array = np.transpose(np.nonzero(location_array > 0))
                centers_and_maps.append((cone_map, location_array))
            except tf.errors.OutOfRangeError:
                break
        return centers_and_maps

    @staticmethod
    def calculate_best_from_list(centers_and_maps):
        best_dice = 0.
        best_sigma = 0.
        best_thresh = 0.
        for thresh in np.linspace(0., 0.9999, 30):
            for sigma in np.linspace(0., 4, 30):
                for prob, actual_centers in centers_and_maps:
                    centers = PostProcessor.get_centers_static(prob, sigma, thresh)
                    dice = DetectorTrainer.get_center_dice(centers, actual_centers)
                    if dice > best_dice:
                        best_dice = dice
                        best_thresh = thresh
                        best_sigma = sigma
            return best_thresh, best_sigma

    @staticmethod
    def get_center_dice(estimated_centers, actual_centroids):

        if not estimated_centers:
            return 0.

        def distance_between_cones():
            # calculate distances from all centroids to all other so that can calculate acceptable distance
            b = actual_centroids.reshape(actual_centroids.shape[0], 1, actual_centroids.shape[1])
            dists = np.sqrt(np.einsum('ijk, ijk->ij', actual_centroids - b, actual_centroids - b))
            dists = np.min(np.where(dists == 0, np.inf, dists), axis=1)
            med_dist = np.median(dists)
            return med_dist

        estimated_centers = np.stack(estimated_centers)
        med_dist = distance_between_cones()
        acceptable_radius = med_dist * 0.75 if med_dist < 20 else 20

        # get nearest neighbours
        tree = KDTree(actual_centroids, leaf_size=100)
        inds, dist = tree.query_radius(estimated_centers, r=acceptable_radius, return_distance=True, sort_results=True)

        # match pairs together, taking only closest match
        pairs = []
        for k in range(len(estimated_centers)):
            if inds[k].shape[0] != 0:
                previous_inds = map(lambda x: x[1], pairs, )
                for l in range(inds[k].shape[0]):
                    if not inds[k][l] in previous_inds:
                        pairs.append((k, inds[k][l]))
                        break

        # calculate dice
        true_positives = set(map(lambda x: x[0], pairs, ))
        paired_actual_centroids = map(lambda x: x[1], pairs, )
        false_positives = set(range(estimated_centers.shape[0])).difference(true_positives)
        false_negatives = set(range(actual_centroids.shape[0])).difference(set(paired_actual_centroids))
        tp = float(len(true_positives))
        fp = float(len(false_positives))
        fn = float(len(false_negatives))

        return 2. * tp / (2. * tp + fp + fn)

    def write_hyper(self, thresh, sigma):
        with open(os.path.join(self.model_direc, 'params.csv'), 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            row = [thresh, sigma]
            writer.writerow(row)

    def train_hyper_params(self):
        centers_and_probs = self.collect_centers_and_prob_maps()
        thresh, sigma = self.calculate_best_from_list(centers_and_probs)
        self.write_hyper(thresh, sigma)
