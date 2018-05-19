# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import os
import pickle
import random

import numpy as np
from matplotlib import pyplot as plt
from matplotlib.widgets import Button
from matplotlib.widgets import RadioButtons


class Annotator:
    """
        takes the output of network, and presents them through 
        a gui for cleanup. Can add and remove points, and maintains 
        seperate lists of original centres and estimated
    """

    def __init__(self, outputs, restart=False):

        if restart:
            pass

        # dictionary with name, cropped image, and centres
        # we shuffle so they cant be biased
        self.outputs_after_annotation = []
        self.raw_network_output = outputs
        random.shuffle(self.raw_network_output)
        self.current_image_id = 0

        # setup the window
        self.fig = plt.figure('Cone Detector')
        ax1 = self.fig.add_subplot(1, 1, 1)
        self.ax1 = ax1

        # add or remove radio button
        self.ADD = 0
        self.REMOVE = 1
        rax = plt.axes([0.05, 0.7, 0.15, 0.15], )
        self.ADD_TEXT = 'Add cone'
        self.REMOVE_TEXT = 'Remove cone'
        self.AR_DICT = {self.ADD_TEXT: self.ADD, self.REMOVE_TEXT: self.REMOVE}
        self.add_or_remove = self.ADD
        radio = RadioButtons(
            rax,
            (self.ADD_TEXT, self.REMOVE_TEXT))
        radio.on_clicked(self.radio_callback)

        # click callback
        self.fig.canvas.mpl_connect('button_press_event', self.onclick)

        # save button
        bax = plt.axes([0.05, 0.4, 0.15, 0.15], )
        save_button = Button(bax, 'Save and next')
        save_button.on_clicked(self.save)

        # collect image data and present
        self.get_next_image(first_image=True)
        self.redraw()
        plt.show()

    def get_next_image(self, first_image=False):
        # get next or first image
        self.current_image_id = 0 if first_image else self.current_image_id + 1
        self.output_dict = self.raw_network_output[self.current_image_id]
        im_name, image, centreList = self.output_dict['name'], self.output_dict['cropped'], self.output_dict['centres']

        # get relavent data from the current output dict
        self.current_image_name = im_name
        self.current_image = image
        if centreList:
            self.current_centroids = np.stack(centreList)
        else:
            self.current_centroids = np.empty(shape=[0, 2])
        self.network_centroids = self.current_centroids
        self.redraw()

    def redraw(self, ):
        """updates figure"""
        self.ax1.cla()
        self.ax1.imshow(self.current_image, cmap='gray')
        self.ax1.axis('off')
        self.ax1.scatter(x=self.current_centroids[:, 1], y=self.current_centroids[:, 0], s=20, c='r')
        number_cones = self.current_centroids.shape[0]
        cone_string = 'Cones: ' + str(number_cones)
        posx, posy = -50, 0
        self.ax1.text(posx, posy, cone_string, fontsize=20)
        self.ax1.figure.canvas.draw()

    def radio_callback(self, label):
        """changes state of annottor to add or remove a point"""
        self.add_or_remove = self.AR_DICT[label]

    def onclick(self, event):
        """clicking adds or removes a point depending on annotator state"""

        # if not in figure
        if event.inaxes != self.ax1.axes: return

        # delete point
        if self.add_or_remove == self.REMOVE:

            # get point clicked and look for closest centroid to it
            point = np.array([event.ydata, event.xdata])
            diff = self.current_centroids - point[None, :]
            diff *= diff
            dist = np.sum(diff, axis=1)
            if self.current_centroids.shape[0] > 0:
                closest_row_index = np.argmin(dist, axis=0)
                closest_point = self.current_centroids[closest_row_index]

                # if within 5 pixels of another point delete it
                # this accounts for not having to click on the exact center
                if dist[closest_row_index] < 5:
                    self.current_centroids = np.delete(self.current_centroids, [closest_row_index], axis=0)

        # add point
        elif self.add_or_remove == self.ADD:
            point = np.array([[event.ydata, event.xdata]])
            self.current_centroids = np.concatenate([self.current_centroids, point])

        # update canvas
        self.redraw()

    def save(self, event):
        """Saves the annotations to a list, which is also saved as a pickle file"""

        # saving old and new information to a list
        original_output_dict = self.raw_network_output[self.current_image_id]
        original_output_dict['correctedCentres'] = self.current_centroids
        original_output_dict['centres'] = self.network_centroids
        self.outputs_after_annotation.append(original_output_dict)

        # saving to temporary folder on windows or linux as pickle
        # we save the current image, with the raw data as well so we 
        # can recover from a crash
        if os.name == 'nt':
            temp_dir = 'C:\\Windows\\Temp'
        else:
            temp_dir = '/tmp'
        filename = os.path.join(temp_dir, 'annotationState.pickle')
        with open(filename, 'wb') as handle:
            state = {
                'currentImageId': self.current_image_id,
                'outputsAfterAnnotation': self.outputs_after_annotation,
                'rawData': self.raw_network_output}
            pickle.dump(state, handle, protocol=pickle.HIGHEST_PROTOCOL)

        # if we have done all images finish
        number_of_images = len(self.raw_network_output)
        if self.current_image_id < number_of_images - 1:
            self.get_next_image()
        else:
            plt.close()
