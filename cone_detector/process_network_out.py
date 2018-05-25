import scipy.ndimage.filters as filters
from skimage.measure import regionprops, label
from . import constants
from . import utilities
import os
import csv


class PostProcessor:

    def __init__(self, mname):
        self.model_name = mname

    def get_csv_path(self):
        return os.path.join(constants.MODEL_DIREC, self.model_name, 'params.csv')

    def get_info(self):
        with open(self.get_csv_path(), 'r') as csvfile:
            reader = csv.reader(csvfile)
            for row in reader:
                return [float(x) for x in row]

    def get_centers(self, prob_map):
        if self.model_name == constants.PAPER_MODEL:
            joint = [1.05263158, 0.88571429]
            healthy = [1.05263158, 0.88571429]
            stgd = [1.68421053, 0.98367347]
            estimated_centroids = PostProcessor.get_centers_static(prob_map, joint[0], joint[1])
            if len(estimated_centroids) > 0.0011 * prob_map.shape[0] * prob_map.shape[1]:
                estimated_centroids = PostProcessor.get_centers_static(prob_map, healthy[0], healthy[1])
            else:
                estimated_centroids = PostProcessor.get_centers_static(prob_map, stgd[0], stgd[1])
        else:
            joint = self.get_info()
            estimated_centroids = PostProcessor.get_centers_static(prob_map, joint[0], joint[1])
        return estimated_centroids

    @staticmethod
    def smooth(prob_map, sigma):
        smoothed = filters.gaussian_filter(prob_map, sigma)
        return smoothed

    @staticmethod
    def im_extended_max(I):
        max_vals = filters.maximum_filter(I, size=(7, 7))
        mask = (max_vals - I) <= 0
        return mask

    @staticmethod
    def reject_weak(mask, value_array, thresh):
        centers = [x.centroid for x in regionprops(label(mask), intensity_image=value_array) if
                     x.max_intensity > thresh]
        return centers

    @staticmethod
    def join_close_centers(centers, shape):
        """
            make mask with disks rather than points
        """
        if not centers:
            return []

        dialiated = utilities.expand_centers(centers, shape[0], shape[1], radius=4)
        centers = [x.centroid for x in regionprops(label(dialiated))]

        return centers

    @staticmethod
    def remove_from_border(centers, height, width):
        new_list = []
        border_thresh = constants.BORDER_THRESH
        for row in centers:
            if border_thresh < row[0] < height - border_thresh and border_thresh < row[1] < width - border_thresh:
                new_list.append(row)
        return new_list

    @staticmethod
    def get_centers_static(I, sigma, thresh):
        smoothed = PostProcessor.smooth(I, sigma)
        mask = PostProcessor.im_extended_max(smoothed)
        centers = PostProcessor.reject_weak(mask, smoothed, thresh)
        joined = PostProcessor.join_close_centers(centers, I.shape)
        without_border = PostProcessor.remove_from_border(joined, I.shape[0], I.shape[1])
        return without_border
