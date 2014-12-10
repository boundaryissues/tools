#!/bin/sh

destination=
lsad="no"
set -- `getopt d:e:sn "$@"`
while test $# -gt 0
do
    case "$1" in
    -n)    lsad="no";;
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
# and determine if there are lsad based splits in this directory

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

if test X"$lsad" = X"yes"; then

    lsad_list=

    i=0
    for f in tl_${year}_${fips}_${type}-??.geojson; do
    
        lsad_code=`echo $f | sed 's/tl_[0-9]*_.*_.*-\(.*\).geojson/\1/g'`
        if test X"$lsad_code" = X"??"; then
    	    break
        fi
#    echo "processing lsad " $lsad_code

        if test X"$lsad_list" = X""; then
	    lsad_list=$lsad_code
        else
	    lsad_list="${lsad_list} ${lsad_code}"
        fi
        i=`expr ${i} + 1`
    done
fi

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
if test X"$lsad" = X"yes" ; then
    echo "    \"tiger\": {" >> METADATA.json
    echo "        \"LSADs\": ["  >> METADATA.json
    echo "lsad list: " $lsad_list
    j=0
    for lsad_code in $lsad_list; do
        eval lsad_desc=\$ls_${lsad_code}_${region}_${type}
        if test X"$lsad_desc" = X""; then
	    eval lsad_desc=\$ls_${lsad_code}
        fi
	j=`expr $j + 1`
	if [ $i -eq $j ] ; then
	    echo "            {\"$lsad_code\":\"${lsad_desc}\"}" >> METADATA.json
	else
	    echo "            {\"$lsad_code\":\"${lsad_desc}\"}," >> METADATA.json
	fi
    done
    echo "         ]" >> METADATA.json
    echo "    }," >> METADATA.json
fi
echo "    \"CRS\": {" >> METADATA.json
echo "        \"Name\":  \"$crs\"," >> METADATA.json
echo "        \"URN\": \"$crsurn\"," >> METADATA.json
echo "        \"Original\": \"$originalcrs\"" >> METADATA.json
echo "    }" >> METADATA.json
echo "}" >> METADATA.json

#
if test X"$lsad" = X"yes"; then

    echo "This ${type} file uses the following LSAD codes:" > README
    echo '' >> README
    for lsad_code in $lsad_list; do
        eval lsad_desc=\$ls_${lsad_code}_${region}_${type}
        if test X"$lsad_desc" = X""; then
            eval lsad_desc=\$ls_${lsad_code}
        fi
        echo "${lsad_code}  ${lsad_desc}" >> README
    done
fi

#
if ! test X"$destination" = X""; then
    if ! test -d $destination; then
	mkdir $destination
    fi
    mv README METADATA.json $destination
fi

