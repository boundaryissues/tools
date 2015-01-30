#!/bin/sh

destination=
set -- `getopt d:e:s:n "$@"`
while test $# -gt 0
do
    case "$1" in
    -d)    destination="$2"
           shift;;
    -s)    state_list="$2"
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
    jq '.features|.[]|.properties|.NAME10' < $i | cut -d "," -f 2 > /tmp/statelist
    break
done

UCtype=`echo $type | tr a-z A-Z`

sourceurl=${sourceurlroot}${year}/${UCtype}/tl_${year}_us_${type}.zip
#echo $sourceurl

typestring=""

case $type in

uac10) typestring="Urban Areas" ;;

esac

# need to consolidate state list
IFS=","
rm /tmp/states
for s in $state_list; do
    echo $s >> /tmp/states
done
sort /tmp/states | uniq > /tmp/sorted_states


#echo $typestring

echo "{" > METADATA.json
echo "    \"Location\": {" >> METADATA.json
if test X"$state_list" = X""; then
    echo "        \"Country\":  \"$country\"" >> METADATA.json
else
    echo "        \"Country\":  \"$country\"," >> METADATA.json
    echo "        \"States\": [ " >> METADATA.json
    IFS=","
    n=`wc -l < /tmp/sorted_states`
    j=1
    echo "n, j: " $n $j
    while read line
    do
	if [ $n -eq $j ] ; then
	    echo "                    \"$line\"" >> METADATA.json
	else
	    echo "                    \"$line\"," >> METADATA.json
	fi
	j=`expr $j + 1`
    done < /tmp/sorted_states
    
    echo "                    ]" >> METADATA.json
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

