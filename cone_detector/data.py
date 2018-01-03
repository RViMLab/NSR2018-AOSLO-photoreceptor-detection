import os
import numpy as np
import sys
import matplotlib.pyplot as plt
import csv

from datetime import datetime
from PIL import Image

class Data:

    @staticmethod
    def crop_center(img,size):
        y,x = img.shape
        startx = x//2-(size//2)
        starty = y//2-(size//2)    
        return img[starty:starty+size,startx:startx+size]


    def __init__(self, location):
        self.location = location
        self.images_by_size = self.get_images_by_size()

    def grayscale_image(self, image_name):
        image_path = os.path.join(self.location, image_name)
        im = Image.open(image_path)
        if im.split() > 1:
            im = im.split()[0]
        im = np.array(im.getdata(), dtype = np.uint8).reshape(im.size[1], im.size[0])
        return im

    def get_images_by_size(self,):
        images_by_size = {}

        for image in os.listdir(self.location):
            if 'tif' in image.split('.')[-1]:
                image_path = os.path.join(self.location, image)
                im = self.grayscale_image(image)
                size = min(im.shape)
                if size not in images_by_size.keys():
                    images_by_size[size] = [image]
                else:
                    images_by_size[size].append(image)

        return images_by_size

    def arrayToGrayscale(self, array):
        array = array.astype(np.float32)
        array = array - array.min()
        array = array / array.max()
        array = array * 255.
        return array.astype(np.uint8)

    def build_output(self, imageCentreList): 
        cwd = os.getcwd()
        now = datetime.now()
        output_folder = os.path.join(cwd, str(now))
        figure_folder = os.path.join(output_folder, 'figures')
        position_folder = os.path.join(output_folder, 'markers')
        image_folder = os.path.join(output_folder, 'images')

        def centreToCSV(centers, image_name):
            with open(os.path.join(position_folder, image_name+'.csv'), 'wb') as csvfile:
                fieldnames = ['row', 'col']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                center = dict()
                for row, col in centers:
                    center['row'] = row
                    center['col'] = col
                    writer.writerow(center)

        number_figures = 10
        saved_figure = 0
        os.makedirs(output_folder)
        os.makedirs(figure_folder)
        os.makedirs(position_folder)
        os.makedirs(image_folder)

        for im_name, image, centreList in imageCentreList:
            plt.imshow(image, cmap='gray')
            xx=np.array(map(lambda e: float(e[1]), centreList))
            yy=np.array(map(lambda e: float(e[0]), centreList))
            plt.scatter(x=xx, y=yy, c='white', s=10, marker='+')
            plt.axis('off')
            plt.tight_layout()
            plt.savefig(os.path.join(figure_folder, im_name + '.png'), transparent=True)
            plt.cla()
            saved_figure += 1
            
            centreToCSV(centreList, im_name)
            im = Image.fromarray(self.arrayToGrayscale(image))
            im.save(os.path.join(image_folder, im_name))
