import tensorflow as tf
from . import constants

def flip(image_tensor, annotation_tensor):
    """Accepts image tensor and annotation tensor and returns randomly flipped tensors of both.
    The function performs random flip of image and annotation tensors with probability of 1/2
    The flip is performed or not performed for image and annotation consistently, so that
    annotation matches the image.
    
    Parameters
    ----------
    image_tensor : Tensor of size (width, height, 3)
        Tensor with image
    annotation_tensor : Tensor of size (width, height, 1)
        Tensor with annotation
        
    Returns
    -------
    randomly_flipped_img : Tensor of size (width, height, 3) of type tf.float.
        Randomly flipped image tensor
    randomly_flipped_annotation : Tensor of size (width, height, 1)
        Randomly flipped annotation tensor
        
    """
    
    # Random variable: two possible outcomes (0 or 1)
    # with a 1 in 2 chance
    random_var = tf.random_uniform(maxval=2, dtype=tf.int32, shape=[])


    randomly_flipped_img = tf.cond(
        tf.equal(random_var, 0),
        lambda: tf.image.flip_up_down(image_tensor),
        lambda: image_tensor)

    randomly_flipped_annotation = tf.cond(
        tf.equal(random_var, 0),
        lambda: tf.image.flip_up_down(annotation_tensor),
        lambda: annotation_tensor)
    
    return randomly_flipped_img, randomly_flipped_annotation


def read_and_decode(filename_queue, ):

    # create reader
    reader = tf.TFRecordReader()

    # get the serialized example
    _, serialized_example = reader.read(filename_queue)

    # convert to dict of serialized features
    feature_info = dict(
        height=tf.uint8,
        width=tf.uint8,
        image=tf.uint8,
        segmentation=tf.uint8)

    features = dict()
    for key in feature_info.keys():
        features[key] = tf.FixedLenFeature([], tf.string)

    features = tf.parse_single_example(serialized_example, features=features)

    # convert to actual values
    for feature in features.keys():
        features[feature] = tf.decode_raw(features[feature], feature_info[feature])

    return features


def pre_process(features):

    crop_shape = [constants.SIZE, constants.SIZE, 2]

    def padding(dim_size):
        dim_size = tf.cast(dim_size, tf.int32)
        padding = tf.cond(dim_size - constants.SIZE < 0, lambda:constants.SIZE - dim_size, lambda:0)
        return tf.stack([padding//2, padding-padding//2])

    height, width = features['height'][0], features['width'][0]
    im_shape = tf.cast(tf.stack([height, width]), tf.int32)
    image = features['image']

    segmentation = features['segmentation']
    image = tf.reshape(image, im_shape)
    segmentation = tf.reshape(segmentation, im_shape)

    pad_h = padding(height)
    pad_w = padding(width)
    
    image = tf.pad(image, tf.stack([pad_h, pad_w]))
    segmentation = tf.pad(segmentation, tf.stack([pad_h, pad_w]))
    cropped = tf.random_crop(
            tf.stack([image, segmentation], axis=2),
            crop_shape)
    image, segmentation = tf.split(cropped, 2, axis = 2)


    image = tf.cast(image, dtype=tf.float32)
    pro_image = image - tf.reduce_mean(image)

    one_hot_seg = tf.one_hot(
        tf.squeeze(segmentation), 
        depth=2, 
        on_value=1., 
        dtype=tf.float32)

    pro_image, one_hot_seg = flip(pro_image, one_hot_seg)
    pro_image = tf.expand_dims(pro_image, axis=0)

    return pro_image[0,:,:,:], one_hot_seg

def pipeline(filename, batch_size=1, num_epochs=1):
    filename_queue = tf.train.string_input_producer(
          filename, 
          num_epochs=num_epochs, 
          shuffle=False)
    features = read_and_decode(filename_queue)
    example, label = pre_process(features)
    min_after_dequeue = 0
    capacity = 48
    example_batch, label_batch = tf.train.shuffle_batch(
        [example, label], 
        batch_size=batch_size, 
        capacity=capacity,
        min_after_dequeue=min_after_dequeue,
        allow_smaller_final_batch=True,)
    return example_batch, label_batch