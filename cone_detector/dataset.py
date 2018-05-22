import os
import csv
import tensorflow as tf
import numpy as np

from . import constants

class DataSet:

    data_file = 'data.tfrecord'
    info_file = 'info.csv'

    def __init__(self, name):
        self.name = name
        self.folder = os.path.join(constants.DATA_DIREC, self.name)

    def get_data_path(self):
        return os.path.join(self.folder, DataSet.data_file)

    def get_info_path(self):
        return os.path.join(self.folder, DataSet.info_file)

    def get_info(self):
        csv_path = self.get_info_path()
        with open(csv_path, 'r') as csvfile:
            reader = csv.reader(csvfile)
            for row in reader:
                return row

    def get_num_images(self):
        return self.get_info()[1]

    def get_min_image_size(self):
        return self.get_info()[0]

    def make_folder(self):
        os.mkdir(self.folder)

    def write_csv(self, num_examples, min_size):
        with open(self.get_info_path(), 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            row = [min_size, num_examples]
            writer.writerow(row)

    def write_tfrecord(self, examples):
        writer = tf.python_io.TFRecordWriter(self.get_data_path())

        for output in examples:
            tf_example = output.to_tf_record()
            writer.write(tf_example.SerializeToString())

        writer.close()

    def create_dataset(self, examples):
        self.make_folder()
        self.write_tfrecord(examples)

        num_examples = len(examples)
        min_size = np.inf
        for e in examples:
            if min(e.image.shape) < min_size:
                min_size = min(e.image.shape)
        self.write_csv(num_examples, min_size)