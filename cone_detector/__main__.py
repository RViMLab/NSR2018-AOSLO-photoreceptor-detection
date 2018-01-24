from . import cone_detector
import argparse
	

def main():
    """command line entry to detect"""
    parser = argparse.ArgumentParser(prog='cone_detector')
    parser.add_argument('-f', help='folder name in current directory')
    args = parser.parse_args()
    cone_detector.main(args.f)

if __name__ == '__main__':
	main()