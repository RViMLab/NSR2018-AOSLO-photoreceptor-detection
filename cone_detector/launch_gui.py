import tkinter as tk
import os
from tkinter.filedialog import askdirectory, askopenfilename
from . import constants


try:
    import tensorflow
except ImportError:
    print('You must install tensorflow:\n https://www.tensorflow.org/install/')

class ConeDetectorGUI:
    def __init__(self):

        # open window
        self.root = tk.Tk()
        self.root.title('Automatic Cone Detection')
        self.frame = None

        # store values asked for
        self.chosen_image_source_folder = tk.StringVar()
        self.chosen_target_folder = tk.StringVar()
        self.chosen_lut_file = tk.StringVar()
        self.chosen_existing_model = tk.StringVar()
        self.chosen_existing_model.set('choose model to apply')
        self.chosen_train_data = tk.StringVar()
        self.chosen_train_data.set('choose training data')
        self.chosen_val_data = tk.StringVar()
        self.chosen_val_data.set('choose validation data')

        self.chosen_new_data_name = tk.StringVar()
        self.chosen_new_data_name.set('name dataset')
        self.chosen_new_model_name = tk.StringVar()
        self.chosen_new_model_name.set('name model')

        self.bright_or_dark = tk.BooleanVar()
        self.fully_or_semi_automatic = tk.BooleanVar()


        self.mode = None
        self.APPLY = 0
        self.DATA = 1
        self.TRAIN = 2

        # ask for parameters
        self.setup_welcome()

    def setup_welcome(self):
        self.frame = tk.Frame(self.root)
        self.frame.pack(expand=1, side=tk.TOP)

        inference = tk.Button(self.frame, text="Apply existing model", command=self.apply_network_gui)
        inference.grid(row=0, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        data = tk.Button(self.frame, text="Build training data", command=self.build_data_gui)
        data.grid(row=1, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        train = tk.Button(self.frame, text="Train new model", command=self.train_network_gui)
        train.grid(row=2, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

    def apply_network_gui(self):
        self.mode = self.APPLY
        self.frame.destroy()
        self.frame = tk.Frame(self.root)
        self.frame.pack(expand=1, side=tk.TOP)

        # Choosing folder button
        def get_im_folder():
            options = dict(
                title='Choose folder of tifs',
            )
            self.chosen_image_source_folder.set(askdirectory(**options))

        im_button = tk.Button(self.frame, text="Choose image folder", command=get_im_folder)
        im_button.grid(row=0, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        # Choosing folder button
        def get_target_folder():
            options = dict(
                title='Choose target folder',
            )
            self.chosen_target_folder.set(askdirectory(**options))

        target_button = tk.Button(self.frame, text="Choose target folder", command=get_target_folder)
        target_button.grid(row=2, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        # choosing csv file button
        def get_lut_file():
            options = dict(
                title='Choose lut',
            )
            self.chosen_lut_file.set(askopenfilename(**options))

        lut_button = tk.Button(self.frame, text="Choose csv", command=get_lut_file)
        lut_button.grid(row=1, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        # some more options
        check_bright = tk.Checkbutton(self.frame, text="Bright on left", variable=self.bright_or_dark)
        check_bright.grid(row=3, column=0, sticky=tk.W)

        manual_anotate = tk.Checkbutton(self.frame, text="Manually annotate", variable=self.fully_or_semi_automatic)
        manual_anotate.grid(row=4, column=0, sticky=tk.W)

        models = os.listdir(constants.MODEL_DIREC)
        option = tk.OptionMenu(self.frame, self.chosen_existing_model, *models)
        option.grid(row=5, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        apply = tk.Button(self.frame, text="Run", command=self.run)
        apply.grid(row=6, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

    def build_data_gui(self):
        self.mode = self.DATA

        self.frame.destroy()
        self.frame = tk.Frame(self.root)
        self.frame.pack(expand=1, side=tk.TOP)

        # Choose images button
        def get_im_folder():
            options = dict(
                title='Choose folder of tifs',
            )
            self.chosen_image_source_folder.set(askdirectory(**options))

        im_button = tk.Button(self.frame, text="Choose image folder", command=get_im_folder)
        im_button.grid(row=0, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        model_name = tk.Entry(self.frame, textvariable=self.chosen_new_data_name)
        model_name.grid(row=1, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        # some more options
        check_bright = tk.Checkbutton(self.frame, text="Bright on left", variable=self.bright_or_dark)
        check_bright.grid(row=2, column=0, sticky=tk.W)

        models = [x for x in os.listdir(constants.MODEL_DIREC) if x[0] != '.']
        models.insert(0, constants.NO_MODEL)
        option = tk.OptionMenu(self.frame, self.chosen_existing_model, *models)
        option.grid(row=3, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        apply = tk.Button(self.frame, text="Run", command=self.run)
        apply.grid(row=4, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

    def train_network_gui(self):
        self.mode = self.TRAIN

        self.frame.destroy()
        self.frame = tk.Frame(self.root)
        self.frame.pack(expand=1, side=tk.TOP)

        # only name not whole path
        datas = [x for x in os.listdir(constants.DATA_DIREC) if x[0] != '.']
        datas.insert(0, constants.NO_DATA)
        option = tk.OptionMenu(self.frame, self.chosen_train_data, *datas)
        option.grid(row=0, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        # only name not whole path
        option_val = tk.OptionMenu(self.frame, self.chosen_val_data, *datas)
        option_val.grid(row=1, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        model_name = tk.Entry(self.frame, textvariable=self.chosen_new_model_name)
        model_name.grid(row=2, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        check_bright = tk.Checkbutton(self.frame, text="Bright on left", variable=self.bright_or_dark)
        check_bright.grid(row=3, column=0, sticky=tk.W)

        apply = tk.Button(self.frame, text="Run", command=self.run)
        apply.grid(row=4, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

    def run(self):
        """passes back to main thread"""
        self.close_builder()

    def start(self):
        self.root.mainloop()

    def close_builder(self):
        self.root.destroy()

    def apply_network(self):
        self.close_builder()