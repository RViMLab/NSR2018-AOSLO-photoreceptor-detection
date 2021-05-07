import numpy as np
import tensorflow.compat.v1 as tf

from . import utilities


class Output:
    def __init__(self, **kwargs):
        if 'output' in kwargs.keys():
            output = kwargs['output']
            self.name = output.name
            self.image = output.image
            self.segmentation = output.segmentation
            self.actual_centers = output.actual_centers
            self.estimated_centers = output.estimated_centers
        else:
            self.name = kwargs['name']
            self.image = kwargs['image']
            self.segmentation = None
            self.actual_centers = None
            self.estimated_centers = None

    def set_estimated_centres(self, centers):
        self.estimated_centers = centers

    def set_actual_centers(self, centers):
        self.actual_centers = centers

    def set_segmentation(self, arr):
        self.segmentation = arr

    def build_segmentation(self):
        if self.segmentation is not None:
            return

        if self.actual_centers is not None:
            self.segmentation = utilities.expand_centers(
                self.actual_centers,
                self.image.shape[0],
                self.image.shape[1])
        else:
            raise ValueError('There are no centers to create segmentation from')

    def build_location_arr(self):
        if self.actual_centers is not None:
            arr = utilities.location_array(
                self.actual_centers,
                self.image.shape[0],
                self.image.shape[1])

            return arr
        else:
            raise ValueError('There are no centers to create segmentation from')

    def to_tf_record(self):
        self.build_segmentation()
        arr = self.build_location_arr()

        features = {
            'segmentation': self.segmentation.astype(np.uint8),
            'image': self.image.astype(np.uint8),
            'height': np.array(self.image.shape[0], dtype=np.uint8),
            'width': np.array(self.image.shape[1], dtype=np.uint8),
            'location': arr}

        def _bytes_feature(value):
            return tf.train.Feature(bytes_list=tf.train.BytesList(value=[value]))

        for key in features:
            features[key] = _bytes_feature(features[key].tostring())

        tf_record = tf.train.Example(features=tf.train.Features(feature=features))
        return tf_record
