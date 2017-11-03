#!/usr/bin/env python

# Cross-platform mkdir command.

import os
import sys

if __name__=='__main__':
    if len(sys.argv) != 2:
        sys.exit('usage: mkdir.py <directory>')
    directory = sys.argv[1]
    try:
        os.makedirs(directory)
    except OSError:
        pass