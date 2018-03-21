#!/bin/bash
#
# Script:  fslstats.sh
# Purpose: Run fslstats on multiple files
# Author:  Tom Nichols; crucial fixes and additions from Adam Thomas
# Version: $Id: fslstats.sh,v 1.5 2013/09/17 08:32:59 nichols Exp $
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
Usage: `basename $0` [options] img1 [img2 ...]

Provides "fslstats" results with multiple files; note the different usage: Options
come first, followed by image file names.

Options: 
   All fslstats options; see fslstats help.
_________________________________________________________________________
T. Nichols, A. Thomas
\$Id: fslstats.sh,v 1.5 2013/09/17 08:32:59 nichols Exp $
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
preopts=()

if [ "$1" = "-t" ] ; then
    preopts=("-t")
    shift
fi
opts=();io=0
while (( $# > 1 )) ; do
    case "$1" in
        "-help")
            Usage
            ;;
        "-l" | "-u" | "-p" | "-P" | "-k" | "-d" | "-h")
            opts[io]="$1 $2"
            shift 2
            ;;
        "-H")
            opts[io]="$1 $2 $3 $4"
            shift 4
            ;;
        -*)
            opts[io]="$1"
	    shift
            ;;
        *)
            break
            ;;
    esac
    ((io++))
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
    foo=`imglob $f`
    fslstats "${preopts[@]}" "$f" "${opts[@]}" |  while read CMD; do
	echo "${foo}: $CMD"
    done
done


###############################################################################
#
# Exit & Clean up
#
###############################################################################

CleanUp

