import os
import pickle


from .annotation_gui import Annotator
from .output_writer import OutputWriter
from .dataset import DataSet
from .detector_trainer import DetectorTrainer
from . import launch_gui
from . import image_folder_reader
from . import constants
from . import output
from . import utilities
from . import cone_detector

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'


def run_through_graph(image_folder, sze, bright_dark, model_name):
    outputs = []
    detector = cone_detector.ConeDetector(sze, bright_dark, model_name)
    for image_name in image_folder.images_by_size[sze]:
        raw_image = image_folder.grayscale_image(image_name)
        prob_of_cone, cropped = detector.network(raw_image)
        centers = detector.get_centers(prob_of_cone)
        o = output.Output(image=cropped, name=image_name)
        o.set_estimated_centres(centers)
        outputs.append(o)
    detector.close_session()
    return outputs


def run_through_nothing(image_folder, sze, outputs):
    for image_name in image_folder.images_by_size[sze]:
        # get image, crop center, and build output
        raw_image = image_folder.grayscale_image(image_name)
        cropped = utilities.crop_center(raw_image, sze)
        o = output.Output(image=cropped, name=image_name)
        o.set_estimated_centres([])
        outputs.append(o)
    return outputs


def locate_cones_with_model(data_folder, bright_dark, model_name):
    image_folder = image_folder_reader.ImageFolder(data_folder)
    outputs = []
    for size in image_folder.images_by_size.keys():
        if model_name == constants.NO_MODEL:
            outputs += run_through_nothing(image_folder, size, outputs)
        else:
            outputs += run_through_graph(image_folder, size, bright_dark, model_name)

    return outputs


def apply(data_folder, lut_csv, model_name, manual, brightDark):
    """
        - applies network to all tifs in data_folder
        - runs an interactive gui on these results for cleanup
            this saves its output as a pickle file
        - load pickle file and run metrics on it
    """

    # apply network and generate estimated
    print('Applying method to data')
    outputs = locate_cones_with_model(data_folder, brightDark, model_name)

    # will manually correct in gui
    if manual:
        # manually correct
        Annotator(outputs)

        # use corrected
        if os.name == 'nt':
            temp_dir = 'C:\\Windows\\Temp'
        else:
            temp_dir = '/tmp'

        filename = os.path.join(temp_dir, 'annotationState.pickle')
        with open(filename, 'rb') as handle:
            outputs = pickle.load(handle)['outputsAfterAnnotation']



    # create output
    print('Building Output')
    writer = OutputWriter(outputs, data_folder, lut_csv)
    writer.write_output()


def data(data_folder, brightDark, data_name, model_name):
    """Build training data set"""

    # get network output, if mname is none then returns empty
    # centers
    outputs = locate_cones_with_model(data_folder, brightDark, model_name)

    # manually correct
    Annotator(outputs)

    # use corrected
    if os.name == 'nt':
        temp_dir = 'C:\\Windows\\Temp'
    else:
        temp_dir = '/tmp'

    filename = os.path.join(temp_dir, 'annotationState.pickle')
    with open(filename, 'rb') as handle:
        outputs = pickle.load(handle)['outputsAfterAnnotation']

    # build tfrecord
    dataset = DataSet(data_name)
    dataset.create_dataset(outputs)


def train_new(train_data_name, val_data_name, model_name, bright_dark):
    trainer = DetectorTrainer(model_name, train_data_name, val_data_name, bright_dark, batch_size=4)
    trainer.train()


def main():
    """command line entry to detect"""
    r = launch_gui.ConeDetectorGUI()
    r.start()

    if r.mode == r.APPLY:
        apply(
            r.chosen_image_source_folder.get(),
            r.chosen_lut_file.get(),
            r.chosen_existing_model.get(),
            r.fully_or_semi_automatic.get(),
            r.bright_or_dark.get()
            )
    elif r.mode == r.DATA:
        data(
            r.chosen_image_source_folder.get(),
            r.bright_or_dark.get(),
            r.chosen_new_data_name.get(),
            r.chosen_existing_model.get())
    elif r.mode == r.TRAIN:
        train_new(
            r.chosen_train_data.get(),
            r.chosen_val_data.get(),
            r.chosen_new_model_name.get(),
            r.bright_or_dark.get())


if __name__ == '__main__':
    main()
