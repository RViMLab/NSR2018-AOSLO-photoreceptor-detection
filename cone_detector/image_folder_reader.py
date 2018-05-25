# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import os

import numpy as np
from PIL import Image

from . import constants


class ImageFolder:

    def __init__(self, location):
        self.location = location
        self.images_by_size = self.get_image_names_by_size()

    def get_image_names(self):
        image_names = []
        for file_name in os.listdir(self.location):
            if constants.TIF in file_name.split('.')[-1]:
                image_names.append(file_name)
        return image_names

    def name_to_path(self, name):
        return os.path.join(self.location, name)

    def grayscale_image(self, image_name):
        image_path = self.name_to_path(image_name)
        im = Image.open(image_path)
        if len(im.split()) > 1:
            im = im.split()[0]

        # PIL uses column row
        im = np.array(im.getdata(), dtype=np.uint8).reshape(im.size[1], im.size[0])
        return im

    def get_images(self, ):
        images = []

        image_names = self.get_image_names()
        for image_name in image_names:
            im = self.grayscale_image(image_name)
            images.append(im)

        return images

    def get_image_names_by_size(self):
        images_by_size = {}
        image_names = self.get_image_names()
        for image_name in image_names:
            image = self.grayscale_image(image_name)
            size = min(image.shape)
            try:
                images_by_size[size].append(image_name)
            except KeyError:
                images_by_size[size] = [image_name]

        return images_by_size
