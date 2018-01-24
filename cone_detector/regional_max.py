# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import scipy.ndimage.filters as filters
import numpy as np

from skimage.measure import regionprops, label

def remove_from_border(c_list, height, width):
    new_list = []
    border_thresh = 7
    for row in c_list:
        if  border_thresh < row[0] < height - border_thresh and border_thresh < row[1] < width - border_thresh:
            new_list.append(row)
    return new_list

def smooth(prob_map, sigma):
    smoothed = filters.gaussian_filter(prob_map, sigma)
    return smoothed

def im_extended_max(I, h):
    max_vals = filters.maximum_filter(I, size=(7,7))
    mask = (max_vals - I) <= h
    return mask

def reject_weak(mask, value_array, thresh):
    centroids = [x.centroid for x in regionprops(label(mask), intensity_image=value_array) if x.max_intensity > thresh]
    return centroids

def post_process(I, sigma, h, thresh):
    smoothed = smooth(I, sigma)
    mask = im_extended_max(I, h)
    centroids = reject_weak(mask, smoothed, thresh)
    return remove_from_border(centroids, I.shape[0], I.shape[1])

def expand_centroids(centroids, shape):
    """
        make mask with disks rather than points
    """
    mask_matrix = np.zeros(shape)
    if centroids.shape[0] > 0:
        centroids = map(lambda x: np.squeeze(x), np.split(centroids, centroids.shape[0]))
    else:
        return []

    for center in centroids:
        mask_matrix[center[0], center[1]] = 1

    radius = 4
    y, x = np.ogrid[-radius:radius + 1, -radius:radius + 1]
    mask = x**2 + y**2 <= radius**2
    mask = mask.astype(np.int16)
    r, c = mask_matrix.shape
    expanded = np.zeros([r,c])
    for i in range(r):
        for j in range(c):
            if mask_matrix[i,j] == 1:
                for ii in range(2*radius+1):
                    for jj in range(2*radius+1):
                        try:
                            if expanded[i - radius + ii, j - radius + jj] != 1:
                                expanded[i - radius + ii, j - radius + jj] = mask[ii, jj]
                        except IndexError:
                            continue
    centroids = [x.centroid for x in regionprops(label(expanded))]

    return centroids
    
def get_centroids(prob_map, sigma, h, thresh):
    
    # expand then collapse (absorbing close centroids into 1)
    centroids = post_process(prob_map, sigma, h, thresh)
    #centroids = np.stack(centroids)
    if centroids:
        centroids = expand_centroids(np.stack(centroids, axis=0).astype(np.int16), prob_map.shape)
    return centroids

def get_centers(prob_map):
    joint = [4., 0.29795918]
    healthy = [3.78947368, 0.21632653]
    estimated_centroids = get_centroids(prob_map, joint[0], 0., joint[1])
    if len(estimated_centroids) > 0.0011 * prob_map.shape[0]*prob_map.shape[1]:
        estimated_centroids = get_centroids(prob_map, healthy[0], 0., healthy[1])
    estimated_centroids = remove_from_border(estimated_centroids, prob_map.shape[0], prob_map.shape[1])
    return estimated_centroids
