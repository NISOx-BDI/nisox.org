#!/bin/bash
#
# Script: WFupload.sh
# Purpose: Warwick Files uploading - from the command line!!!
# Author: Thomas Nichols
# Dependencies: Warwick Files enviornment, API; curl
# Version: $Id: WFupload.sh,v 1.1 2013/01/22 17:51:34 nichols Exp nichols $
#

#
# Stil To Do
#
# Add option to allow images/nontext data

###############################################################################
#
# Environment set up
#
###############################################################################

# Change this to your own Warwick unique username
UserID="essicd"
# Change this to your own Warwick files space
BaseFileDir="tenichols/Files"

shopt -s nullglob # No-match globbing expands to null
TmpDir=/tmp
Tmp=$TmpDir/`basename $0`-${$}-
trap CleanUp INT

# $APIurl must be appended with destination directory
APIurlFmt="https://files.warwick.ac.uk/files/api/upload?forceBasic=true&path=%s&fileName=%s&fileuploadid=123"

###############################################################################
#
# Functions
#
###############################################################################

Usage() {
cat <<EOF
Usage: `basename $0` [options] DestinationDir File1 [File2 ...]

Uploads plain text files to DestinationDir in my home directory.  Base path is
assumed to be
   $BaseFileDir

Options
   -u user   Specify username (default $UserID)
_________________________________________________________________________
\$Id: WFupload.sh,v 1.1 2013/01/22 17:51:34 nichols Exp nichols $
EOF
exit
}

CleanUp () {
    /bin/rm -f ${Tmp}*
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
        "-u")
            shift
            UserID="$1"
            shift
            ;;
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
Tmp=$TmpDir/f2r-${$}-

if (( $# < 2 )) ; then
    Usage
fi

###############################################################################
#
# Script Body
#
###############################################################################

FileDir="$1"
shift
stty_orig=`stty -g`
stty -echo
echo -n "Enter password for $UserID: "
read Password
stty "$stty_orig"
echo 

echo -n "Uploading: "

# Absolute-ize path
if [ "$FileDir" == "." ] ; then
    AbsFileDir="${BaseFileDir}"
elif [[ ! "$FileDir" =~ ^/ ]] ; then
    AbsFileDir="${BaseFileDir}${FileDir}"
else
    AbsFileDir="${FileDir}"
fi

    for f in "$@" ; do
	echo -n "$f "
	
	fnm=$(basename $f)

	APIurl=$(printf "$APIurlFmt" "$AbsFileDir" "$fnm")
	curl -i -F file=@"$f" -u "${UserID}:${Password}" "${APIurl}"

    done



###############################################################################
#
# Exit & Clean up
#
###############################################################################

CleanUp

