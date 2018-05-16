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
    parser.add_argument('-m', help='whether to manually amend?',choices=set("yn"))
    parser.add_argument('-b', help='bright lobe on left?', choices=set("yn"))
    args = parser.parse_args()
    cone_detector.main(args.f, args.a, args.b)


if __name__ == '__main__':
    main()
