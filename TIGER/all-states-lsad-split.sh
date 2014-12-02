#!/bin/sh
# to use this command, the openpolygons/tools/splitter must be in your
# shell path. cd to the directory containing the state directories named
# by FIPS codes to run.

# $1 is the destination, results will be placed in this directory
# in subdirectories using the USPS state abbreviations instead of the
# FIPS codes

. fips-codes.sh

for i in ??; do
    cd $i
    eval STATE=\$f_${i}
    echo $STATE
    lsad-split.sh $1/$STATE
    cd ..
done
