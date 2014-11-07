#!/bin/sh

destination=
add_state="no"
set -- `getopt d:s "$@"`
while test $# -gt 0
do
    case "$1" in
    -d)    destination="$2"; shift;;
    -s)    add_state="yes";;
    :*)    echo >&2 "usage: $0 [-s] [-d dir]"
           exit 1;;
    *)     break;;
    esac
    shift
done

#
country='US'
source='US Census Bureau (TIGER)'
year='2014'
sourceurlroot='ftp://ftp2.census.gov/geo/tiger/TIGER'
license='Public Domain'
crs='WGS84'
originalcrs='NAD83'
crsurn='urn:ogc:def:crs:OGC:1.3:CRS84'
# region and SourceURL will be computed on the fly

# load table of fips codes
. fips-codes.sh

# extract year, FIPS state code and tiger file type from base shapefile name
# and determine if there are lsad based splits in this directory

for i in *.geojson; do
    year=`echo $i | sed 's/tl_\([0-9]*\)_.*\.geojson/\1/g'`    
    fips=`echo $i | sed 's/tl_[0-9]*_\([a-z0-9][a-z0-9]\)_.*.geojson/\1/g'`
    type=`echo $i | sed 's/tl_[0-9]*_[a-z0-9]*_\([a-z]*\).*.geojson/\1/g'`
    break
done




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

aiannh) typestring="American Indian/Alaska Native/Native Hawaiian Areas" ;;

aitsn) typestring="American Indian Tribal Subdivision National" ;;

anrc) typestring="Alaska Native Regional Corporation" ;;

esac

echo $typestring

lsad_list=

for f in tl_${year}_${fips}_${type}-??.geojson; do
    
    lsad=`echo $f | sed 's/tl_[0-9]*_.*_.*-\(.*\).geojson/\1/g'`
    if test X"$lsad" = X"??"; then
	break
    fi
    echo "processing lsad " $lsad
    if test X"$lsad_list" = X""; then
	lsad_list=\"${lsad}\"
    else
	lsad_list=${lsad_list},\"${lsad}\"
    fi
done

echo "{" > METADATA.json
echo "    \"Location\": {" >> METADATA.json
echo "        \"Country\":  \"$country\"," >> METADATA.json
if ! test X"$fips" = X"us"; then 
    echo "        \"State\":  \"$region\"," >> METADATA.json
fi
echo "    }," >> METADATA.json
if ! test X"$typestring" = X""; then
    echo "    \"Description\":  \"$typestring\"," >> METADATA.json
fi
echo "    \"Year\":  \"$year\"," >> METADATA.json
echo "    \"License\": \"$license\"," >> METADATA.json
echo "    \"Source\": {" >> METADATA.json
echo "          \"Name\": \"$source\"," >> METADATA.json
echo "          \"SourceURL\": \"$sourceurl\"" >> METADATA.json
echo "    }," >> METADATA.json
if ! test X"$lsad_list" = X"" ; then
    echo "    \"LSADs\":  [ $lsad_list ]," >> METADATA.json
fi
echo "    \"CRS\": {" >> METADATA.json
echo "        \"Name\":  \"$crs\"," >> METADATA.json
echo "        \"URN\": \"$crsurn\"," >> METADATA.json
echo "        \"Original\": \"$originalcrs\"" >> METADATA.json
echo "    }" >> METADATA.json
echo "}" >> METADATA.json

if ! test X"$destination" = X""; then
    if test X"$add_state" = X"yes"; then
        mv METADATA.json $destination/$region
    else
        mv METADATA.json $destination
    fi
fi
