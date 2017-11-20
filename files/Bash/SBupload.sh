#!/bin/bash
#
# Script: SBupload.sh
# Purpose: Sitebuilder uploading - from the command line!!!
# Author: Thomas Nichols
# Dependencies: Warwick SiteBuilder enviornment, Atom API; curl
# Version: $Id: SBupload.sh,v 1.14 2013/01/29 21:15:06 nichols Exp $
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
# Change this to your own Warwick webpage
BaseWebDir="/fac/sci/statistics/staff/academic-research/nichols/"

shopt -s nullglob # No-match globbing expands to null
TmpDir=/tmp
Tmp=$TmpDir/`basename $0`-${$}-
trap CleanUp INT

# $APIurl must be appended with destination directory
APIurl="https://sitebuilder.warwick.ac.uk/sitebuilder2/edit/atom/file.htm?page="
ContentType="text/plain"

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
   $BaseWebDir

Options
   -u user   Specify username (default $UserID)
   -c ContentType   Specify MIME content type (default is ${ContentType}). 
                    Can specify shorthand, like "pdf" or "png"; use "bin" to
                    specify generic binary datatype.
   -ot       Output some template text to use a Textile page
   -oh       Output some template text to use in a HTML document
_________________________________________________________________________
\$Id: SBupload.sh,v 1.14 2013/01/29 21:15:06 nichols Exp $
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
        "-c")
            shift
            ContentType="$1"
            shift
            ;;
        "-ot")
            shift
            OutputTextile=1
            ;;
        "-oh")
            shift
            OutputHtml=1
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

case "$ContentType" in
    "csv" | "html" | "plain" | "rtf")
	ContentType=text/$ContentType
	;;
    "txt")
	ContentType=text/plain
	;;
    "pdf" | "zip" | "gzip")
	ContentType=application/$ContentType
	;;
    "doc")
        ContentType=application/msword
	;;
    "docx")
        ContentType=application/vnd.openxmlformats-officedocument.wordprocessingml.document
	;;
    "xls")
        ContentType=application/vnd.ms-excel
	;;
    "xlsx")
        ContentType=application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
	;;
    "ppt")
        ContentType=application/vnd.ms-powerpoint
	;;
    "pptx")
        ContentType=application/vnd.openxmlformats-officedocument.presentationml.presentation
	;;
    "gif" | "jpeg" | "tiff" | "png")
	ContentType=image/$ContentType
	;;
    "tif")
	ContentType=image/tiff
	;;
    "jpg")
	ContentType=image/jpeg
	;;
    "bin")
	ContentType=binary/octet-stream
	;;
    "mov")
        ContentType=video/quicktime
	;;
    "mpg")
        ContentType=video/mpeg
	;;
    "avi" | "mp4")
        ContentType=video/$ContentType
	;;
esac

###############################################################################
#
# Script Body
#
###############################################################################

WebDir="$1"
shift
stty_orig=`stty -g`
stty -echo
echo -n "Enter password for $UserID: "
read Password
stty "$stty_orig"
echo 

echo -n "Uploading: "

# Absolute-ize path
if [ "$WebDir" == "." ] ; then
    AbsWebDir="${BaseWebDir}"
elif [[ ! "$WebDir" =~ ^/ ]] ; then
    AbsWebDir="${BaseWebDir}${WebDir}"
else
    AbsWebDir="${WebDir}"
fi

    touch  ${Tmp}-TextileList
    touch  ${Tmp}-HtmlList
    for f in "$@" ; do
	echo -n "$f "
	
	curl -i -X POST -u "${UserID}:${Password}" \
	    --data-binary @"$f" -H "Slug: $f" -H "Content-type: $ContentType" \
	    "${APIurl}${AbsWebDir}"
	cat <<EOF >> ${Tmp}-TextileList
* "_${f}_":$f<BR>
About this file...
EOF
	cat <<EOF >> ${Tmp}-HtmlList
<a href="${f}">$f</a><BR>
EOF
    done
    echo 
    
if [ "$OutputTextile" = 1 ] ; then 
    echo "Copy and paste into Textile page"
    echo "----------------------------------------------------------"
    cat ${Tmp}-TextileList
    echo "----------------------------------------------------------"
fi
if [ "$OutputHtml" = 1 ] ; then
    echo "Copy and paste into Html page"
    echo "----------------------------------------------------------"
    cat ${Tmp}-HtmlList
    echo "----------------------------------------------------------"
fi


###############################################################################
#
# Exit & Clean up
#
###############################################################################

CleanUp

