#!/bin/sh

#
country='US'
source='US Census Bureau (TIGER)'
sourceurlroot='ftp://ftp2.census.gov/geo/tiger/TIGER'
license='Public Domain'
crs='WGS84'
originalcrs='NAD83'

# region and SourceURL will be computed on the fly

# load table of fips codes
. fips-codes.sh


# remove old lsad specific shape files
rm tl_????_??_*-??.???

# extract year, FIPS state code and tiger file type from base shapefile name
year=`echo tl_????_??_*.shp | sed 's/tl_\([0-9]*\).*\.shp/\1/g'`
fips=`echo tl_????_??_*.shp | sed 's/tl_[0-9]*_\(.*\)_.*.shp/\1/g'`
type=`echo tl_????_??_*.shp | sed 's/tl_[0-9]*_.*_\(.*\).shp/\1/g'`

echo $year $fips $type

if ! test X"$fips" = X"us"; then
   # get state postal code
   eval region=\$f_${fips}
else
   region="us"
fi

echo "Region:" $region

sourceurl=${sourceurlroot}${year}/${type}/tl_${year}_${fips}_${type}.zip
#echo $sourceurl

typestring=""

case $type in

state) typestring="States and State equivalents" ;;

county) typestring="Counties and County equivalents" ;;

cousub) typestring="County Subdivision" ;;

place) typestring="TIGER Places (Cities & other Municipalities, CDPs)" ;;

concity) typestring="Consolidated City/County Government" ;;

cnecta) typestring="New England Consolidated City/Town Government" ;;

esac

echo "Country: " $country > METADATA
if ! test X"$fips" = X"us"; then 
    echo "State: " $region >> METADATA
fi
if ! test X"$typestring" = X""; then
    echo "Description: " $typestring >> METADATA
fi
echo "Source: " $source >> METADATA
echo "SourceURL: " $sourceurl >> METADATA
echo "License: " $license >> METADATA
echo "CRS: " $crs >> METADATA
echo "OriginalCRS: " $originalcrs >> METADATA

#mv METADATA $1/$region
mv METADATA $1/
