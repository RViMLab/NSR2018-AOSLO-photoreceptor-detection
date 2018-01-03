from setuptools import setup


setup(name='cone_detector',
		version='0.1',
		description='Automatic cone detection software',
		url='https://gitlab.com/rmapbda/ConeDetector',
		author='Benjamin Davidson',
		author_email='benjamin.davidson.16@ucl.ac.ul',
		license='MIT',
		packages=['cone_detector'],
		package_data={'cone_detector': ['ckpts/*']},
		install_requires=[
			'matplotlib',
			'numpy',
			'scipy',
			'scikit-image',
			'Pillow',
			'argparse',
			'tensorflow',
      	],
		entry_points = {
			'console_scripts': ['cone_detector=cone_detector.command_line:main'],
		},
		keywords='AOSLO photoreceptor localisation',
		include_package_data=True,
		zip_safe=False)