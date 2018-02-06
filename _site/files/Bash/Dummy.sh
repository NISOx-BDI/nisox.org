#!/bin/bash
#
# Script:  Dummy.sh
# Purpose: Creates dummy variables for a categorical variable; uses R
# Author:  T. Nichols
# Version: $Id: Dummy.sh,v 1.2 2012/02/28 17:00:51 nichols Exp $
#


###############################################################################
#
# Environment set up
#
###############################################################################

shopt -s nullglob # No-match globbing expands to null
TmpDir=/tmp
Tmp=$TmpDir/`basename $0`-${$}-
trap CleanUp INT

###############################################################################
#
# Functions
#
###############################################################################

Usage() {
cat <<EOF
Usage: `basename $0` [options] CatVarTab OutTab
Creates dummy variables for a categorical variable; uses R

Input:
    CatVarTab   A CSV table where the first column are the labels 
                of a categorical variable (all other columns are ignored). 
                The labels must have no whitespace nor commas, and there must
                be a header row (i.e. first row is ignored).
    OutTab      A CSV table with dummy variables coding the levels of the
                categorical variable.

Options:  -c ConType
                 Use contrast parameterization ConType; possible values are 
                 'sum' and 'anova' (sum-to-zero constraint vs. no constraint)
                 (sum is default)
_________________________________________________________________________
\$Id: Dummy.sh,v 1.2 2012/02/28 17:00:51 nichols Exp $
EOF
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

ConTyp="sum"
while [ $# -gt 1 ] ; do
    case "$1" in
        "-help")
            Usage
            ;;
        "-c")
            shift
            ConTyp="$1"
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
Tmp=$TmpDir/AddDummy-${$}-

if [ $# -ne 2 ] ; then
    Usage
fi

###############################################################################
#
# Script Body
#
###############################################################################

TabIn="$1"
TabOut="$2"

#
# Check table
#
if [ ! -f "$TabIn" ] ; then
    echo "ERROR: Cannot read '$TabIn'"
    CleanUp
fi
VarNm=$( awk -F, '(NR==1){print $1}' $TabIn )

#
# Set up the R script
#
if [ "$ConTyp" == "sum" ] ; then

    cat <<EOF > $Tmp.R
x=read.table("$TabIn",header=TRUE,sep=",")
y=1:dim(x)[1]
D=model.matrix(y~C(x[,1],sum))
D=D[,-1]
write.table(D,"${Tmp}.dat",sep=",",row.names=FALSE,col.names=FALSE)
EOF

elif [ "$ConTyp" == "anova" ] ; then

    cat <<EOF > $Tmp.R
x=read.table("$TabIn",header=TRUE,sep=",")
y=1:dim(x)[1]
D=model.matrix(y~-1+C(x[,1],treatment))
write.table(D,"${Tmp}.dat",sep=",",row.names=FALSE,col.names=FALSE)
EOF

else
    echo "ERROR: Invalid contrast type '$ConTyp'"
    CleanUp
fi

#
# Run R script
#
R --vanilla --slave < $Tmp.R >& /dev/null

#
# Set header
#
nVar=$( awk -F, '(NR==1) {print NF}' $Tmp.dat )

cp /dev/null "$TabOut"
for (( i=1; i<=nVar; i++ )) ; do
    printf "%s-%d" "$VarNm" $i >> "$TabOut"
    if (( i<nVar )) ; then
	printf "," >> "$TabOut"
    else
	printf "\n" >> "$TabOut"
    fi
done

#
# Add on data
#
cat $Tmp.dat >> "$TabOut"

###############################################################################
#
# Exit & Clean up
#
###############################################################################

CleanUp

