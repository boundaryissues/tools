#!/bin/sh

destination=
add_state="no"
external_state=""
lsad="yes"
set -- `getopt d:e:sn "$@"`
while test $# -gt 0
do
    case "$1" in
    -n)    lsad="no";;
    -d)    destination="$2"
           shift;;
    -e)    external_state="$2"
           shift;;
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

# load tables of fips codes, lsad info
. fips-codes.sh
if test X"$lsad" = X"yes"; then
    . lsad-codes.sh
fi
# extract year, FIPS state code and tiger file type from base shapefile name
# and determine if there are lsad based splits in this directory

for i in *.geojson; do
    year=`echo $i | sed 's/tl_\([0-9]*\)_.*\.geojson/\1/g'`    
    fips=`echo $i | sed 's/tl_[0-9]*_\([a-z0-9][a-z0-9]\)_.*.geojson/\1/g'`
    type=`echo $i | sed 's/tl_[0-9]*_[a-z0-9]*_\([a-z]*\).*.geojson/\1/g'`
    break
done

UCtype=`echo $type | tr a-z A-Z`

if ! test X"$external_state" = X""; then
   region=$external_state
elif ! test X"$fips" = X"us"; then
   # get state postal code
   eval region=\$f_${fips}
else
   region="us"
fi

echo "Region:" $region

sourceurl=${sourceurlroot}${year}/${UCtype}/tl_${year}_${fips}_${type}.zip
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

    eval state_name=\$fn_${fips}
    echo "The ${state_name} ${type} file uses the following LSAD codes:" > README
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
    if test X"$add_state" = X"yes"; then
	if ! test -d $destination/$region; then
	    mkdir $destination/$region
	fi
        mv README METADATA.json $destination/$region
    else
        mv README METADATA.json $destination
    fi
fi

