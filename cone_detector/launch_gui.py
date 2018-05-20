# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018


import tkinter as tk
import os
from tkinter.filedialog import askdirectory, askopenfilename
from . import constants

class ConeDetectorGUI:
    def __init__(self):

        # open window
        self.root = tk.Tk()
        self.root.title('Automatic Cone Detection')
        # w, h = self.root.winfo_screenwidth(), self.root.winfo_screenheight()
        # self.root.geometry("%dx%d+0+0" % (w, h))

        # store values asked for
        self.im_folder_var = tk.StringVar()
        self.lut_var = tk.StringVar()
        self.model_name_var = tk.StringVar()
        self.model_name_var.set(constants.NO_MODEL)
        self.train_data_loc_var = tk.StringVar(value='Choose training data')
        self.val_data_loc_var = tk.StringVar(value=constants.NO_DATA)
        self.new_data_name_var = tk.StringVar(value='Give data a name')
        self.new_model_name_var = tk.StringVar(value='Give model a name')

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
            self.im_folder_var.set(askdirectory(**options))

        self.im_button = tk.Button(self.frame, text="Choose image folder", command=get_im_folder)
        self.im_button.grid(row=0, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        # choosing csv file button
        def get_lut_file():
            options = dict(
                title='Choose lut',
            )
            self.lut_var.set(askopenfilename(**options))

        self.lut_button = tk.Button(self.frame, text="Choose lut", command=get_lut_file)
        self.lut_button.grid(row=1, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        # some more options
        self.bright_dark_var = tk.BooleanVar()
        check_bright = tk.Checkbutton(self.frame,text="Bright on left", variable=self.bright_dark_var)
        check_bright.grid(row=2, column=0, sticky=tk.W)

        self.manually_annotate_var = tk.BooleanVar()
        manual_anotate = tk.Checkbutton(self.frame, text="Manually annotate", variable=self.manually_annotate_var)
        manual_anotate.grid(row=3, column=0, sticky=tk.W)

        models = os.listdir(constants.MODEL_DIREC)
        option = tk.OptionMenu(self.frame, self.model_name_var, *models)
        option.grid(row=4, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        apply = tk.Button(self.frame, text="Run", command=self.run)
        apply.grid(row=5, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

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
            self.im_folder_var.set(askdirectory(**options))

        self.im_button = tk.Button(self.frame, text="Choose image folder", command=get_im_folder)
        self.im_button.grid(row=0, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        model_name = tk.Entry(self.frame, textvariable=self.new_data_name_var)
        model_name.grid(row=1, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        # some more options
        self.bright_dark_var = tk.BooleanVar()
        check_bright = tk.Checkbutton(self.frame, text="Bright on left", variable=self.bright_dark_var)
        check_bright.grid(row=2, column=0, sticky=tk.W)

        models = [x for x in os.listdir(constants.MODEL_DIREC) if x[0] != '.']
        option = tk.OptionMenu(self.frame, self.model_name_var, *models)
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
        option = tk.OptionMenu(self.frame, self.train_data_loc_var, *datas)
        option.grid(row=0, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        # only name not whole path
        option_val = tk.OptionMenu(self.frame, self.val_data_loc_var, *datas)
        option_val.grid(row=1, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        self.model_name = tk.Entry(self.frame, textvariable=self.new_model_name_var)
        self.model_name.grid(row=2, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))

        self.bright_dark_var = tk.BooleanVar()
        check_bright = tk.Checkbutton(self.frame, text="Bright on left", variable=self.bright_dark_var)
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
        self.im_folder = self.im_folder_var.get()
        self.lut_file = self.lut_var.get()
        self.bright_dark = self.bright_dark_var.get()
        self.manually_annotate = self.manually_annotate_var.get()
        self.close_builder()