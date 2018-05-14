# Copyright (C) Benjamin Davidson, Inc - All Rights Reserved
# Unauthorized copying of this file, without the authors written permission
# via any medium is strictly prohibited
# Proprietary and confidential
# Written by Benjamin Davidson <ben.davidson6@googlemail.com>, January 2018

import argparse

from . import cone_detector


def main():
    """command line entry to detect"""
    parser = argparse.ArgumentParser(prog='cone_detector')
    parser.add_argument('-f', help='folder name in current directory')
    args = parser.parse_args()
    cone_detector.main(args.f)


if __name__ == '__main__':
    main()
