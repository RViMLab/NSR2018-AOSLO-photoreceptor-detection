import tkinter as tk

from tkinter.filedialog import askdirectory, askopenfilename
from . import cone_detector


class ConeDetectorGUI:
    def __init__(self):

        # open window
        self.root = tk.Tk()
        # w, h = self.root.winfo_screenwidth(), self.root.winfo_screenheight()
        # self.root.geometry("%dx%d+0+0" % (w, h))

        # store values asked for
        self.im_folder_var = tk.StringVar()
        self.lut_var = tk.StringVar()

        # ask for parameters
        self.setup_welcome()

    def setup_welcome(self):

        def get_im_folder():
            options = dict(
                title='Choose folder of tifs',
            )
            self.im_folder_var.set(askdirectory(**options))

        self.frame = tk.Frame(self.root)
        self.frame.pack(expand=1, side=tk.TOP)
        self.im_button = tk.Button(self.frame, text="Choose folder location", command=get_im_folder)
        self.im_button.grid(row=0, column=0)

        def get_lut_file():
            options = dict(
                title='Choose lut',
            )
            self.lut_var.set(askopenfilename(**options))

        self.lut_button = tk.Button(self.frame, text="Choose lut", command=get_lut_file)
        self.lut_button.grid(row=1, column=0, sticky='w')

        self.bright_dark_var = tk.BooleanVar()
        check_bright = tk.Checkbutton(self.frame,text="Bright on left", variable=self.bright_dark_var)
        check_bright.grid(row=2, column=0, sticky='w')

        self.manually_annotate_var = tk.BooleanVar()
        manual_anotate = tk.Checkbutton(self.frame, text="Manually annotate", variable=self.manually_annotate_var)
        manual_anotate.grid(row=3, column=0, sticky='w')

        run = tk.Button(self.frame, text="Run", command=self.run)
        run.grid(row=4, column=0)

    def run(self):
        im_folder = self.im_folder_var.get()
        lut_file = self.lut_var.get()
        bright_dark = self.bright_dark_var.get()
        manually_annotate = self.manually_annotate_var.get()
        self.close_builder()
        cone_detector.main(im_folder, lut_file, manually_annotate, bright_dark)

    def close_builder(self):
        self.root.destroy()