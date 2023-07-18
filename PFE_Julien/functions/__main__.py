# -*- encoding: utf-8 -*-

from __future__ import print_function

from . import read_instance

if __name__ == "__main__":

    import sys

    # Test read_instance
    R = read_instance(open(sys.argv[1]))

    print(R)
