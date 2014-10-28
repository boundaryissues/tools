#!/bin/sh
#

COUNTRY='US'
SOURCE='US Census Bureau (TIGER)'
SOURCEURLROOT='ftp://ftp2.census.gov/geo/tiger/TIGER'
LICENSE='Public Domain'
PROJECTION='WGS84'
ORIGINALPROJECTION='NAD83'
# State and SourceURL will be computed on the fly

# load table of fips codes
. fips-codes.sh


# remove old lsad specific shape files
rm tl_????_??_*-??.???

# extract year, FIPS state code and tiger file type from base shapefile name
export YEAR=`echo tl_????_??_*.shp | sed 's/tl_\([0-9]*\).*\.shp/\1/g'`
export FIPS=`echo tl_????_??_*.shp | sed 's/tl_[0-9]*_\(.*\)_.*.shp/\1/g'`
export TYPE=`echo tl_????_??_*.shp | sed 's/tl_[0-9]*_.*_\(.*\).shp/\1/g'`

echo $YEAR $FIPS $TYPE

# get state postal code
eval STATE=\$f_${FIPS}

echo $STATE

SOURCEURL=${SOURCEURLROOT}${YEAR}/${TYPE}/tl_${YEAR}_${FIPS}_${TYPE}.zip
echo $SOURCEURL

echo "Country: " $COUNTRY > METADATA
echo "State: " $STATE >> METADATA
echo "Source: " $SOURCE >> METADATA
echo "SourceURL: " $SOURCEURL >> METADATA
echo "License: " $LICENSE >> METADATA
echo "Projection: " $PROJECTION >> METADATA
echo "OriginalProjection: " $ORIGINALPROJECTION >> METADATA

mv METADATA $1/${STATE}
