import numpy as np
from scipy.spatial import Voronoi, Delaunay
import matplotlib.pyplot as plt

class StatsCalculator:
    def __init__(self, single_image_dict, um_per_pix):
        self.image_name = single_image_dict['name']
        self.image = single_image_dict['cropped']
        self.networkCentres = single_image_dict['centres']
        self.humanCentres = single_image_dict['correctedCentres']
        self.um_per_pix = um_per_pix
        self.height, self.width = self.image.shape

    def mean_nearest_neighbour(self,):

        def meanNNDist(arr):
            difference = arr[None, :, :] - arr[:, None, :]
            distanceSqrd = (difference*difference).sum(axis=2)
            distance = np.sqrt(distanceSqrd)
            maxD = np.max(distance)
            distance += np.eye(difference.shape[0])*maxD
            closest_neighbours = np.sort(distance)[:, 0]
            return {'meanNN':np.mean(closest_neighbours)*self.um_per_pix}
        
        return {'alg':meanNNDist(self.networkCentres), 'hum':meanNNDist(self.humanCentres)}

    def voronoi(self,):

        def polyArea(x,y):
            return 0.5*np.abs(np.dot(x,np.roll(y,1))-np.dot(y,np.roll(x,1)))

        def volArea(vor_obj, i):
            xPoints = []
            yPoints = []
            for point_index in vor_obj.regions[i]:
                xPoints.append(vor_obj.vertices[point_index][0])
                yPoints.append(vor_obj.vertices[point_index][1])

            xPoints = np.array(xPoints)
            yPoints = np.array(yPoints)
            return polyArea(xPoints, yPoints)

        def calcVoronoi(arr):
            bounded = np.zeros(arr.shape[0], dtype=np.bool)
            vor = Voronoi(arr)
            point_region = vor.point_region
            number_bounded = 0.
            number_six_sided = 0.
            volumes = []
            sides = []
            for idx, region in enumerate(vor.regions):

                #if finite
                if -1 in region:
                    continue
                else:
                    number_bounded += 1.
                    bounded[point_region==idx] = True
                sides.append(len(region))
                volumes.append(volArea(vor, idx))

            volume_array = np.array(volumes)
            sides_array = np.array(sides) + 1
            num_sixes = (sides_array==6).sum()

            volume = np.mean(volume_array*self.um_per_pix)/np.std(volume_array*self.um_per_pix)
            sides = np.mean(sides_array)/np.std(sides_array)
            six_sides = (float(num_sixes) / sides_array.shape[0])*100.
            vor_density = number_bounded/np.sum(volume*self.um_per_pix)
            return {'bound':bounded, 'vorVolume':volume, 'vorSides':sides, 'vorSix':six_sides, 'vorDensity':vor_density}

        return {'alg':calcVoronoi(self.networkCentres), 'hum':calcVoronoi(self.humanCentres)}

    def intercell_distance(self, bounded_alg, bounded_hum):

        def calcInter(arr):
            dt = Delaunay(arr)
            indPtr, indices = dt.vertex_neighbor_vertices
            max_neighbour = []
            min_neighbour = []
            mean_neighbour = []

            for vertex in range(indPtr.shape[0] - 1):
                if not bounded_alg[vertex]:
                    continue

                neighbours = indices[indPtr[vertex]:indPtr[vertex+1]]

                vert_point = arr[vertex,:]
                neighbours = arr[neighbours,:]
                distance = neighbours - vert_point[None, :]
                distance = np.sqrt((distance*distance).sum(axis=1))

                max_d = np.max(distance)
                min_d = np.min(distance)
                mean_d = np.mean(distance)

                max_neighbour.append(max_d)
                min_neighbour.append(min_d)
                mean_neighbour.append(mean_d)

            ic_max = np.mean(np.array(max_neighbour))
            ic_min = np.mean(np.array(min_neighbour))
            ic_mean = np.mean(np.array(mean_neighbour))
            return {'icMax':ic_max*self.um_per_pix, 'icMin':ic_min*self.um_per_pix, 'icMean':ic_mean*self.um_per_pix}

        return {'alg':calcInter(self.networkCentres), 'hum':calcInter(self.humanCentres)}

    def get_image_stats(self,):
        mean_nn = self.mean_nearest_neighbour()
        voronoi = self.voronoi()
        bounded_alg = voronoi['alg']['bound']
        bounded_hum = voronoi['hum']['bound']
        ic_distance = self.intercell_distance(bounded_alg, bounded_hum)

        stats_list = [mean_nn, voronoi, ic_distance]
        final_stats = {'name':self.image_name}

        # human or alg centres
        for key in ['alg', 'hum']:
            # what kind of states
            for stat in stats_list:
                specific = stat[key]
                # the individual stats produced from each thing
                for related_stat_key in specific:
                    if related_stat_key=='bound':
                        continue
                    final_stats[key + '_' + related_stat_key] = specific[related_stat_key]

        return final_stats




