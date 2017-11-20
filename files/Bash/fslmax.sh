#!/bin/bash
#
# Script:  fslmax.sh
# Purpose: Print the maximum of one or more images
# Author:  Tom Nichols
# Version: $Id: fslmax.sh,v 1.1 2010/02/17 07:10:25 nichols Exp $
#


###############################################################################
#
# Environment set up
#
###############################################################################

shopt -s nullglob # No-match globbing expands to null
trap CleanUp INT

###############################################################################
#
# Functions
#
###############################################################################

Usage() {
cat <<EOF
Usage: `basename $0` img1 [img2 ...]

Print the maximum of one or more images. 
_________________________________________________________________________
\$Id: fslmax.sh,v 1.1 2010/02/17 07:10:25 nichols Exp $
EOF
exit
}

CleanUp () {
    exit 0
}


###############################################################################
#
# Parse arguments
#
###############################################################################

while (( $# > 1 )) ; do
    case "$1" in
        "-help")
            Usage
            ;;
#         "-t")
#             shift
#             tval="$1"
#             shift
#             ;;
        -*)
            echo "ERROR: Unknown option '$1'"
            exit 1
            break
            ;;
        *)
            break
            ;;
    esac
done

if (( $# < 1 )) ; then
    Usage
fi

###############################################################################
#
# Script Body
#
###############################################################################

for f in "$@" ; do
    echo -n "${f}: "
    fslstats "$f" -R | awk '{print $2}'
done

###############################################################################
#
# Exit & Clean up
#
###############################################################################

CleanUp

