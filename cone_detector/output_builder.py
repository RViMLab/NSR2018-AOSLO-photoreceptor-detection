# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import csv
import datetime
import os

import matplotlib.pyplot as plt
import numpy as np
from PIL import Image

from .stats_calculator import StatsCalculator


def build_output(outputs, data_folder, corrected):

    # building the um_per_pix dict
    # find the csv file
    files = os.listdir(data_folder)
    csv_file_name = None
    for f in files:
        if '.csv' == f[-4:]:
            csv_file_name = f
            break

    assert csv_file_name is not None

    # extract name and conversion
    um_per_pix_dict = {}
    with open(os.path.join(data_folder, csv_file_name), 'r') as csv_file:
        reader = csv.reader(csv_file)
        for row in reader:
            row = [x for x in row if not x == '']
            um_per_pix_dict[row[0]] = float(row[1])

    cwd = os.getcwd()
    now = str(datetime.datetime.now()).replace(':', '')
    output_folder = os.path.join(cwd, str(now))
    alg_figure_folder = os.path.join(output_folder, 'algorithmFigures')
    alg_folder = os.path.join(output_folder, 'algorithmMarkers')
    image_folder = os.path.join(output_folder, 'images')
    os.makedirs(output_folder)
    os.makedirs(alg_figure_folder)
    os.makedirs(alg_folder)
    os.makedirs(image_folder)

    if corrected:
        corrected_figure_folder = os.path.join(output_folder, 'correctedFigures')
        corrected_folder = os.path.join(output_folder, 'correctedMarkers')
        os.makedirs(corrected_figure_folder)
        os.makedirs(corrected_folder)


    def centreToCSV(centers, image_name, fldr):
        with open(os.path.join(fldr, image_name + '.csv'), 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            for row, col in centers:
                center = [col, row]
                writer.writerow(center)

    def statsCSV(stats, image_name):
        filename = os.path.join(output_folder, 'stats.csv')
        file_exists = os.path.isfile(filename)
        headers = list(stats.keys())
        headers.remove('name')
        headers.sort()
        headers.insert(0, 'name')
        with open(filename, 'a', newline='') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=headers)
            if not file_exists:
                writer.writeheader()
            writer.writerow(stats)

    def numpy_to_list(arr):
        get_points = lambda x: (x[0, 0], x[0, 1])
        list_centers = list(map(
            get_points,
            np.split(arr, arr.shape[0], axis=0)))
        return list_centers

    def arrayToGrayscale(array):
        array = array.astype(np.float32)
        array = array - array.min()
        array = array / array.max()
        array = array * 255.
        return array.astype(np.uint8)

    for d in outputs:

        if corrected:
            im_name, image, algCentre, correctedCentre = d['name'], d['cropped'], d['centres'], d['correctedCentres']
        else:
            im_name, image, algCentre = d['name'], d['cropped'], d['centres']
            # hack after changing so that can choose whether to manually adjust
            algCentre = np.stack(algCentre)
            d['centres'] = algCentre

        # save image
        im = Image.fromarray(arrayToGrayscale(image))
        im.save(os.path.join(image_folder, im_name))
        patient_name = '_'.join(im_name.split('_')[:2])

        # algorithm figure
        algCentre = numpy_to_list(algCentre)
        fig = plt.imshow(image, cmap='gray')
        ax = fig.axes
        ax.axis('off')
        ax.get_xaxis().set_visible(False)
        ax.get_yaxis().set_visible(False)
        xx = np.array(list(map(lambda e: float(e[1]), algCentre)))
        yy = np.array(list(map(lambda e: float(e[0]), algCentre)))
        plt.scatter(x=xx, y=yy, c='yellow', s=20)
        plt.savefig(
            os.path.join(alg_figure_folder, im_name + '.png'),
            bbox_inches='tight',
            transparent=True,
            pad_inches=0)
        plt.cla()

        # raw csv
        centreToCSV(algCentre, im_name, alg_folder)

        if corrected:
            # corrected figure
            correctedCentre = numpy_to_list(correctedCentre)
            fig = plt.imshow(image, cmap='gray')
            ax = fig.axes
            ax.axis('off')
            ax.get_xaxis().set_visible(False)
            ax.get_yaxis().set_visible(False)
            xx = np.array(list(map(lambda e: float(e[1]), correctedCentre)))
            yy = np.array(list(map(lambda e: float(e[0]), correctedCentre)))
            plt.scatter(x=xx, y=yy, c='yellow', s=20)
            plt.savefig(
                os.path.join(corrected_figure_folder, im_name + '.png'),
                transparent=True,
                bbox_inches='tight',
                pad_inches=0)
            plt.cla()

            # corrected csv
            centreToCSV(correctedCentre, im_name, corrected_folder)

        # work out stats
        statsCalculator = StatsCalculator(d, um_per_pix_dict[patient_name])
        stats = statsCalculator.get_image_stats()
        statsCSV(stats, im_name)
