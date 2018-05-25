import os

import numpy as np
import tensorflow as tf

from . import constants
from . import model
from . import process_network_out
from . import utilities


class ConeDetector:

    def __init__(self, size, bright_dark, model_name):
        self.size = size
        self.post_processor = process_network_out.PostProcessor(model_name)
        self.model_name = model_name
        self.prob_of_cone = None
        self.graph = tf.Graph()
        self.input_placeholder = None
        self.init_op = None
        self.saver = None
        self.build_graph(size, bright_dark)
        self.sess = tf.Session(graph=self.graph)
        self.initialize_vars()
        self.restore()

    def initialize_vars(self):
        self.sess.run(self.init_op)

    def restore(self, ):
        model_location = os.path.join(constants.MODEL_DIREC, self.model_name, 'model')
        self.saver.restore(self.sess, model_location)

    def build_graph(self, size, bright_dark):
        with self.graph.as_default():
            self.input_placeholder = tf.placeholder(dtype=tf.float32, shape=[1, size, size, 1])
            self.prob_of_cone = model.forward_network_softmax(self.input_placeholder, bright_dark)
            self.init_op = tf.global_variables_initializer()
            self.saver = tf.train.Saver()

    def pre_process_numpy(self, image):
        cropped = utilities.crop_center(image, self.size)
        centered = cropped - np.mean(cropped)
        centered = centered[None, :, :, None]
        return centered, cropped

    def network(self, image):
        centered, cropped = self.pre_process_numpy(image)
        feed_dict = {self.input_placeholder: centered}
        prob_map = self.sess.run(self.prob_of_cone, feed_dict=feed_dict)
        prob_map = np.reshape(prob_map, [self.size, self.size])

        return prob_map, cropped

    def get_centers(self, prob_map):
        return self.post_processor.get_centers(prob_map)

    def close_session(self):
        self.sess.close()
