import numpy as np
from scipy.signal import convolve2d
from scipy.spatial import Voronoi, Delaunay
from scipy.spatial.qhull import QhullError


class StatsCalculator:

    def __init__(self, output, um_per_pix):
        self.image_name = output.name
        self.image = output.image
        self.networkCentres = output.estimated_centers
        self.humanCentres = output.actual_centers

        self.um_per_pix = um_per_pix
        self.height, self.width = self.image.shape

    def meanNNDist(self, arr):
        if arr is None:
            return
        if arr.shape[0] <= 1:
            return {'meanNN': 'notEnoughPoints'}
        difference = arr[None, :, :] - arr[:, None, :]
        distanceSqrd = (difference * difference).sum(axis=2)
        distance = np.sqrt(distanceSqrd)
        maxD = np.max(distance)
        distance += np.eye(difference.shape[0]) * maxD
        closest_neighbours = np.sort(distance)[:, 0]
        return {'meanNN': np.mean(closest_neighbours) * self.um_per_pix}

    def voronoi(self, arr):

        def polyArea(x, y):
            return 0.5 * np.abs(np.dot(x, np.roll(y, 1)) - np.dot(y, np.roll(x, 1)))

        def volArea(vor_obj, i):
            xPoints = []
            yPoints = []
            for point_index in vor_obj.regions[i]:
                xPoints.append(vor_obj.vertices[point_index][0])
                yPoints.append(vor_obj.vertices[point_index][1])

            xPoints = np.array(xPoints)
            yPoints = np.array(yPoints)
            return polyArea(xPoints, yPoints)

        bounded = np.zeros(arr.shape[0], dtype=np.bool)
        try:
            vor = Voronoi(arr)
        except (QhullError, ValueError):
            return {
                'bound': 'notEnoughPoints',
                'vorVolume': 'notEnoughPoints',
                'vorSides': 'notEnoughPoints',
                'vorSix': 'notEnoughPoints',
                'vorDensity': 'notEnoughPoints'}

        point_region = vor.point_region
        number_bounded = 0.
        volumes = []
        sides = []
        for idx, region in enumerate(vor.regions):

            # if finite
            if -1 in region:
                continue
            else:
                number_bounded += 1.
                bounded[point_region == idx] = True
            sides.append(len(region))
            volumes.append(volArea(vor, idx))

        if volumes:
            volume_array = np.array(volumes)
            std = np.std(volume_array * self.um_per_pix)
            std = std if std != 0. else 1.
            volume = np.mean(volume_array * self.um_per_pix) / std
            vor_density = number_bounded / np.sum(volume * self.um_per_pix)
        else:
            volume = 0.
            vor_density = 0.
        if sides:
            sides_array = np.array(sides) + 1
            num_sixes = (sides_array == 6).sum()
            std = np.std(sides_array)
            std = std if std != 0. else 1.
            sides = np.mean(sides_array) / std
            six_sides = (float(num_sixes) / sides_array.shape[0]) * 100.
        else:
            six_sides = 0.
            sides = 0.

        return {'bound': bounded, 'vorVolume': volume, 'vorSides': sides, 'vorSix': six_sides,
                'vorDensity': vor_density}

    def intercell_distance(self, arr, bnd):

        try:
            dt = Delaunay(arr)
        except (QhullError, ValueError):
            return {'icMax': 'notEnoughPoints', 'icMin': 'notEnoughPoints', 'icMean': 'notEnoughPoints'}

        indPtr, indices = dt.vertex_neighbor_vertices
        max_neighbour = []
        min_neighbour = []
        mean_neighbour = []

        for vertex in range(indPtr.shape[0] - 1):
            if not bnd[vertex]:
                continue

            neighbours = indices[indPtr[vertex]:indPtr[vertex + 1]]

            vert_point = arr[vertex, :]
            neighbours = arr[neighbours, :]
            distance = neighbours - vert_point[None, :]
            distance = np.sqrt((distance * distance).sum(axis=1))

            max_d = np.max(distance)
            min_d = np.min(distance)
            mean_d = np.mean(distance)

            max_neighbour.append(max_d)
            min_neighbour.append(min_d)
            mean_neighbour.append(mean_d)

        ic_max = np.mean(np.array(max_neighbour))
        ic_min = np.mean(np.array(min_neighbour))
        ic_mean = np.mean(np.array(mean_neighbour))
        return {'icMax': ic_max * self.um_per_pix, 'icMin': ic_min * self.um_per_pix,
                'icMean': ic_mean * self.um_per_pix}

    def density_map(self, arr):
        mask = np.zeros([self.height, self.width])
        for row in range(arr.shape[0]):
            mask[int(arr[row, 0]), int(arr[row, 1])] = 1

        avg_positions = []
        for size in [40, 45, ]:
            conv_filter = np.ones([size, size])
            density = convolve2d(mask, conv_filter, mode='same')

            max_val = np.max(density)
            posr, posc = np.nonzero(density == max_val)
            avg_pos = np.array([posr.mean(), posc.mean()])

            avg_positions.append(avg_pos)

        avg_locations = np.stack(avg_positions)
        avg_location = avg_locations.mean(axis=0)

        return {'avgLocationRow': avg_location[0], 'avgLocationCol': avg_location[1], }

    def count_cones(self, arr):
        return {'count': arr.shape[0]}

    def get_image_stats(self, ):
        # remove whitespace as otherwise messes csv
        if ' ' in self.image_name:
            print('Warning\n Filename contains spaces: %s\n stripping spaces in csv' % (self.image_name))
        final_stats = {'name': self.image_name.replace(' ', '')}

        # human or alg centres
        centers = {'alg': self.networkCentres, 'hum': self.humanCentres}

        for key in centers:
            if centers[key] is None:
                continue
            else:
                if centers[key]:
                    arr = np.stack(centers[key])
                else:
                    arr = np.empty(shape=[0, 2])

            # calculate stats
            density_locations = self.density_map(arr)
            mean_nn = self.meanNNDist(arr)
            voronoi = self.voronoi(arr)
            bound = voronoi['bound']
            ic_distance = self.intercell_distance(arr, bound)
            counts = self.count_cones(arr)
            stats_list = [mean_nn, voronoi, ic_distance, density_locations, counts]

            # what kind of states
            for stat in stats_list:
                # the individual stats produced from each thing
                for stat_key in stat:
                    if stat_key == 'bound':
                        continue
                    final_stats[key + '_' + stat_key] = stat[stat_key]
        final_stats['cropped_size_h'] = self.image.shape[0]
        final_stats['cropped_size_w'] = self.image.shape[1]
        return final_stats
