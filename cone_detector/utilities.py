import numpy as np


def crop_center(img, size):
    y, x = img.shape
    startx = x // 2 - (size // 2)
    starty = y // 2 - (size // 2)
    return img[starty:starty + size, startx:startx + size]


def list_to_array(h, w, center_list):
    """centers are row, column"""
    array = np.zeros([h, w], dtype=np.uint8)
    for r in center_list:
        array[r[0, 0], r[0, 1]] = 1

    return array


def array_to_list(arr):
    non_zero = np.transpose(np.nonzero(arr > 0))
    non_zero_list = [(x[0,0], x[0,1]) for x in np.split(non_zero, non_zero.shape[0], axis=0)]
    return non_zero_list


def array_to_grayscale(array):
    array = array.astype(np.float32)
    array = array - array.min()
    array = array / array.max()
    array = array * 255.
    return array.astype(np.uint8)


def expand_centers(centers, height, width, radius=5):

    y, x = np.ogrid[-radius:radius + 1, -radius:radius + 1]
    disk = x ** 2 + y ** 2 <= radius ** 2
    disk = disk.astype(np.uint8)

    segmentation = np.zeros([height, width], dtype=np.uint8)

    for row, col in centers:
        row = int(row)
        col = int(col)
        for offset_row in range(2 * radius + 1):
            for offset_col in range(2 * radius + 1):
                row_pos = row - radius + offset_row
                col_pos = col - radius + offset_col
                try:
                    if segmentation[row_pos, col_pos] == 0:
                        segmentation[row_pos, col_pos] = disk[offset_row, offset_col]
                except IndexError:
                    continue

    return segmentation


def location_array(centers, height, width):

    arr = np.zeros([height, width], dtype=np.uint8)

    for row, col in centers:
        arr[row, col] = 1

    return arr