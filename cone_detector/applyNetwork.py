import tensorflow as tf
import numpy as np
import os

from .data import Data
from .regional_max import get_centers
from .model import CONV_MD_32U2L

def run(dataFolder):
    direc = os.path.dirname(os.path.realpath(__file__))
    model_location = os.path.join(direc, 'ckpts', 'model')
    model = CONV_MD_32U2L
    data = Data(dataFolder)
    
    outputs = []

    # process every image with the same maximum square 
    # portion of size size
    for size in data.images_by_size.keys():

        # build graph for this size
        with tf.Graph().as_default():
            with tf.Session() as sess:

                # build graph and restore
                feed_dict = dict()
                image_place = tf.placeholder(dtype = tf.float32, shape = [1, size, size, 1])
                image, out, prob_of_cone = model(image_place)
                saver = tf.train.Saver()
                saver.restore(sess, model_location)

                # process all images where maximum sized cropped is size
                for image_name in data.images_by_size[size]:
                    output_dict = dict()

                    # get image, crop, center, make tensor
                    raw_image = data.grayscale_image(image_name)
                    cropped = Data.crop_center(raw_image, size)
                    centred = cropped - np.mean(cropped)

                    # put through graph
                    feed_dict[image_place] = centred[None,:,:,None]
                    im, prob_map = sess.run([image, prob_of_cone], feed_dict=feed_dict)
                    prob_map = np.reshape(prob_map, [size, size])
                    centres = get_centers(prob_map)
                    output_dict['name'] = image_name
                    output_dict['cropped'] = cropped
                    output_dict['centres'] = centres
                    outputs.append(output_dict)
    return outputs