# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import os
import csv
import datetime
import matplotlib.pyplot as plt
from .stats_calculator import StatsCalculator

from PIL import Image
import numpy as np

def build_output(correctedOutput, data_folder):
    cwd = os.getcwd()
    now = str(datetime.datetime.now()).replace(':', '')
    output_folder = os.path.join(cwd, str(now))
    alg_figure_folder = os.path.join(output_folder, 'algorithmFigures')
    corrected_figure_folder = os.path.join(output_folder, 'correctedFigures')
    alg_folder = os.path.join(output_folder, 'algorithmMarkers')
    corrected_folder = os.path.join(output_folder, 'correctedMarkers')
    image_folder = os.path.join(output_folder, 'images')

    def centreToCSV(centers, image_name, fldr):
        with open(os.path.join(fldr, image_name+'.csv'), 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            for row, col in centers:
                center = [col, row]
                writer.writerow(center)

    def statsCSV(stats, image_name):
        filename = os.path.join(output_folder, 'stats.csv')
        file_exists = os.path.isfile(filename)
        headers = list(stats.keys())
        for idx, field in enumerate(headers):
            if field=='name':
                break

        temp = headers[0]
        headers[0] = headers[idx]
        headers[idx] = temp

        with open(filename, 'a') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=headers)
            if not file_exists:
                writer.writeheader()
            writer.writerow(stats)

    def numpy_to_list(arr):
        get_points = lambda x: (x[0,0], x[0,1])
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
            um_per_pix_dict[row[0]] = float(row[1])

    os.makedirs(output_folder)
    os.makedirs(alg_figure_folder)
    os.makedirs(corrected_figure_folder)
    os.makedirs(corrected_folder)
    os.makedirs(alg_folder)
    os.makedirs(image_folder)

    for d in correctedOutput['outputsAfterAnnotation']:
        im_name, image, algCentre, correctedCentre = d['name'], d['cropped'], d['centres'], d['correctedCentres']
        
        # save image
        im = Image.fromarray(arrayToGrayscale(image))
        im.save(os.path.join(image_folder, im_name))
        patient_name = '_'.join(im_name.split('_')[:2])

        # algorithm figure
        algCentre = numpy_to_list(algCentre)
        plt.imshow(image, cmap='gray')
        xx=np.array(list(map(lambda e: float(e[1]), algCentre)))
        yy=np.array(list(map(lambda e: float(e[0]), algCentre)))
        plt.scatter(x=xx, y=yy, c='white', s=10, marker='+')
        plt.axis('off')
        plt.tight_layout()
        plt.savefig(os.path.join(alg_figure_folder, im_name + '.png'), transparent=True)
        plt.cla()

        # algorithm figure
        correctedCentre = numpy_to_list(correctedCentre)
        plt.imshow(image, cmap='gray')
        xx=np.array(list(map(lambda e: float(e[1]), correctedCentre)))
        yy=np.array(list(map(lambda e: float(e[0]), correctedCentre)))
        plt.scatter(x=xx, y=yy, c='white', s=10, marker='+')
        plt.axis('off')
        plt.tight_layout()
        plt.savefig(os.path.join(corrected_figure_folder, im_name + '.png'), transparent=True)
        plt.cla()

        # save corrected and algorithm as csv
        centreToCSV(correctedCentre, im_name, corrected_folder)
        centreToCSV(algCentre, im_name, alg_folder)

        # work out stats
        statsCalculator = StatsCalculator(d, um_per_pix_dict[patient_name])
        stats = statsCalculator.get_image_stats()
        statsCSV(stats, im_name)
            


