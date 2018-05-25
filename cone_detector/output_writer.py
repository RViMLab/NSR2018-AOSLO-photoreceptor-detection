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

from . import utilities
from .stats_calculator import StatsCalculator


class OutputWriter:

    def __init__(self, outputs, data_folder, lut_csv):
        self.lut_name = lut_csv
        self.data_folder = data_folder
        self.um_to_pix = None
        self.outputs = outputs
        self.output_folder = None
        self.image_folder = None
        self.alg_figure_folder = None
        self.alg_folder = None
        self.corrected_figure_folder = None
        self.corrected_folder = None

    def get_lut_path(self):
        return os.path.join(self.data_folder, self.lut_name)

    def get_um_to_pix(self):
        # extract name and conversion
        um_per_pix_dict = {}
        with open(self.get_lut_path(), 'r') as csv_file:
            reader = csv.reader(csv_file)
            for row in reader:
                row = [x for x in row if not x == '']
                um_per_pix_dict[row[0].lower()] = float(row[1])
        self.um_to_pix = um_per_pix_dict

    def has_been_corrected(self):
        return self.outputs[0].actual_centers is not None

    def prepare_folders(self):
        cwd = os.getcwd()
        now = str(datetime.datetime.now()).replace(':', '')
        self.output_folder = os.path.join(cwd, str(now))
        self.alg_figure_folder = os.path.join(self.output_folder, 'algorithmFigures')
        self.alg_folder = os.path.join(self.output_folder, 'algorithmMarkers')
        self.image_folder = os.path.join(self.output_folder, 'images')
        os.makedirs(self.output_folder)
        os.makedirs(self.alg_figure_folder)
        os.makedirs(self.alg_folder)
        os.makedirs(self.image_folder)

        if self.has_been_corrected():
            self.corrected_figure_folder = os.path.join(self.output_folder, 'correctedFigures')
            self.corrected_folder = os.path.join(self.output_folder, 'correctedMarkers')
            os.makedirs(self.corrected_figure_folder)
            os.makedirs(self.corrected_folder)

    @staticmethod
    def center_to_csv(centers, image_name, fldr):
        path = os.path.join(fldr, image_name + '.csv')
        with open(path, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            for row, col in centers:
                center = [col, row]
                writer.writerow(center)

    @staticmethod
    def stats_csv(stats, flder):
        filename = os.path.join(flder, 'stats.csv')
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

    @staticmethod
    def get_subject_id(output):
        name = output.name
        subject_id = '_'.join(name.split('_')[:2])
        return subject_id

    def save_image(self, image, image_name):
        grayscale = utilities.array_to_grayscale(image)
        im = Image.fromarray(grayscale)
        im.save(os.path.join(self.image_folder, image_name))

    @staticmethod
    def save_figure(image, folder, name, centers):
        # algorithm figure
        fig = plt.imshow(image, cmap='gray')
        ax = fig.axes
        ax.axis('off')
        ax.get_xaxis().set_visible(False)
        ax.get_yaxis().set_visible(False)
        xx = np.array(list(map(lambda e: float(e[1]), centers)))
        yy = np.array(list(map(lambda e: float(e[0]), centers)))
        plt.scatter(x=xx, y=yy, c='yellow', s=20)
        plt.savefig(
            os.path.join(folder, name + '.png'),
            bbox_inches='tight',
            transparent=True,
            pad_inches=0)
        plt.cla()

    def save_figures_and_center_locations(self, output):
        self.save_image(output.image, output.name)
        OutputWriter.save_figure(output.image, self.alg_figure_folder, output.name, output.estimated_centers)
        OutputWriter.center_to_csv(output.estimated_centers, output.name, self.alg_folder)
        if self.has_been_corrected():
            OutputWriter.save_figure(output.image, self.corrected_figure_folder, output.name, output.estimated_centers)
            OutputWriter.center_to_csv(output.actual_centers, output.name, self.corrected_folder)

    def save_stats(self, output):

        um_to_px = self.um_to_pix[self.get_subject_id(output).lower()]
        calculator = StatsCalculator(output, um_to_px)
        stats = calculator.get_image_stats()
        OutputWriter.stats_csv(stats, self.output_folder)

    def write_output(self):
        self.prepare_folders()
        self.get_um_to_pix()
        for output in self.outputs:
            self.save_figures_and_center_locations(output)
            self.save_stats(output)
