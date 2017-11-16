from setuptools import setup


def readme():
    with open('README.rst') as f:
        return f.read()

setup(name='cone_detector_gpu',
		version='0.1',
		description='Automatic cone detection software',
		url='http://github.com/storborg/funniest',
		author='Benjamin Davidson',
		author_email='benjamin.davidson.16@ucl.ac.ul',
		license='MIT',
		packages=['cone_detector'],
		install_requires=[
			'matplotlib',
			'numpy',
			'scipy',
			'scikit-image',
			'Pillow',
			'argparse'
      	],
		entry_points = {
			'console_scripts': ['cone_detector=cone_detector.command_line:main'],
		},
		long_description=readme(),
		keywords='AOSLO photoreceptor localisation',
		include_package_data=True,
		zip_safe=False)