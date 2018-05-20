from setuptools import setup

setup(name='cone_detector',
      version='0.1',
      description='Automatic cone detection software',
      url='https://gitlab.com/rmapbda/ConeDetector',
      author='Benjamin Davidson',
      author_email='ben.davidson6@googlemail.com',
      packages=['cone_detector'],
      package_data={'cone_detector': ['*']},
      install_requires=[
          'matplotlib',
          'numpy',
          'scipy',
          'scikit-image',
          'Pillow',
          'argparse',
          'tensorflow',
      ],
      entry_points={
          'console_scripts': ['cone_detector=cone_detector.__main__:main'],
      },
      keywords='AOSLO photoreceptor localisation',
    )
