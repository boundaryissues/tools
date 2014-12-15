#!/bin/sh

destination=
set -- `getopt d:e:sn "$@"`
while test $# -gt 0
do
    case "$1" in
    -d)    destination="$2"
           shift;;
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
# SourceURL will be computed on the fly

# extract year and tiger file type from base shapefile name

for i in *.geojson; do
    year=`echo $i | sed 's/tl_\([0-9]*\)_.*\.geojson/\1/g'`    
    type=`echo $i | sed 's/tl_[0-9]*_[a-z0-9]*_\([a-z0-9]*\).*.geojson/\1/g'`
    break
done

UCtype=`echo $type | tr a-z A-Z`

sourceurl=${sourceurlroot}${year}/${UCtype}/tl_${year}_us_${type}.zip
#echo $sourceurl

typestring=""

case $type in

uac10) typestring="Urban Areas" ;;

esac

#echo $typestring

rm METADATA.old.json

echo "{" > METADATA.json
echo "    \"Location\": {" >> METADATA.json
if test X"$region" = X""; then
    echo "        \"Country\":  \"$country\"" >> METADATA.json
else
    echo "        \"Country\":  \"$country\"," >> METADATA.json
    echo "        \"State\":  \"$region\"" >> METADATA.json
fi
echo "    }," >> METADATA.json
if ! test X"$typestring" = X""; then
    echo "    \"Description\":  \"$typestring\"," >> METADATA.json
fi
echo "    \"Year\":  \"$year\"," >> METADATA.json
echo "    \"License\": \"$license\"," >> METADATA.json
echo "    \"Source\": {" >> METADATA.json
echo "          \"Name\": \"$source\"," >> METADATA.json
echo "          \"URL\": \"$sourceurl\"" >> METADATA.json
echo "    }," >> METADATA.json
echo "    \"CRS\": {" >> METADATA.json
echo "        \"Name\":  \"$crs\"," >> METADATA.json
echo "        \"URN\": \"$crsurn\"," >> METADATA.json
echo "        \"Original\": \"$originalcrs\"" >> METADATA.json
echo "    }" >> METADATA.json
echo "}" >> METADATA.json

#
#
if ! test X"$destination" = X""; then
    if ! test -d $destination; then
	mkdir $destination
    fi
    mv METADATA.json $destination
fi

