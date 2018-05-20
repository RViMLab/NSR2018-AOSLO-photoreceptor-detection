import tensorflow as tf
import numpy as np
from . import constants
import os
import csv

def expand_centroids(examples):

    def list_to_array(image, center_list):
        h, w = image.shape
        segmentation = np.zeros([h,w], dtype=np.uint8)
        c = np.split(center_list, center_list.shape[0], axis=0)
        for r in c:
            segmentation[r[0,0], r[0,1]] = 1

        return segmentation

    examples = [{
        'segmentation':ex['correctedCentres'].astype(np.uint8),
        'image': ex['cropped'].astype(np.uint8),
        'height':np.array(ex['cropped'].shape[0], dtype=np.uint8),
        'width': np.array(ex['cropped'].shape[1], dtype=np.uint8)} for ex in examples]

    radius = 5
    y, x = np.ogrid[-radius:radius + 1, -radius:radius + 1]
    disk = x ** 2 + y ** 2 <= radius ** 2
    disk = disk.astype(np.uint8)
    for ex in examples:
        arr = list_to_array(ex['image'], ex['segmentation'])
        segmentation = np.copy(arr)

        for col in range(arr.shape[1]):
            for row in range(arr.shape[0]):
                if arr[row, col] == 1:
                    for offset_row in range(2 * radius + 1):
                        for offset_col in range(2 * radius + 1):
                            row_pos = row - radius + offset_row
                            col_pos = col - radius + offset_col
                            try:
                                if segmentation[row_pos, col_pos]==0:
                                    segmentation[row_pos, col_pos] = disk[offset_row, offset_col]
                            except IndexError:
                                continue

        ex['segmentation'] = segmentation

    return examples

def to_tfrecord(tfrecord_name, data_examples):
    """
        take list of dict examples with
            value = np.array

    """

    def _bytes_feature(value):
        return tf.train.Feature(bytes_list=tf.train.BytesList(value=[value]))

    flder = os.path.join(constants.DATA_DIREC, tfrecord_name)
    os.mkdir(flder)
    tfrecord_name = os.path.join(flder, 'data.tfrecord')

    writer = tf.python_io.TFRecordWriter(tfrecord_name)

    min_im_size = np.inf
    for example in data_examples:
        features_dict = dict()
        for feature in example.keys():
            if feature=='image':
                min_im_size = np.min(example[feature].shape)
            feature_value = example[feature]
            features_dict[feature] = _bytes_feature(feature_value.tostring())

        example = tf.train.Example(features=tf.train.Features(feature=features_dict))
        writer.write(example.SerializeToString())
    writer.close()

    with open(os.path.join(flder, 'info.csv'), 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        row = [min_im_size, len(data_examples)]
        writer.writerow(row)

def write_dataset(data_name, examples):
    examples = expand_centroids(examples)
    to_tfrecord(data_name, examples)